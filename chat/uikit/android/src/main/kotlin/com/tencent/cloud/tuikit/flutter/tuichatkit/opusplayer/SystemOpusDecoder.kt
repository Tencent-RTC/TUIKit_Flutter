package com.tencent.cloud.tuikit.flutter.tuichatkit.opusplayer

import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Build
import android.util.Log
import com.tencent.cloud.tuikit.flutter.tuichatkit.realtimeaudio.RealtimeAudioSpec
import java.nio.ByteBuffer
import java.nio.ByteOrder

private const val TAG = "SystemOpusDecoder"

/**
 * 系统 [MediaCodec] 裸 Opus 解码器：TTS 下行 packet → 16kHz / 单声道 PCM16。
 *
 * 不用第三方库。后台分片帧长不保证是 20ms；部分机型解码器固定出 48kHz，这里会折回 16kHz。
 *
 * 非线程安全，只在解码线程上使用。
 */
class SystemOpusDecoder {

    private var codec: MediaCodec? = null
    private var outputSampleRate = RealtimeAudioSpec.SAMPLE_RATE
    private var presentationTimeUs = 0L

    /**
     * @return 解出的 PCM；packet 损坏、解码器未打开或解码失败时返回 null
     */
    fun decode(packet: ByteArray): ShortArray? {
        val decoder = codec ?: return null
        if (packet.isEmpty()) {
            return null
        }
        val inputIndex = decoder.dequeueInputBuffer(INPUT_TIMEOUT_US)
        if (inputIndex < 0) {
            return null
        }
        val inputBuffer = decoder.getInputBuffer(inputIndex) ?: return null
        inputBuffer.clear()
        inputBuffer.put(packet)
        decoder.queueInputBuffer(inputIndex, 0, packet.size, presentationTimeUs, 0)
        presentationTimeUs += FRAME_DURATION_US

        var pcm: ShortArray? = null
        val info = MediaCodec.BufferInfo()
        // 一个输入包最多出一个输出缓冲：拿到之前按超时等，拿到之后只收已经就绪的。
        // 一直按超时等到 TRY_AGAIN_LATER 才算取完的话，每包都要白等满一个超时
        var outputTimeoutUs = OUTPUT_TIMEOUT_US
        while (true) {
            val outputIndex = decoder.dequeueOutputBuffer(info, outputTimeoutUs)
            if (outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER) {
                break
            }
            if (outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                outputSampleRate = decoder.outputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                continue
            }
            if (outputIndex < 0) {
                continue
            }
            val outputBuffer = decoder.getOutputBuffer(outputIndex)
            if (outputBuffer != null && info.size > 0) {
                outputBuffer.position(info.offset)
                outputBuffer.limit(info.offset + info.size)
                outputBuffer.order(ByteOrder.nativeOrder())
                val frame = ShortArray(info.size / 2)
                outputBuffer.asShortBuffer().get(frame)
                pcm = if (pcm == null) frame else pcm + frame
            }
            decoder.releaseOutputBuffer(outputIndex, false)
            outputTimeoutUs = 0L
        }
        val decoded = pcm ?: return null
        return resampleTo16k(decoded, outputSampleRate)
    }

    /** 丢弃解码器状态。每段 TTS 播报开始前调一次。 */
    fun reset() {
        release()
        start()
    }

    fun release() {
        codec?.let { decoder ->
            runCatching { decoder.stop() }
            runCatching { decoder.release() }
        }
        codec = null
        outputSampleRate = RealtimeAudioSpec.SAMPLE_RATE
        presentationTimeUs = 0L
    }

    private fun start(): Boolean {
        if (codec != null) {
            return true
        }
        if (!isSupported()) {
            return false
        }
        return try {
            val format = MediaFormat.createAudioFormat(
                MediaFormat.MIMETYPE_AUDIO_OPUS,
                RealtimeAudioSpec.SAMPLE_RATE,
                RealtimeAudioSpec.CHANNEL_COUNT,
            )
            format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, MAX_PACKET_BYTES)
            format.setInteger(MediaFormat.KEY_PCM_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
            format.setByteBuffer("csd-0", opusIdentificationHeader())
            format.setByteBuffer("csd-1", nanosecondsCsd(CODEC_DELAY_NS))
            format.setByteBuffer("csd-2", nanosecondsCsd(SEEK_PRE_ROLL_NS))
            val newCodec = MediaCodec.createDecoderByType(MediaFormat.MIMETYPE_AUDIO_OPUS)
            newCodec.configure(format, null, null, 0)
            newCodec.start()
            codec = newCodec
            true
        } catch (exception: Exception) {
            Log.w(TAG, "configure opus decoder failed", exception)
            false
        }
    }

    companion object {
        private const val MAX_PACKET_BYTES = 4000
        private const val INPUT_TIMEOUT_US = 10_000L

        /** 只在解码线程上等，放宽一些，减少输出晚到被挪进下一包的情况 */
        private const val OUTPUT_TIMEOUT_US = 30_000L
        private const val FRAME_DURATION_US = 20_000L

        /** 与 OpusHead 里的 pre-skip 一致：后台分片不带编码器的前导延迟信息，按 0 处理 */
        private const val CODEC_DELAY_NS = 0L

        /** RFC 7845 建议的 80ms。这里不会 seek，只是解码器要求必须给齐第三份 CSD */
        private const val SEEK_PRE_ROLL_NS = 80_000_000L

        @Volatile
        private var cachedSupported: Boolean? = null

        /** 系统是否注册了 `audio/opus` 解码器。结果缓存，探测本身要遍历全部 codec。 */
        fun isSupported(): Boolean {
            cachedSupported?.let { return it }
            val supported = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                false
            } else {
                runCatching {
                    MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos.any { info: MediaCodecInfo ->
                        !info.isEncoder && info.supportedTypes.any {
                            MediaFormat.MIMETYPE_AUDIO_OPUS.equals(it, ignoreCase = true)
                        }
                    }
                }.getOrDefault(false)
            }
            cachedSupported = supported
            return supported
        }

        /** 安全构造。机型没有 `audio/opus` 解码器或 configure 失败时返回 null。 */
        fun create(): SystemOpusDecoder? {
            val decoder = SystemOpusDecoder()
            return if (decoder.start()) decoder else null
        }

        /**
         * RFC 7845 Identification Header。系统解码器要这份 CSD 才能解裸 packet。
         */
        private fun opusIdentificationHeader(): ByteBuffer {
            val header = ByteBuffer.allocate(19).order(ByteOrder.LITTLE_ENDIAN)
            header.put("OpusHead".toByteArray(Charsets.US_ASCII))
            header.put(1) // version
            header.put(RealtimeAudioSpec.CHANNEL_COUNT.toByte())
            header.putShort(0) // pre-skip
            header.putInt(RealtimeAudioSpec.SAMPLE_RATE)
            header.putShort(0) // output gain
            header.put(0) // mapping family 0
            header.flip()
            return header
        }

        /**
         * csd-1（codec delay）/ csd-2（seek pre-roll）：纳秒数，64 位、本机字节序。
         *
         * 系统 Opus 解码器把前三个输入缓冲都当配置吃掉，第二、三个按「8 字节纳秒数」解释。
         * 这里塞别的（比如 OpusTags）会被读成一个天文数字的前导延迟，之后解出的样本全被丢弃；
         * 少给一个则会把第一个音频包当配置吞掉。
         */
        private fun nanosecondsCsd(ns: Long): ByteBuffer =
            ByteBuffer.allocate(8).order(ByteOrder.nativeOrder()).putLong(ns).apply { flip() }

        internal fun resampleTo16k(pcm: ShortArray, srcRate: Int): ShortArray {
            if (srcRate == RealtimeAudioSpec.SAMPLE_RATE || srcRate <= 0 || pcm.isEmpty()) {
                return pcm
            }
            if (srcRate % RealtimeAudioSpec.SAMPLE_RATE == 0) {
                val step = srcRate / RealtimeAudioSpec.SAMPLE_RATE
                val outLen = pcm.size / step
                if (outLen <= 0) {
                    return pcm
                }
                val out = ShortArray(outLen)
                var source = 0
                for (i in out.indices) {
                    var acc = 0
                    repeat(step) { acc += pcm[source++].toInt() }
                    out[i] = (acc / step).toShort()
                }
                return out
            }
            val outLen = (pcm.size.toLong() * RealtimeAudioSpec.SAMPLE_RATE / srcRate).toInt()
            if (outLen <= 0) {
                return pcm
            }
            val out = ShortArray(outLen)
            val ratio = srcRate.toDouble() / RealtimeAudioSpec.SAMPLE_RATE
            for (i in out.indices) {
                val src = i * ratio
                val index = src.toInt().coerceIn(0, pcm.lastIndex)
                val next = (index + 1).coerceAtMost(pcm.lastIndex)
                val frac = src - index
                out[i] = ((1 - frac) * pcm[index] + frac * pcm[next]).toInt().toShort()
            }
            return out
        }
    }
}

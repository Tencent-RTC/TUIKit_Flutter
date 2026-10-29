package com.tencent.cloud.tuikit.flutter.tuichatkit.realtimeaudio

import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Build
import android.util.Log
import java.nio.ByteOrder

/**
 * 系统 [MediaCodec] 裸 Opus 编码器：16kHz / 单声道 / 20ms PCM16 → 一包裸 Opus packet。
 *
 * 不加 Ogg。`BUFFER_FLAG_CODEC_CONFIG` 是 codec-specific header，后台不要，这里丢掉。
 * 不用第三方 Opus 库；`audio/opus` 编码器要 Android 10 起且机型注册了才有，见 [isSupported]。
 *
 * 非线程安全。只在采集线程上 [encode] / [reset] / [release]。
 */
class SystemOpusEncoder {

    private var codec: MediaCodec? = null
    private var presentationTimeUs = 0L

    /**
     * 打开编码器。可重复调用；已经打开时直接成功。
     *
     * @return 机型没有 `audio/opus` 或 configure 失败时返回 false
     */
    fun start(): Boolean {
        if (codec != null) {
            return true
        }
        if (!isSupported()) {
            return false
        }
        return try {
            val newCodec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_OPUS)
            val format = MediaFormat.createAudioFormat(
                MediaFormat.MIMETYPE_AUDIO_OPUS,
                RealtimeAudioSpec.SAMPLE_RATE,
                RealtimeAudioSpec.CHANNEL_COUNT,
            )
            format.setInteger(MediaFormat.KEY_BIT_RATE, OPUS_BIT_RATE)
            format.setInteger(MediaFormat.KEY_PCM_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
            newCodec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            newCodec.start()
            codec = newCodec
            true
        } catch (exception: Exception) {
            Log.w(TAG, "configure opus encoder failed", exception)
            false
        }
    }

    /**
     * 送入恰好一帧 PCM，把当前能抽到的裸 packet 交给 [onPacket]。
     *
     * 帧长不对或编码器未打开时什么都不回调。同一帧可能对应 0..n 个 packet
     * （MediaCodec 会缓冲），调用方必须逐包处理，不要拼成一个容器。
     */
    fun encode(pcm: ShortArray, offset: Int = 0, onPacket: (ByteArray) -> Unit) {
        val encoder = codec ?: return
        if (offset < 0 || pcm.size - offset < RealtimeAudioSpec.FRAME_SAMPLES) {
            return
        }
        val inputIndex = encoder.dequeueInputBuffer(DEQUEUE_TIMEOUT_US)
        if (inputIndex >= 0) {
            val inputBuffer = encoder.getInputBuffer(inputIndex)
            if (inputBuffer != null) {
                inputBuffer.clear()
                inputBuffer.order(ByteOrder.nativeOrder())
                inputBuffer.asShortBuffer().put(pcm, offset, RealtimeAudioSpec.FRAME_SAMPLES)
                inputBuffer.position(0)
                inputBuffer.limit(RealtimeAudioSpec.FRAME_BYTES)
                encoder.queueInputBuffer(
                    inputIndex,
                    0,
                    RealtimeAudioSpec.FRAME_BYTES,
                    presentationTimeUs,
                    0,
                )
                presentationTimeUs += FRAME_DURATION_US
            }
        }
        drainOutput(encoder, onPacket)
    }

    /**
     * 丢掉帧间状态，下一帧当作独立起点。
     *
     * 只 [MediaCodec.flush]，不要 stop/release 再新建：拆掉 MediaCodec 的瞬间若 IMSDK 也在用
     * `audio/opus`（startRealtimeTranscriber），识别会话会直接起不来。
     */
    fun reset() {
        codec?.let { encoder ->
            runCatching { encoder.flush() }
        }
        presentationTimeUs = 0L
    }

    fun release() {
        codec?.let { encoder ->
            runCatching { encoder.stop() }
            runCatching { encoder.release() }
        }
        codec = null
        presentationTimeUs = 0L
    }

    private fun drainOutput(encoder: MediaCodec, onPacket: (ByteArray) -> Unit) {
        val info = MediaCodec.BufferInfo()
        while (true) {
            val outputIndex = encoder.dequeueOutputBuffer(info, DEQUEUE_TIMEOUT_US)
            if (outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER) {
                return
            }
            if (outputIndex < 0) {
                continue
            }
            val outputBuffer = encoder.getOutputBuffer(outputIndex)
            if (outputBuffer != null && info.size > 0 &&
                (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) == 0
            ) {
                val packet = ByteArray(info.size)
                outputBuffer.position(info.offset)
                outputBuffer.limit(info.offset + info.size)
                outputBuffer.get(packet)
                onPacket(packet)
            }
            encoder.releaseOutputBuffer(outputIndex, false)
        }
    }

    companion object {
        private const val TAG = "SystemOpusEncoder"
        private const val OPUS_BIT_RATE = 24000
        private const val DEQUEUE_TIMEOUT_US = 10_000L
        private const val FRAME_DURATION_US = 20_000L

        @Volatile
        private var cachedSupported: Boolean? = null

        /** 系统是否注册了 `audio/opus` 编码器。结果缓存，探测本身要遍历全部 codec。 */
        fun isSupported(): Boolean {
            cachedSupported?.let { return it }
            val supported = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                false
            } else {
                runCatching {
                    MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos.any { info: MediaCodecInfo ->
                        info.isEncoder && info.supportedTypes.any {
                            MediaFormat.MIMETYPE_AUDIO_OPUS.equals(it, ignoreCase = true)
                        }
                    }
                }.getOrDefault(false)
            }
            cachedSupported = supported
            return supported
        }

        /** 安全构造。失败返回 null，调用方应关掉语音上行，不要重试。 */
        fun create(): SystemOpusEncoder? {
            val encoder = SystemOpusEncoder()
            return if (encoder.start()) encoder else null
        }
    }
}

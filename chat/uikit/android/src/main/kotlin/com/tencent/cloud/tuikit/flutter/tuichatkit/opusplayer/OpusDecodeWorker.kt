package com.tencent.cloud.tuikit.flutter.tuichatkit.opusplayer

import android.os.Handler
import android.os.HandlerThread
import com.tencent.cloud.tuikit.flutter.tuichatkit.realtimeaudio.RealtimeAudioSpec

/**
 * TTS 下行音频的解码线程：Opus packet → PCM → [OpusPlaybackEngine]。
 *
 * 解码不能放在主线程。[SystemOpusDecoder.decode] 是同步的，每包都要等系统解码器把输出交回来；
 * 而后台合成比实时快得多，长回答的音频几秒内就全部到齐，几百包排着解会把主线程连续占住。
 *
 * [SystemOpusDecoder] 的创建、重置、解码、释放都只在这条线程上；公开方法只在主线程调用。
 *
 * @param onChunkDecoded 一个分片处理完后在解码线程上回调，带着投递时的 [generation]，
 *   调用方切回主线程后自行与当前 [generation] 比对
 */
class OpusDecodeWorker(
    private val playback: OpusPlaybackEngine,
    private val onChunkDecoded: (generation: Int, decodedMs: Long, isFinished: Boolean) -> Unit,
) {

    private val thread = HandlerThread("tts-opus-decode").apply { start() }
    private val handler = Handler(thread.looper)

    /**
     * 第一次真正播 TTS 时才打开：系统 `audio/opus` 编解码器实例有限，提前占着解码器，
     * 再去 startRealtimeTranscriber，识别会话会直接失败。只在解码线程上读写。
     */
    private var decoder: SystemOpusDecoder? = null

    /**
     * 每次 [beginStream] / [invalidate] 自增。解码任务带着投递时的值，入队前在 [enqueueLock]
     * 里比对，对不上说明这段音频属于已被放弃的那一段。
     *
     * 比对和入队必须在同一把锁里：否则解码线程比对通过之后、入队之前，主线程恰好完成
     * 「自增 + flush」，这一包旧音频就会落进刚清空的播放队列。
     */
    @Volatile
    var generation = 0
        private set

    private val enqueueLock = Any()

    /** 新一段 TTS 音频流开始：作废上一段在途音频，丢掉残留的解码器状态。 */
    fun beginStream() {
        synchronized(enqueueLock) {
            generation++
        }
        handler.post {
            val current = decoder
            if (current != null) {
                current.reset()
            } else {
                ensureDecoder()
            }
        }
    }

    /**
     * 解码一个 TTS 分片并送去播放。
     *
     * [isFinished] 时的 markEndOfStream 必须排在本分片最后一包入队之后，**顺序不能调换**：
     * 反过来的话播放线程可能在「已置位但最后一段还没入队」的瞬间看到「endOfStream 且队列空」
     * 而提前收尾。解码线程串行执行，所以它也一定排在之前所有分片之后。
     */
    fun decode(packets: List<ByteArray>, isFinished: Boolean) {
        val gen = generation
        handler.post {
            if (gen != generation) {
                return@post
            }
            var decodedMs = 0L
            for (packet in packets) {
                // 单包解码失败就丢弃这一包继续，不中断整段播放
                val pcm = ensureDecoder()?.decode(packet) ?: continue
                synchronized(enqueueLock) {
                    if (gen != generation) {
                        return@post
                    }
                    playback.enqueue(pcm)
                }
                decodedMs += pcm.size * 1000L / RealtimeAudioSpec.SAMPLE_RATE
            }
            if (isFinished) {
                synchronized(enqueueLock) {
                    if (gen != generation) {
                        return@post
                    }
                    playback.markEndOfStream()
                }
            }
            onChunkDecoded(gen, decodedMs, isFinished)
        }
    }

    /**
     * 作废已投递、还没入队的音频，并复位解码器。主线程调用，之后**必须**紧接着 flush 播放引擎：
     * 自增之后不会再有旧音频入队，自增之前已经入队的由 flush 清掉。顺序反过来就漏了中间那一段。
     */
    fun invalidate() {
        synchronized(enqueueLock) {
            generation++
        }
        handler.post { decoder?.reset() }
    }

    /** 作废全部在途音频、释放解码器并结束线程。之后不能再用。 */
    fun release() {
        synchronized(enqueueLock) {
            generation++
        }
        handler.post {
            decoder?.release()
            decoder = null
        }
        thread.quitSafely()
    }

    private fun ensureDecoder(): SystemOpusDecoder? {
        if (decoder == null) {
            decoder = SystemOpusDecoder.create()
        }
        return decoder
    }
}

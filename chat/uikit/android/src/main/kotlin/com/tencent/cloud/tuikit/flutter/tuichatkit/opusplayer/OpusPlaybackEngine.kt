package com.tencent.cloud.tuikit.flutter.tuichatkit.opusplayer

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.util.Log
import com.tencent.cloud.tuikit.flutter.tuichatkit.realtimeaudio.RealtimeAudioSpec
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicLong
import kotlin.concurrent.thread
import kotlin.math.sqrt

private const val TAG = "OpusPlaybackEngine"

/** 排空硬件缓冲时的轮询间隔 */
private const val DRAIN_POLL_MS = 10L

/** 排空超时在「剩余帧数换算出的毫秒」之上留的余量 */
private const val DRAIN_MARGIN_MS = 200L

/** 排空超时硬上限 */
private const val DRAIN_TIMEOUT_MAX_MS = 2000L

/** 新一轮播放开头淡入，压掉 AudioTrack 从静音拉起来的那一声「呲」。16kHz 下 160 样本 = 10ms。 */
private const val FADE_IN_SAMPLES = 160

/**
 * TTS 音频播放：16kHz / 单声道 / PCM16。
 *
 * 用 USAGE_VOICE_COMMUNICATION 而不是 USAGE_MEDIA，是为了让系统把它识别成通话音频，
 * 从而能作为回声消除的参考信号，防止 TTS 播放被 VAD 误判成用户说话。
 *
 * [onFinished] 在播放线程上回调，需要切主线程由调用方自行 post。
 * 需要 API 23+（`AudioTrack.Builder`），调用方负责版本判断。
 */
class OpusPlaybackEngine(private val onFinished: () -> Unit) {

    private val queue = LinkedBlockingQueue<ShortArray>()
    private var track: AudioTrack? = null
    private var playbackThread: Thread? = null

    @Volatile
    private var running = false

    @Volatile
    private var endOfStream = false

    @Volatile
    private var levelValue = 0f

    /** 有数据写进轨道、还没播完（或被 flush / stop 打断）之前为 true，用于决定是否上报音量。 */
    @Volatile
    private var playing = false

    /**
     * 已经写进 AudioTrack 的帧数（单声道，1 sample = 1 frame），与 playbackHeadPosition 同基准。
     *
     * 只由播放线程累加，由 [start] / [flush] / [stop] 清零——这三处同时也是
     * playbackHeadPosition 归零的时机（flush / stop 会把播放头清零），两者必须一起动。
     *
     * 累加与清零分属两条线程，所以要的是原子的读改写而不只是可见性：volatile 上的 `+=`
     * 会在「播放线程读到旧值」与「写回」之间被 [flush] 的清零插进来，清零就此丢失，
     * 计数器带着整段残值进入下一轮，[awaitDrain] 每次都要白等到超时。
     */
    private val framesWritten = AtomicLong(0L)

    /**
     * 每调用一次 [flush] 自增。播放线程在 poll 之前记下当前值，write 之前再比对，
     * 不相等说明这个 chunk 是 flush 之前的残留，直接丢弃。
     *
     * 只清队列是不够的：播放线程可能刚好已经 poll 出一个 chunk 拿在手里，
     * 那一段仍会被写进去放出来，打断就不干净。
     */
    @Volatile
    private var flushEpoch = 0

    /** 下一包 PCM 需要做开头淡入：新建轨道或 [flush] 重建之后。 */
    @Volatile
    private var fadeInPending = false

    /** 最近一段播放数据的音量，0f..1f */
    val currentLevel: Float
        get() = levelValue

    val isPlaying: Boolean
        get() = playing

    /**
     * 启动播放线程。
     *
     * @return false 表示 `AudioTrack` 没能建起来。引擎没起来时 [enqueue] 会全部丢弃，
     * [onFinished] 也永远不会触发，调用方必须据此降级。
     */
    fun start(): Boolean {
        if (running) {
            return true
        }
        val newTrack = createTrack() ?: return false
        track = newTrack
        running = true
        endOfStream = false
        fadeInPending = true
        framesWritten.set(0L)
        playbackThread = thread(name = "tts-audio-playback", isDaemon = true) { playbackLoop(newTrack) }
        return true
    }

    fun enqueue(pcm: ShortArray) {
        if (!running || pcm.isEmpty()) {
            return
        }
        // 只入队。空缓冲上 play() 会欠载，华为上下一轮第一包常先「呲」一声。
        // 真正的 play 放到播放线程 write 成功之后，见 [playbackLoop]。
        queue.offer(pcm)
    }

    /** 告知不会再有新数据。队列放空、硬件缓冲也播完之后触发 [onFinished]。 */
    fun markEndOfStream() {
        endOfStream = true
    }

    /**
     * 立即停止出声并清空队列，用于说话打断。
     *
     * 华为上 `AudioTrack.flush()` 经常冲不干净 `USAGE_VOICE_COMMUNICATION` 的硬件缓冲，
     * 残样会在下一次 `play()` 时打成一声「呲」。所以这里不信任 flush，而是停掉播放线程、
     * 释放旧轨道、再建一条空的。新轨道在第一包 write 成功之前保持 STOPPED。
     */
    fun flush() {
        flushEpoch++
        queue.clear()
        endOfStream = false
        levelValue = 0f
        playing = false
        framesWritten.set(0L)
        fadeInPending = true
        if (!running) {
            return
        }
        runCatching { track?.pause() }
        running = false
        val worker = playbackThread
        playbackThread = null
        if (worker != null && worker != Thread.currentThread()) {
            runCatching { worker.join(JOIN_TIMEOUT_MS) }
            if (worker.isAlive) {
                Log.w(TAG, "flush: playback thread still alive after ${JOIN_TIMEOUT_MS}ms")
            }
        }
        releaseTrack()
        val newTrack = createTrack()
        if (newTrack == null) {
            Log.e(TAG, "flush: recreate AudioTrack failed")
            return
        }
        track = newTrack
        running = true
        playbackThread = thread(name = "tts-audio-playback", isDaemon = true) { playbackLoop(newTrack) }
        Log.i(TAG, "playback track recreated after flush")
    }

    /**
     * 停止播放并释放资源。可重复调用。
     *
     * 释放前先等播放线程退出：它可能正阻塞在 `write()` 里，或停在排空自旋上，
     * `release()` 之后再碰 track 就是 use-after-release。`running = false` 会让两处都尽快返回。
     */
    fun stop() {
        running = false
        queue.clear()

        val worker = playbackThread
        playbackThread = null
        if (worker != null && worker != Thread.currentThread()) {
            runCatching { worker.join(JOIN_TIMEOUT_MS) }
            if (worker.isAlive) {
                Log.w(TAG, "playback thread still alive after ${JOIN_TIMEOUT_MS}ms, releasing anyway")
            }
        }

        releaseTrack()
        levelValue = 0f
        playing = false
        framesWritten.set(0L)
    }

    private fun createTrack(): AudioTrack? {
        val minBufferSize = AudioTrack.getMinBufferSize(
            RealtimeAudioSpec.SAMPLE_RATE,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        if (minBufferSize <= 0) {
            Log.e(TAG, "getMinBufferSize failed: $minBufferSize")
            return null
        }
        val newTrack = runCatching {
            AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(RealtimeAudioSpec.SAMPLE_RATE)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(maxOf(minBufferSize, RealtimeAudioSpec.FRAME_BYTES * 20))
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build()
        }.getOrElse {
            Log.e(TAG, "create AudioTrack failed", it)
            return null
        }
        if (newTrack.state != AudioTrack.STATE_INITIALIZED) {
            Log.e(TAG, "AudioTrack not initialized")
            newTrack.release()
            return null
        }
        return newTrack
    }

    private fun releaseTrack() {
        val t = track
        track = null
        runCatching {
            t?.pause()
            t?.flush()
            t?.stop()
            t?.release()
        }.onFailure { Log.w(TAG, "release track failed", it) }
    }

    private fun playbackLoop(t: AudioTrack) {
        while (running) {
            val epoch = flushEpoch
            val chunk = try {
                queue.poll(50, TimeUnit.MILLISECONDS)
            } catch (e: InterruptedException) {
                null
            }
            if (chunk == null) {
                // 上游说完了、队列也空了，但硬件缓冲里通常还压着几百毫秒没出声的音频，
                // 要等它真的放完才算这一段结束
                if (endOfStream && queue.isEmpty()) {
                    if (!awaitDrain(t, epoch)) {
                        continue
                    }
                    endOfStream = false
                    levelValue = 0f
                    playing = false
                    onFinished()
                }
                continue
            }
            if (flushEpoch != epoch) {
                // poll 之后、write 之前发生了 flush，这一段属于被打断的内容，丢掉
                continue
            }
            val pcm = applyFadeInIfNeeded(chunk)
            levelValue = levelOf(pcm)
            // 文档要求 MODE_STREAM 先 play 再 write。关键是同一条线程上紧挨着做，
            // 中间不能隔着 enqueue 里那种空等——空轨 play 几十毫秒就会「呲」。
            if (t.playState != AudioTrack.PLAYSTATE_PLAYING) {
                runCatching { t.play() }.onFailure { Log.w(TAG, "play failed", it) }
            }
            val written = runCatching { t.write(pcm, 0, pcm.size) }
                .onFailure { Log.w(TAG, "write failed", it) }
                .getOrDefault(0)
            if (flushEpoch != epoch || !running) {
                Log.i(TAG, "discard write after flush")
                continue
            }
            if (written < 0) {
                Log.w(TAG, "write returned $written")
                continue
            }
            framesWritten.addAndGet(written.toLong())
            playing = true
        }
    }

    /**
     * 等硬件把已写入的数据真正播完。
     *
     * MODE_STREAM 下 write() 只保证数据进了缓冲区，不代表已经从喇叭出去。不等就回调
     * [onFinished] 的话，上层会在话音未落时切回聆听态，而麦克风是常开的，这段尾音会被
     * 当成用户的下一句送进 ASR，同时干扰 VAD 断句。
     *
     * @param epoch 进入本轮循环时的 [flushEpoch]，期间发生 flush 就放弃等待
     * @return true 表示可以回调 [onFinished]；false 表示被 [stop] 或 [flush] 打断
     */
    private fun awaitDrain(t: AudioTrack, epoch: Int): Boolean {
        val target = framesWritten.get()
        if (target <= 0L) {
            return true
        }
        // 超时上限 = 剩余帧数换算的毫秒 + 200ms 余量，再压一个 2s 硬顶。
        // 必须有上限：个别机型的 playbackHeadPosition 可能不推进或行为异常，
        // 真卡住了也得照常回调，否则上层会永久停在播放态再也出不来。
        val remainingMs =
            (target - headPositionOf(t)).coerceAtLeast(0L) * 1000L / RealtimeAudioSpec.SAMPLE_RATE
        val timeoutMs = (remainingMs + DRAIN_MARGIN_MS).coerceAtMost(DRAIN_TIMEOUT_MAX_MS)
        val deadlineNanos = System.nanoTime() + timeoutMs * 1_000_000L

        while (running && flushEpoch == epoch && headPositionOf(t) < target) {
            if (System.nanoTime() - deadlineNanos >= 0) {
                Log.w(TAG, "drain timeout after ${timeoutMs}ms, head=${headPositionOf(t)} written=$target")
                return true
            }
            try {
                Thread.sleep(DRAIN_POLL_MS)
            } catch (e: InterruptedException) {
                return false
            }
        }
        return running && flushEpoch == epoch
    }

    /**
     * getPlaybackHeadPosition() 返回的是 Int，溢出后会回绕成负数，所以按 unsigned 读。
     */
    private fun headPositionOf(t: AudioTrack): Long =
        runCatching { t.playbackHeadPosition.toLong() and 0xFFFFFFFFL }
            .getOrElse {
                Log.w(TAG, "read playbackHeadPosition failed", it)
                Long.MAX_VALUE
            }

    private fun applyFadeInIfNeeded(chunk: ShortArray): ShortArray {
        if (!fadeInPending) {
            return chunk
        }
        fadeInPending = false
        val n = minOf(chunk.size, FADE_IN_SAMPLES)
        if (n <= 1) {
            return chunk
        }
        val faded = chunk.copyOf()
        for (i in 0 until n) {
            val gain = i.toFloat() / n
            faded[i] = (faded[i] * gain).toInt().toShort()
        }
        return faded
    }

    private fun levelOf(pcm: ShortArray): Float {
        var sum = 0.0
        for (s in pcm) {
            val v = s.toDouble()
            sum += v * v
        }
        val rms = sqrt(sum / pcm.size)
        // 6000 是 TTS 输出上的经验满量程参考值，只用来驱动动画
        return (rms / 6000.0).coerceIn(0.0, 1.0).toFloat()
    }

    private companion object {
        /** 播放循环的 poll 超时是 50ms，排空自旋每轮 10ms，200ms 足够它们看到 running=false。 */
        const val JOIN_TIMEOUT_MS = 200L
    }
}

package com.tencent.cloud.tuikit.flutter.tuichatkit.realtimeaudio

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log

/**
 * 通话音频模式：`MODE_IN_COMMUNICATION` + 独占的通话音频焦点。
 *
 * [onFocusChange] 在主线程回调，true 表示重新拿到焦点，false 表示焦点丢失（含短暂丢失）。
 * 只在主线程调用 [enter] / [exit]。
 */
class VoiceCallAudioMode(
    context: Context,
    private val onFocusChange: (gained: Boolean) -> Unit,
) {

    private val audioManager =
        context.applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    /** API 26+ 的焦点句柄，归还焦点时要用同一个对象 */
    private var audioFocusRequest: AudioFocusRequest? = null

    /** 进入通话模式前的全局音频模式，退出时原样还回去 */
    private var previousAudioMode = AudioManager.MODE_NORMAL

    private var active = false
    private var focusGranted = false

    /**
     * DUCK 之类的其余取值对语音通话没有意义，不处理。
     * API 26+ 显式传主线程 Handler；更低版本的回调落在申请线程（主线程）的 Looper 上。
     */
    private val audioFocusListener = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> onFocusChange(false)

            AudioManager.AUDIOFOCUS_GAIN -> onFocusChange(true)

            else -> Unit
        }
    }

    /**
     * USAGE_VOICE_COMMUNICATION 与 TTS 播放的 AudioTrack 属性保持一致，系统据此把这条流当成
     * 通话音频，才可能拿它做回声消除的参考信号。
     *
     * @return 是否拿到音频焦点。拿不到最常见的原因是系统通话正在进行，调用方不必中断通话
     */
    fun enter(): Boolean {
        if (active) {
            return focusGranted
        }
        active = true
        // 真机实测：不设通话模式时，外放期间麦克风被整条清零，机型侧按半双工处理，
        // 说话打断根本拿不到输入。MODE_IN_COMMUNICATION 也是硬件 AEC 真正生效的前提。
        previousAudioMode = audioManager.mode
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                .setOnAudioFocusChangeListener(audioFocusListener, Handler(Looper.getMainLooper()))
                .build()
            audioFocusRequest = request
            audioManager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                audioFocusListener,
                AudioManager.STREAM_VOICE_CALL,
                AudioManager.AUDIOFOCUS_GAIN
            )
        }
        focusGranted = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        if (!focusGranted) {
            Log.w(TAG, "audio focus not granted: $result")
        }
        return focusGranted
    }

    /** 可重复调用。 */
    fun exit() {
        if (!active) {
            return
        }
        active = false
        focusGranted = false
        // 通话模式是全局的，不还回去会让退出后的普通媒体播放走听筒
        audioManager.mode = previousAudioMode
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            audioFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(audioFocusListener)
        }
    }

    private companion object {
        const val TAG = "VoiceCallAudioMode"
    }
}

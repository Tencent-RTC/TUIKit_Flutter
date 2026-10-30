package com.tencent.cloud.tuikit.flutter.tuichatkit.realtimeaudio

/**
 * 实时采集与 TTS 播放共用的固定参数。
 *
 * 音频格式由 IMSDK 实时识别 / TTS 规定：Opus / 16kHz / 单声道 / 裸 packet。
 */
internal object RealtimeAudioSpec {
    const val SAMPLE_RATE = 16000
    const val CHANNEL_COUNT = 1

    /** 20ms @ 16kHz */
    const val FRAME_SAMPLES = 320
    const val FRAME_BYTES = FRAME_SAMPLES * 2
}

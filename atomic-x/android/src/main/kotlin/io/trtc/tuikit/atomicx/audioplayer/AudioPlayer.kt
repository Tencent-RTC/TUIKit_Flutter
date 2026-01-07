package io.trtc.tuikit.atomicx.audioplayer

import io.trtc.tuikit.atomicx.audioplayer.impl.MediaAudioPlayer

abstract class AudioPlayer {
    companion object {
        val shared: AudioPlayer by lazy {
            MediaAudioPlayer()
        }
    }

    abstract fun play(filePath: String)

    abstract fun pause()

    abstract fun resume()

    abstract fun stop()

    abstract fun setListener(listener: AudioPlayerListener?): AudioPlayer

    abstract fun getCurrentPosition(): Int

    abstract fun getDuration(): Int

    abstract fun isPlaying(): Boolean

    abstract fun isPaused(): Boolean
}

enum class AudioOutputDevice {
    SPEAKER,
    EARPIECE
}

interface AudioPlayerListener {

    fun onPlay() {}

    fun onPause() {}

    fun onResume() {}

    fun onProgressUpdate(currentPosition: Int, duration: Int) {}

    fun onCompletion() {}

    fun onError(errorMessage: String) {}

    fun onAudioOutputChanged(device: AudioOutputDevice) {}
}

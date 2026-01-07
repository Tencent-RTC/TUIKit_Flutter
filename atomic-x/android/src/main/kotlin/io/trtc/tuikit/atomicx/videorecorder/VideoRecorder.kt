package io.trtc.tuikit.atomicx.videorecorder

import io.trtc.tuikit.atomicx.videorecorder.impl.VideoRecorderViewImpl

object VideoRecorder {
    private val instance = VideoRecorderViewImpl()

    /**
     * Launches the camera capture interface
     * @param config Capture configuration settings
     * @param listener Callback interface for receiving capture results, including:
     *                 - Photo capture success
     *                 - Video recording success
     */
    fun startRecord(config: VideoRecorderConfig = VideoRecorderConfig(), listener: VideoRecordListener) {
        instance.takeVideo(config, listener)
    }
}

data class VideoRecorderConfig(
    var recordMode: RecordMode? = null,
    var videoQuality: VideoQuality? = null,
    var minDurationMs: Int? = null,
    var maxDurationMs: Int? = null,
    var isDefaultFrontCamera: Boolean? = null,
    var isSupportEdit: Boolean? = null,
    var isSupportBeauty: Boolean? = null,
    var isSupportRecordScrollFilter: Boolean? = null,
    var isSupportTorch: Boolean? = null,
    var isSupportAspect:Boolean? = null
)

enum class RecordMode(val value: Int) {
    MIXED(0),
    PHOTO_ONLY(1),
    VIDEO_ONLY(2);

    companion object {
        fun fromInteger(value: Int): RecordMode {
            return RecordMode.entries.find { it.value == value } ?: MIXED
        }
    }
}

interface VideoRecordListener {
    fun onPhotoCaptured(filePath: String?) {}

    fun onVideoCaptured(filePath: String?, durationMs: Int, thumbnailPath: String?) {}
}

enum class VideoQuality(val value: Int) {
    LOW(1),
    MEDIUM(2),
    HIGH(3);

    companion object {
        fun fromInteger(value: Int): VideoQuality {
            return VideoQuality.entries.find { it.value == value } ?: LOW
        }
    }
}
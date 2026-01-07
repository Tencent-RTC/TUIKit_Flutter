package io.trtc.tuikit.atomicx.videorecorder.view

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import io.trtc.tuikit.atomicx.videorecorder.RecordMode
import io.trtc.tuikit.atomicx.videorecorder.VideoRecordListener
import io.trtc.tuikit.atomicx.videorecorder.config.VideoRecorderConfigInternal
import io.trtc.tuikit.atomicx.videorecorder.config.VideoRecorderConstants
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderFileUtil

class VideoRecorderBridgeActivity : ComponentActivity() {
    companion object {
        private const val TAG = "VideoRecorderBridge"
        var callback: VideoRecordListener? = null
    }

    class VideoRecordResult {
        var filePath: String? = null
        var type: Int = VideoRecorderConstants.RECORD_TYPE_VIDEO
        var duration: Int = 0
    }

    private val cameraLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        var finalPath: String? = null
        var recordResult:VideoRecordResult? = null
        if (result.resultCode != RESULT_OK) {
            Log.i(TAG, "The activity did not return RESULT_OK, indicating the operation was canceled or failed.")
        } else {
            recordResult = getRecodeResult(result)
            finalPath = recordResult?.filePath
            Log.i(TAG, "recode file complete. path is $finalPath")
            if (finalPath.isNullOrEmpty()) {
                print("recode file path.is null or empty")
                finalPath = null
            }
        }

        if (recordResult == null) {
            if (VideoRecorderConfigInternal.getInstance().getRecordMode() == RecordMode.PHOTO_ONLY) {
                callback?.onPhotoCaptured(null)
            } else {
                callback?.onVideoCaptured(null, 0, null)
            }
        } else {
            if (recordResult.type == VideoRecorderConstants.RECORD_TYPE_VIDEO) {
                callback?.onVideoCaptured(finalPath, recordResult.duration, getVideoThumbnailPath(finalPath))
            } else {
                callback?.onPhotoCaptured(finalPath)
            }
        }
        finish()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setTheme(android.R.style.Theme_Translucent_NoTitleBar)
        val intent = Intent(this, VideoRecorderActivity::class.java)
        cameraLauncher.launch(intent)
    }

    private fun getRecodeResult(result: ActivityResult?): VideoRecordResult? {
        if (result == null) {
            return null
        }
        val resultBundle: Bundle = result.data?.extras ?: return null
        val recordeResult = VideoRecordResult()
        recordeResult.filePath = resultBundle.getString(VideoRecorderConstants.PARAM_NAME_EDITED_FILE_PATH)
        recordeResult.type = resultBundle.getInt(VideoRecorderConstants.RESULT_NAME_RECORD_TYPE)
        recordeResult.duration = resultBundle.getInt(VideoRecorderConstants.RESULT_NAME_RECORD_DURATION)
        return recordeResult
    }

    fun getVideoThumbnailPath(path: String?): String? {
        if (path == null) {
            return null;
        }

        return try {
            val retriever = android.media.MediaMetadataRetriever()
            retriever.setDataSource(path)
            val bitmap = retriever.frameAtTime
            retriever.release()
            if (bitmap == null) return null
            var file = VideoRecorderFileUtil.generateRecodeFilePath(VideoRecorderFileUtil.VideoRecodeFileType.PICTURE_FILE)
            java.io.FileOutputStream(file).use { out ->
                bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 90, out)
            }
            file.toString()
        } catch (e: Exception) {
            Log.e(TAG, "getVideoThumbnailPath failed", e)
            null
        }
    }
}
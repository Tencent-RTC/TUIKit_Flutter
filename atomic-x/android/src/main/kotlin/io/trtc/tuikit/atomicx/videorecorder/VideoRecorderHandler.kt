package io.trtc.tuikit.atomicx.videorecorder

import android.app.Application
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.trtc.tuikit.atomicx.basecomponent.theme.ThemeState
import io.trtc.tuikit.atomicx.basecomponent.utils.ContextProvider
import io.trtc.tuikit.atomicx.utils.LocaleUtils
import io.trtc.tuikit.atomicx.videorecorder.view.VideoRecorderActivity

class VideoRecorderHandler {
    companion object {
        private const val TAG = "VideoRecorderHandler"
    }

    private var pendingResult: MethodChannel.Result? = null
    private var lifecycleCallbacks: Application.ActivityLifecycleCallbacks? = null

    fun handleStartRecord(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "handleStartRecord called")

        if (pendingResult != null) {
            Log.w(TAG, "VideoRecorder is already active")
            result.error("ALREADY_ACTIVE", "VideoRecorder is already active", null)
            return
        }

        try {
            pendingResult = result

            // 解析配置参数
            val recordModeInt = call.argument<Int>("recordMode")
            val videoQualityInt = call.argument<Int>("videoQuality")
            val minDurationMs = call.argument<Int>("minDurationMs")
            val maxDurationMs = call.argument<Int>("maxDurationMs")
            val isDefaultFrontCamera = call.argument<Boolean>("isDefaultFrontCamera")
            val isSupportEdit = call.argument<Boolean>("isSupportEdit")
            val isSupportBeauty = call.argument<Boolean>("isSupportBeauty")
            val isSupportRecordScrollFilter = call.argument<Boolean>("isSupportRecordScrollFilter")
            val isSupportTorch = call.argument<Boolean>("isSupportTorch")
            val isSupportAspect = call.argument<Boolean>("isSupportAspect")
            val primaryColor = call.argument<String>("primaryColor")
            val languageCode = call.argument<String>("languageCode")
            val countryCode = call.argument<String>("countryCode")
            val scriptCode = call.argument<String>("scriptCode")

            Log.d(TAG, "Config - recordMode: $recordModeInt, videoQuality: $videoQualityInt, primaryColor: $primaryColor, language: $languageCode")

            // 设置主题色
            if (!primaryColor.isNullOrEmpty()) {
                ThemeState.shared.setPrimaryColor(primaryColor)
            }

            // 设置语言
            if (!languageCode.isNullOrEmpty()) {
                setupLanguageCallback(languageCode, countryCode, scriptCode)
            }

            // 构建配置
            val config = VideoRecorderConfig(
                recordMode = recordModeInt?.let { RecordMode.fromInteger(it) },
                videoQuality = videoQualityInt?.let { 
                    // Flutter 枚举的 index 从 0 开始，但 VideoQuality 的 value 从 1 开始
                    VideoQuality.fromInteger(it + 1) 
                },
                minDurationMs = minDurationMs,
                maxDurationMs = maxDurationMs,
                isDefaultFrontCamera = isDefaultFrontCamera,
                isSupportEdit = isSupportEdit,
                isSupportBeauty = isSupportBeauty,
                isSupportRecordScrollFilter = isSupportRecordScrollFilter,
                isSupportTorch = isSupportTorch,
                isSupportAspect = isSupportAspect
            )

            // 调用原生录制
            VideoRecorder.startRecord(config, object : VideoRecordListener {
                override fun onPhotoCaptured(filePath: String?) {
                    Log.d(TAG, "onPhotoCaptured: $filePath")
                    
                    val resultMap = mapOf(
                        "type" to "photo",
                        "filePath" to (filePath ?: "")
                    )
                    
                    pendingResult?.success(resultMap)
                    pendingResult = null
                    cleanupLanguageCallback()
                }

                override fun onVideoCaptured(filePath: String?, durationMs: Int, thumbnailPath: String?) {
                    Log.d(TAG, "onVideoCaptured: path=$filePath, duration=$durationMs, thumbnail=$thumbnailPath")
                    
                    val resultMap = mapOf(
                        "type" to "video",
                        "filePath" to (filePath ?: ""),
                        "durationMs" to durationMs,
                        "thumbnailPath" to (thumbnailPath ?: "")
                    )
                    
                    pendingResult?.success(resultMap)
                    pendingResult = null
                    cleanupLanguageCallback()
                }
            })

        } catch (e: Exception) {
            Log.e(TAG, "Error in handleStartRecord", e)
            pendingResult?.error("VIDEO_RECORDER_ERROR", e.message, null)
            pendingResult = null
            cleanupLanguageCallback()
        }
    }

    private fun setupLanguageCallback(languageCode: String, countryCode: String?, scriptCode: String?) {
        val application = ContextProvider.appContext as? Application ?: return
        
        lifecycleCallbacks = LocaleUtils.registerLanguageCallback(
            application = application,
            targetActivityClass = VideoRecorderActivity::class.java,
            languageCode = languageCode,
            countryCode = countryCode,
            scriptCode = scriptCode,
            onActivityDestroyed = {
                cleanupLanguageCallback()
            }
        )
    }

    private fun cleanupLanguageCallback() {
        val application = ContextProvider.appContext as? Application
        application?.let {
            LocaleUtils.unregisterLanguageCallback(it, lifecycleCallbacks)
            lifecycleCallbacks = null
        }
    }
}


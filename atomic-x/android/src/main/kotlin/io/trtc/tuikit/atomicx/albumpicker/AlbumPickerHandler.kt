package io.trtc.tuikit.atomicx.albumpicker

import android.app.Application
import android.net.Uri
import android.text.TextUtils
import android.util.Log
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.trtc.tuikit.atomicx.albumpicker.interfaces.AlbumPickerListener
import io.trtc.tuikit.atomicx.albumpicker.ui.picker.AlbumPickerActivity
import io.trtc.tuikit.atomicx.basecomponent.utils.ContextProvider
import io.trtc.tuikit.atomicx.messageinput.utils.FileUtils
import io.trtc.tuikit.atomicx.utils.LocaleUtils

/**
 * AlbumPickerHandler
 *
 */
class AlbumPickerHandler(
    private val eventSink: (Map<String, Any>) -> Unit
) {

    companion object {
        private const val TAG = "AlbumPickerHandler"
    }

    private var pendingResult: MethodChannel.Result? = null
    private var lifecycleCallbacks: Application.ActivityLifecycleCallbacks? = null

    fun handlePickMedia(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "handlePickMedia called")

        if (pendingResult != null) {
            Log.w(TAG, "AlbumPicker is already active")
            result.error("ALREADY_ACTIVE", "AlbumPicker is already active", null)
            return
        }

        try {
            pendingResult = result

            val pickModeInt = call.argument<Int>("pickMode") ?: 1
            val maxCount = call.argument<Int>("maxCount") ?: 9
            val gridCount = call.argument<Int>("gridCount") ?: 4
            val primaryColor = call.argument<Int>("primaryColor") ?: -1
            val languageCode = call.argument<String>("languageCode")
            val countryCode = call.argument<String>("countryCode")
            val scriptCode = call.argument<String>("scriptCode")

            Log.d(
                TAG,
                "Config - pickMode: $pickModeInt, maxCount: $maxCount, gridCount: $gridCount, primaryColor: $primaryColor, language: $languageCode"
            )

            val pickMode = when (pickModeInt) {
                0 -> PickMode.IMAGE
                1 -> PickMode.VIDEO
                2 -> PickMode.ALL
                else -> PickMode.ALL
            }

            val config = AlbumPickerConfig(
                pickMode = pickMode,
                maxCount = maxCount,
                gridCount = gridCount,
                primaryColor = if (primaryColor != -1) primaryColor else -1,
            )

            if (!languageCode.isNullOrEmpty()) {
                setupLanguageCallback(languageCode, countryCode, scriptCode)
            }

            AlbumPicker.pickMedia(config, object : AlbumPickerListener {
                override fun onFinishedSelect(count: Int) {
                    Log.d(TAG, "onFinishedSelect: $count items")
                    
                    if (count == 0) {
                        // 用户取消
                        pendingResult?.success(null)
                        pendingResult = null
                        cleanupLanguageCallback()
                    }
                }

                override fun onProgress(model: AlbumPickerModel, index: Int, progress: Double) {
                    Log.d(TAG, "onProgress: index=$index, progress=$progress")
                    
                    try {
                        val mediaPathUri = model.mediaPath ?: ""
                        if (mediaPathUri.isEmpty()) {
                            Log.e(TAG, "model.mediaPath is empty")
                            return
                        }

                        val context = ContextProvider.appContext
                        val uri = Uri.parse(mediaPathUri)
                        val mediaPath = FileUtils.getPathFromUri(context, uri)
                        
                        if (mediaPath.isEmpty()) {
                            Log.e(TAG, "Failed to convert URI to path: $mediaPathUri")
                            return
                        }
                        
                        Log.d(TAG, "Converted URI to path: $mediaPathUri -> $mediaPath")

                        val fileExtension = FileUtils.getFileExtensionFromUrl(mediaPath)
                        val fileSize = FileUtils.getFileSize(mediaPath)

                        val mediaTypeValue = when (model.mediaType) {
                            PickMediaType.IMAGE -> 0
                            PickMediaType.VIDEO -> 1
                            PickMediaType.GIF -> 2
                        }

                        Log.d(
                            TAG,
                            "Processed file: path=$mediaPath, size=$fileSize, type=$mediaTypeValue"
                        )

                        // 构建数据字典
                        val dataMap = mutableMapOf(
                            "id" to model.id.toLong(),
                            "mediaType" to mediaTypeValue,
                            "mediaPath" to mediaPath,
                            "fileExtension" to fileExtension,
                            "fileSize" to fileSize,
                            "isOrigin" to model.isOrigin
                        )
                        
                        // 如果是视频且有缩略图，直接添加缩略图路径
                        if (mediaTypeValue == 1 && model.videoThumbnailPath != null) {
                            dataMap["videoThumbnailPath"] = model.videoThumbnailPath
                        }

                        // 发送进度事件
                        val progressEvent = mapOf(
                            "type" to "progress",
                            "index" to index,
                            "progress" to progress,
                            "data" to dataMap
                        )
                        eventSink(progressEvent)

                        // 当所有资源处理完成时，结束
                        if (progress >= 1.0) {
                            pendingResult?.success(null)
                            pendingResult = null
                            cleanupLanguageCallback()
                        }

                    } catch (e: Exception) {
                        Log.e(TAG, "Error processing model: $model", e)
                    }
                }
            })

        } catch (e: Exception) {
            Log.e(TAG, "Error in handlePickMedia", e)
            pendingResult?.error("ALBUM_PICKER_ERROR", e.message, null)
            pendingResult = null
            cleanupLanguageCallback()
        }
    }

    private fun setupLanguageCallback(languageCode: String, countryCode: String?, scriptCode: String?) {
        val application = ContextProvider.appContext as? Application ?: return
        
        lifecycleCallbacks = LocaleUtils.registerLanguageCallback(
            application = application,
            targetActivityClass = AlbumPickerActivity::class.java,
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

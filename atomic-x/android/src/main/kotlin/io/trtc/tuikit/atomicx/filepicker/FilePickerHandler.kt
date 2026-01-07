package io.trtc.tuikit.atomicx.filepicker

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.text.TextUtils
import android.util.Log
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale

class FilePickerHandler(
    private val context: Context,
    private val methodChannel: MethodChannel
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "FilePickerHandler"
        private const val FILE_PROVIDER_AUTH = ".BaseComponent.FileProvider"
    }

    private var pendingResult: MethodChannel.Result? = null

    init {
        setupFilePickerCallbacks()
    }

    private fun setupFilePickerCallbacks() {
        // Callbacks will be set when pickFiles is called
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFiles" -> pickFiles(call, result)
            "openFile" -> openFile(call, result)
            else -> result.notImplemented()
        }
    }

    private fun pickFiles(call: MethodCall, result: MethodChannel.Result) {
        val maxCount = call.argument<Int>("maxCount") ?: 1
        val allowedMimeTypes = call.argument<List<String>>("allowedMimeTypes") ?: emptyList()

        pendingResult = result

        val config = FilePickerConfig(
            allowedMimeTypes = allowedMimeTypes,
            maxCount = maxCount
        )

        FilePicker.pickFiles(config, object : FilePickerListener {
            override fun onPicked(result: List<FilePickerResult>) {
                val resultData = result.map { file ->
                    mapOf(
                        "filePath" to file.filePath,
                        "fileName" to file.fileName,
                        "fileSize" to file.fileSize,
                        "extension" to file.extension
                    )
                }
                pendingResult?.success(resultData)
                pendingResult = null
            }

            override fun onCanceled() {
                pendingResult?.success(emptyList<Map<String, Any>>())
                pendingResult = null
            }
        })
    }

    /**
     * Open file with system default application
     * Reference: FileUtils.kt from android_compose
     */
    private fun openFile(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath")
        if (filePath.isNullOrEmpty()) {
            Log.e(TAG, "openFile failed: file path is required")
            result.error("INVALID_ARGUMENTS", "File path is required", null)
            return
        }

        try {
            val file = File(filePath)
            
            // Check if file exists
            if (!file.exists()) {
                Log.e(TAG, "openFile failed: file does not exist - $filePath")
                result.success(false)
                return
            }

            // Get URI from file path
            val uri = getUriFromPath(filePath)
            if (uri == null) {
                Log.e(TAG, "openFile failed: uri is null")
                result.success(false)
                return
            }

            // Get file extension and MIME type
            val fileExtension = getFileExtensionFromUrl(filePath)
            val mimeType = if (fileExtension.isNotEmpty()) {
                MimeTypeMap.getSingleton().getMimeTypeFromExtension(fileExtension)
            } else {
                null
            } ?: "*/*"

            Log.d(TAG, "Opening file: $filePath, extension: $fileExtension, MIME type: $mimeType")

            // Create intent
            val intent = Intent(Intent.ACTION_VIEW).apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                setDataAndType(uri, mimeType)
            }

            // Use chooser to let user select app
            val chooserIntent = Intent.createChooser(intent, "Open file with")
            chooserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            context.startActivity(chooserIntent)
            Log.d(TAG, "File opened successfully")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "openFile failed: ${e.message}", e)
            result.success(false)
        }
    }

    /**
     * Get URI from file path
     * For Android N (API 24) and above, use FileProvider
     * For older versions, use Uri.fromFile
     */
    private fun getUriFromPath(path: String): Uri? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(
                    context,
                    context.applicationInfo.packageName + FILE_PROVIDER_AUTH,
                    File(path)
                )
            } else {
                Uri.fromFile(File(path))
            }
        } catch (e: Exception) {
            Log.e(TAG, "getUriFromPath failed: ${e.message}", e)
            null
        }
    }

    /**
     * Get file extension from URL or file path
     * Reference: FileUtils.kt from android_compose
     */
    private fun getFileExtensionFromUrl(url: String): String {
        var processedUrl = url
        if (!TextUtils.isEmpty(processedUrl)) {
            // Remove fragment
            val fragment = processedUrl.lastIndexOf('#')
            if (fragment > 0) {
                processedUrl = processedUrl.substring(0, fragment)
            }

            // Remove query parameters
            val query = processedUrl.lastIndexOf('?')
            if (query > 0) {
                processedUrl = processedUrl.substring(0, query)
            }

            // Extract filename
            val filenamePos = processedUrl.lastIndexOf('/')
            val filename = if (0 <= filenamePos) {
                processedUrl.substring(filenamePos + 1)
            } else {
                processedUrl
            }

            // Extract extension
            if (filename.isNotEmpty()) {
                val dotPos = filename.lastIndexOf('.')
                if (0 <= dotPos) {
                    return filename.substring(dotPos + 1).lowercase(Locale.getDefault())
                }
            }
        }

        return ""
    }

    fun dispose() {
        pendingResult = null
    }
}

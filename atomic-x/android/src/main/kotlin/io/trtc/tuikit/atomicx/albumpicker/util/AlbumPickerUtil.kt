package io.trtc.tuikit.atomicx.albumpicker.util

import android.content.pm.PackageManager
import android.util.Log
import com.tencent.qcloud.tuicore.ServiceInitializer

object AlbumPickerUtil {
    fun ensureVideoThumbnailPath(context: android.content.Context, uri: android.net.Uri): String? {
        return try {
            val retriever = android.media.MediaMetadataRetriever()
            retriever.setDataSource(context, uri)
            val bitmap = retriever.frameAtTime
            retriever.release()
            if (bitmap == null) return null
            val file = java.io.File(context.cacheDir, "album_picker_thumb_${System.currentTimeMillis()}.jpg")
            java.io.FileOutputStream(file).use { out ->
                bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 85, out)
            }
            file.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "ensureVideoThumbnailPath failed", e)
            null
        }
    }

    fun generateId(mediaPath: String?): ULong {
        return try {
            val seed = (mediaPath ?: "") + "#" + System.nanoTime().toString()
            val uuid = java.util.UUID.nameUUIDFromBytes(seed.toByteArray(Charsets.UTF_8))
            (uuid.mostSignificantBits xor uuid.leastSignificantBits).toULong()
        } catch (e: Exception) {
            System.nanoTime().toULong()
        }
    }
    private const val TAG = "AlbumPickerUtil"

    @JvmStatic
    fun getAppName(): String {
        var appName = ""
        val context = ServiceInitializer.getAppContext()
        val packageManager = context.packageManager
        try {
            val applicationInfo = packageManager.getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)
            packageManager.getApplicationLabel(applicationInfo)
            val labelCharSequence = applicationInfo.loadLabel(packageManager)
            if (labelCharSequence.isNotEmpty()) {
                appName = labelCharSequence.toString()
            }
        } catch (e: PackageManager.NameNotFoundException) {
            Log.e(TAG, "getAppName exception:${e.message}")
        }
        return appName
    }
} 
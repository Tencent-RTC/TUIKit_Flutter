package io.trtc.tuikit.atomicx.filepicker.util

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

object FilePickerUtils {
    
    fun getFileName(context: Context, uri: Uri): String? {
        var result: String? = null
        
        if (uri.scheme == ContentResolver.SCHEME_CONTENT) {
            context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1) {
                        result = cursor.getString(nameIndex)
                    }
                }
            }
        }
        
        if (result == null) {
            result = uri.path
            val cut = result?.lastIndexOf('/')
            if (cut != -1 && cut != null) {
                result = result?.substring(cut + 1)
            }
        }
        
        return result
    }
    
    fun getFileSize(context: Context, uri: Uri): Long {
        var fileSize = -1L
        
        if (uri.scheme == ContentResolver.SCHEME_CONTENT) {
            context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                    if (sizeIndex != -1) {
                        fileSize = cursor.getLong(sizeIndex)
                    }
                }
            }
        }
        
        if (fileSize == -1L) {
            try {
                context.contentResolver.openInputStream(uri)?.use { inputStream ->
                    fileSize = inputStream.available().toLong()
                }
            } catch (e: IOException) {
                e.printStackTrace()
            }
        }
        
        return fileSize
    }
    
    fun getMimeType(context: Context, uri: Uri): String? {
        var mimeType: String? = context.contentResolver.getType(uri)
        
        if (mimeType == null) {
            val extension = MimeTypeMap.getFileExtensionFromUrl(uri.toString())
            if (extension != null) {
                mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.lowercase())
            }
        }
        
        return mimeType
    }
    
    fun copyFileToAppDir(context: Context, uri: Uri, directory: String = "files"): File? {
        val fileName = getFileName(context, uri) ?: return null
        
        val targetDir = File(context.filesDir, directory)
        if (!targetDir.exists() && !targetDir.mkdirs()) {
            return null
        }
        
        // Generate unique filename with timestamp
        val timestamp = System.currentTimeMillis()
        val uniqueFileName = "${timestamp}_$fileName"
        val targetFile = File(targetDir, uniqueFileName)
        
        try {
            context.contentResolver.openInputStream(uri)?.use { inputStream ->
                FileOutputStream(targetFile).use { outputStream ->
                    val buffer = ByteArray(4 * 1024) // 4KB buffer
                    var read: Int
                    while (inputStream.read(buffer).also { read = it } != -1) {
                        outputStream.write(buffer, 0, read)
                    }
                    outputStream.flush()
                }
            }
            return targetFile
        } catch (e: IOException) {
            e.printStackTrace()
            if (targetFile.exists()) {
                targetFile.delete()
            }
        }
        
        return null
    }
    
    fun formatFileSize(size: Long): String {
        if (size <= 0) return "0 B"
        val units = arrayOf("B", "KB", "MB", "GB", "TB")
        val digitGroups = (Math.log10(size.toDouble()) / Math.log10(1024.0)).toInt()
        return String.format("%.1f %s", size / Math.pow(1024.0, digitGroups.toDouble()), units[digitGroups])
    }
}

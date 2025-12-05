package io.trtc.tuikit.atomicx.albumpicker.util

import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import android.text.TextUtils
import com.tencent.qcloud.tuicore.ServiceInitializer
import java.util.Locale

object FileUtil {
    fun getFileName(context: Context, uri: Uri): String? {
        val mimeType = context.contentResolver.getType(uri)
        var filename: String? = null

        if (mimeType == null) {
            filename = FileUtil.getName(uri.toString())
        } else {
            val returnCursor = context.contentResolver.query(uri, null, null, null, null)
            if (returnCursor != null) {
                val nameIndex = returnCursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                returnCursor.moveToFirst()
                filename = returnCursor.getString(nameIndex)
                returnCursor.close()
            }
        }

        return filename
    }

    fun getName(filePath: String?): String? {
        if (filePath == null) {
            return null
        }
        val index = filePath.lastIndexOf('/')
        return filePath.substring(index + 1)
    }

    // fix the problem that getFileExtensionFromUrl does not support Chinese
    fun getFileExtensionFromUrl(url: String): String {
        var url = url
        if (!TextUtils.isEmpty(url)) {
            val fragment = url.lastIndexOf('#')
            if (fragment > 0) {
                url = url.substring(0, fragment)
            }

            val query = url.lastIndexOf('?')
            if (query > 0) {
                url = url.substring(0, query)
            }

            val filenamePos = url.lastIndexOf('/')
            val filename = if (0 <= filenamePos) url.substring(filenamePos + 1) else url

            // if the filename contains special characters, we don't
            // consider it valid for our matching purposes:

            //          if (!filename.isEmpty() && Pattern.matches("[a-zA-Z_0-9\\.\\-\\(\\)\\%]+", filename))
            if (!filename.isEmpty()) {
                val dotPos = filename.lastIndexOf('.')
                if (0 <= dotPos) {
                    return filename.substring(dotPos + 1).lowercase(Locale.getDefault())
                }
            }
        }

        return ""
    }


    fun isFileSizeExceedsLimit(data: Uri, maxSize: Int): Boolean {
        try {
            val returnCursor: Cursor? =
                ServiceInitializer.getAppContext().getContentResolver().query(data, null, null, null, null)
            if (returnCursor != null) {
                val sizeIndex = returnCursor.getColumnIndex(OpenableColumns.SIZE)
                returnCursor.moveToFirst()
                val size = returnCursor.getInt(sizeIndex)
                if (size > maxSize) {
                    return true
                }
                returnCursor.close()
                return false
            }
            return false
        } catch (e: Exception) {
            return false
        }
    }
}

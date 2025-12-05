package io.trtc.tuikit.atomicx.messageinput.utils

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.text.TextUtils
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Locale

object FileUtils {
    const val DOCUMENTS_DIR: String = "documents"

    const val FILE_PROVIDER_AUTH: String = ".MessageInput.FileProvider"

    const val SIZETYPE_B: Int = 1
    const val SIZETYPE_KB: Int = 2
    const val SIZETYPE_MB: Int = 3
    const val SIZETYPE_GB: Int = 4

    fun deleteFile(path: String?): Boolean {
        if (TextUtils.isEmpty(path)) {
            return false
        }
        var result = false
        val file = File(path)
        if (file.exists()) {
            result = file.delete()
        }
        return result
    }

    fun getPathFromUri(context: Context, uri: Uri): String {
        var path: String? = ""
        try {
            val sdkVersion = Build.VERSION.SDK_INT
            path = if (sdkVersion >= 19) {
                getPathByCopyFile(context, uri)
            } else {
                getRealFilePath(context, uri)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        if (path == null) {
            path = ""
        }
        return path
    }

    fun getRealFilePath(context: Context, uri: Uri?): String? {
        if (null == uri) {
            return null
        }
        val scheme = uri.scheme
        var data: String? = null
        if (scheme == null) {
            data = uri.path
        } else if (ContentResolver.SCHEME_FILE == scheme) {
            data = uri.path
        } else if (ContentResolver.SCHEME_CONTENT == scheme) {
            val cursor = context.contentResolver.query(
                uri, arrayOf(MediaStore.Images.ImageColumns.DATA), null, null, null
            )
            if (null != cursor) {
                if (cursor.moveToFirst()) {
                    val index = cursor.getColumnIndex(MediaStore.Images.ImageColumns.DATA)
                    if (index > -1) {
                        data = cursor.getString(index)
                    }
                }
                cursor.close()
            }
        }
        return data
    }


    private fun getPathByCopyFile(context: Context, uri: Uri): String? {
        val fileName = getFileName(context, uri)
        val cacheDir = getDocumentCacheDir(context)
        val file = generateFileName(fileName, cacheDir)
        var destinationPath: String? = null
        if (file != null) {
            destinationPath = file.absolutePath
            val saveSuccess = saveFileFromUri(context, uri, destinationPath)
            if (!saveSuccess) {
                file.delete()
                return null
            }
        }

        return destinationPath
    }

    fun generateFileName(name: String?, directory: File?): File? {
        var name = name ?: return null

        var file = File(directory, name)

        if (file.exists()) {
            var fileName = name
            var extension = ""
            val dotIndex = name.lastIndexOf('.')
            if (dotIndex > 0) {
                fileName = name.substring(0, dotIndex)
                extension = name.substring(dotIndex)
            }

            var index = 0

            while (file.exists()) {
                index++
                name = "$fileName($index)$extension"
                file = File(directory, name)
            }
        }

        try {
            if (!file.createNewFile()) {
                return null
            }
        } catch (e: IOException) {
            e.printStackTrace()
            return null
        }

        return file
    }

    fun getFileName(context: Context, uri: Uri): String? {
        val mimeType = context.contentResolver.getType(uri)
        var filename: String? = null

        if (mimeType == null) {
            filename = getFileName(uri.toString())
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

    fun getFileName(filePath: String?): String? {
        if (filePath == null) {
            return null
        }
        val index = filePath.lastIndexOf('/')
        return filePath.substring(index + 1)
    }

    fun getDocumentCacheDir(context: Context): File {
        val dir = File(context.cacheDir, DOCUMENTS_DIR)
        if (!dir.exists()) {
            dir.mkdirs()
        }

        return dir
    }

    private fun saveFileFromUri(context: Context, uri: Uri, destinationPath: String?): Boolean {
        var `is`: InputStream? = null
        var bos: BufferedOutputStream? = null
        try {
            `is` = context.contentResolver.openInputStream(uri)
            bos = BufferedOutputStream(FileOutputStream(destinationPath, false))
            val buf = ByteArray(1024)

            var actualBytes: Int
            while ((`is`!!.read(buf).also { actualBytes = it }) != -1) {
                bos.write(buf, 0, actualBytes)
            }
        } catch (e: IOException) {
            e.printStackTrace()
            return false
        } finally {
            try {
                `is`?.close()
                bos?.close()
            } catch (e: IOException) {
                e.printStackTrace()
            }
        }
        return true
    }

    /**
     * Get the value of the data column for this Uri. This is useful for
     * MediaStore Uris, and other file-based ContentProviders.
     *
     * @param context       The context.
     * @param uri           The Uri to query.
     * @param selection     (Optional) Filter used in the query.
     * @param selectionArgs (Optional) Selection arguments used in the query.
     * @return The value of the _data column, which is typically a file path.
     */
    fun getDataColumn(context: Context, uri: Uri, selection: String?, selectionArgs: Array<String>?): String? {
        var cursor: Cursor? = null
        val column = "_data"
        val projection = arrayOf(column)

        try {
            cursor = context.contentResolver.query(uri, projection, selection, selectionArgs, null)
            if (cursor != null && cursor.moveToFirst()) {
                val column_index = cursor.getColumnIndexOrThrow(column)
                return cursor.getString(column_index)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            cursor?.close()
        }
        return null
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is ExternalStorageProvider.
     */
    fun isExternalStorageDocument(uri: Uri): Boolean {
        return "com.android.externalstorage.documents" == uri.authority
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is DownloadsProvider.
     */
    fun isDownloadsDocument(uri: Uri): Boolean {
        return "com.android.providers.downloads.documents" == uri.authority
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is MediaProvider.
     */
    fun isMediaDocument(uri: Uri): Boolean {
        return "com.android.providers.media.documents" == uri.authority
    }

    /**
     *
     * Convert file size to string
     *
     * @param fileS
     * @return
     */
    fun formatFileSize(fileS: Long): String {
        val symbols = DecimalFormatSymbols(Locale.US)
        val df = DecimalFormat("#.00", symbols)
        var fileSizeString = ""
        val wrongSize = "0B"
        if (fileS == 0L) {
            return wrongSize
        }
        fileSizeString = if (fileS < 1024) {
            df.format(fileS.toDouble()) + "B"
        } else if (fileS < 1048576) {
            df.format(fileS.toDouble() / 1024) + "KB"
        } else if (fileS < 1073741824) {
            df.format(fileS.toDouble() / 1048576) + "MB"
        } else {
            df.format(fileS.toDouble() / 1073741824) + "GB"
        }
        return fileSizeString
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

    fun getFileSize(path: String): Long {
        val file = File(path)
        if (file.exists()) {
            return file.length()
        }
        return 0
    }

    fun saveBitmap(path: String?, b: Bitmap): Boolean {
        try {
            makeDirs(path)
            val fout = FileOutputStream(path)
            val bos = BufferedOutputStream(fout)
            b.compress(Bitmap.CompressFormat.JPEG, 100, bos)
            bos.flush()
            bos.close()
            return true
        } catch (e: IOException) {
            e.printStackTrace()
            return false
        }
    }

    fun isFileExists(path: String): Boolean {
        try {
            val file = File(path)
            return file.exists() && file.isFile
        } catch (e: Exception) {
            return false
        }
    }

    fun isDirExists(path: String): Boolean {
        try {
            val file = File(path)
            return file.exists() && file.isDirectory
        } catch (e: Exception) {
            return false
        }
    }

    fun makeDirs(path: String?) {
        if (path.isNullOrEmpty()) return
        val file = File(path)
        file.parentFile?.mkdirs()
    }

}

package io.trtc.tuikit.atomicx.albumpicker.viewmodels

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import io.trtc.tuikit.atomicx.albumpicker.model.BaseBean
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class AlbumMediaLoader(private val context: Context) {
    private val imageUri: Uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
    private val videoUri: Uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
    private val imageProjections = arrayOf(
        MediaStore.Images.ImageColumns._ID,
        MediaStore.Images.ImageColumns.DATE_ADDED, MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME
    )

    private val videoProjections = arrayOf(
        MediaStore.Video.VideoColumns._ID, MediaStore.Video.VideoColumns.DATE_ADDED,
        MediaStore.Video.VideoColumns.BUCKET_DISPLAY_NAME, MediaStore.Video.VideoColumns.DURATION
    )


    suspend fun loadAllImage(): List<BaseBean>? {
        return loadImage(-1)
    }

    suspend fun loadAllVideo(): List<BaseBean>? {
        return loadVideo(-1)
    }

    suspend fun loadImage(count: Int): List<BaseBean>? = withContext(Dispatchers.Default) {
        try {
            val cursor = loadImage(count, 0) ?: return@withContext null
            val baseBeans = ImageVideoBeanParser.parse(cursor, false)
            cursor.close()
            return@withContext baseBeans
        } catch (e: Exception) {
            e.printStackTrace()
            return@withContext null
        }
    }

    suspend fun loadVideo(count: Int): List<BaseBean>? = withContext(Dispatchers.Default) {
        try {
            val cursor = loadVideo(count, 0) ?: return@withContext null
            val baseBeans = ImageVideoBeanParser.parse(cursor, true)
            cursor.close()
            return@withContext baseBeans
        } catch (e: Exception) {
            e.printStackTrace()
            return@withContext null
        }
    }

    private suspend fun loadImage(count: Int, nextPage: Int): Cursor? = withContext(Dispatchers.IO) {
        val contentResolver = context.contentResolver
        val cursor: Cursor?
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val queryArgs = Bundle()
            queryArgs.putInt(ContentResolver.QUERY_ARG_SORT_DIRECTION, ContentResolver.QUERY_SORT_DIRECTION_DESCENDING)
            if (count > 0) {
                val offset = nextPage * count
                queryArgs.putInt(ContentResolver.QUERY_ARG_LIMIT, count)
                queryArgs.putInt(ContentResolver.QUERY_ARG_OFFSET, offset)
            }
            queryArgs.putStringArray(
                ContentResolver.QUERY_ARG_SORT_COLUMNS, arrayOf(MediaStore.Images.Media.DATE_MODIFIED)
            )
            cursor = contentResolver.query(imageUri, imageProjections, queryArgs, null)
        } else {
            val sortOrder =
                MediaStore.Images.Media.DATE_MODIFIED + " DESC limit " + count + " offset " + nextPage * count
            cursor = contentResolver.query(imageUri, imageProjections, null, null, sortOrder)
        }
        return@withContext cursor
    }

    private suspend fun loadVideo(count: Int, nextPage: Int): Cursor? = withContext(Dispatchers.IO) {
        val contentResolver = context.contentResolver
        val cursor: Cursor?
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val queryArgs = Bundle()
            queryArgs.putInt(ContentResolver.QUERY_ARG_SORT_DIRECTION, ContentResolver.QUERY_SORT_DIRECTION_DESCENDING)
            if (count > 0) {
                val offset = nextPage * count
                queryArgs.putInt(ContentResolver.QUERY_ARG_LIMIT, count)
                queryArgs.putInt(ContentResolver.QUERY_ARG_OFFSET, offset)
            }
            queryArgs.putStringArray(
                ContentResolver.QUERY_ARG_SORT_COLUMNS, arrayOf(MediaStore.Images.Media.DATE_MODIFIED)
            )
            cursor = contentResolver.query(videoUri, videoProjections, queryArgs, null)
        } else {
            val sortOrder =
                MediaStore.Video.Media.DATE_MODIFIED + " DESC limit " + count + " offset " + nextPage * count
            cursor = contentResolver.query(videoUri, videoProjections, null, null, sortOrder)
        }
        return@withContext cursor
    }

    companion object {
        private const val TAG = "MediaLoader"
    }
}

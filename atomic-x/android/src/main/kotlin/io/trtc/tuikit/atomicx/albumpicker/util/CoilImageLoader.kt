package io.trtc.tuikit.atomicx.albumpicker.util

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import coil3.ImageLoader
import coil3.asImage
import coil3.decode.DataSource
import coil3.fetch.FetchResult
import coil3.fetch.Fetcher
import coil3.fetch.ImageFetchResult
import coil3.request.Options
import io.trtc.tuikit.atomicx.albumpicker.model.BaseBean
import io.trtc.tuikit.atomicx.albumpicker.model.ImageBean
import io.trtc.tuikit.atomicx.albumpicker.model.VideoBean
import java.io.IOException

class BaseBeanFetcher(
    private val context: Context,
    private val baseBean: BaseBean,
    private val options: Options
) : Fetcher {

    override suspend fun fetch(): FetchResult {
        if (baseBean.editedUri != null) {
            try {
                return when (baseBean) {
                    is ImageBean -> loadImageThumbnail(baseBean)
                    is VideoBean -> loadVideoThumbnail(baseBean)
                    else -> throw UnsupportedOperationException("unsupported BaseBean type")
                }
            } catch (e: Exception) {
                Log.e(TAG, "load bean failed", e)
                throw e
            }
        }

        return when (baseBean) {
            is ImageBean -> loadImageThumbnail(baseBean)
            is VideoBean -> loadVideoThumbnail(baseBean)
            else -> throw UnsupportedOperationException("unsupported BaseBean type")
        }
    }

    private suspend fun loadImageThumbnail(imageBean: ImageBean): FetchResult {
        val uri = imageBean.editedUri ?: imageBean.uri
        ?: throw IOException("ImageBean's URI is empty")

        var bitmap: Bitmap? = null
        val contentResolver = context.contentResolver

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val size = Size(THUMB_SIZE, THUMB_SIZE)
                bitmap = contentResolver.loadThumbnail(uri, size, null)
            } catch (e: IOException) {
                Log.e(TAG, "load thumbnail failed", e)
                throw e
            }
        } else {
            bitmap = MediaStore.Images.Thumbnails.getThumbnail(
                contentResolver,
                imageBean.id.toLong(), MediaStore.Images.Thumbnails.MINI_KIND, null
            )
        }

        if (bitmap == null) {
            throw IOException("load thumbnail failed, bitmap is null")
        }

        return ImageFetchResult(bitmap.asImage(), true, DataSource.DISK)
    }

    private suspend fun loadVideoThumbnail(videoBean: VideoBean): FetchResult {
        val uri = videoBean.editedUri ?: videoBean.uri
        ?: throw IOException("VideoBean's URI is empty")

        var bitmap: Bitmap? = null
        val contentResolver = context.contentResolver

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val size = Size(THUMB_SIZE, THUMB_SIZE)
                bitmap = contentResolver.loadThumbnail(uri, size, null)
            } catch (e: IOException) {
                Log.e(TAG, "load thumbnail failed ,try MediaMetadataRetriever", e)
            }
        } else {
            bitmap = MediaStore.Video.Thumbnails.getThumbnail(
                contentResolver,
                videoBean.id.toLong(), MediaStore.Video.Thumbnails.MINI_KIND, null
            )
        }

        if (bitmap == null) {
            try {
                val retriever = MediaMetadataRetriever()
                retriever.setDataSource(context, uri)
                bitmap = retriever.frameAtTime
                retriever.release()
            } catch (e: Exception) {
                Log.e(TAG, "load thumbnail failed", e)
                throw e
            }
        }

        if (bitmap == null) {
            throw IOException("load thumbnail failed, bitmap is null")
        }

        return ImageFetchResult(bitmap.asImage(), true, DataSource.DISK)
    }

    companion object {
        private const val TAG = "BaseBeanFetcher"
        private const val THUMB_SIZE = 512
    }

    class Factory : Fetcher.Factory<BaseBean> {
        override fun create(data: BaseBean, options: Options, imageLoader: ImageLoader): Fetcher? {
            return BaseBeanFetcher(options.context, data, options)
        }
    }
}

fun createImageLoader(context: Context): ImageLoader {
    return ImageLoader.Builder(context)
        .components {
            add(BaseBeanFetcher.Factory())
        }
        .build()
}

object CoilImageLoader {
    private var instance: ImageLoader? = null

    fun getInstance(context: Context): ImageLoader {
        if (instance == null) {
            instance = createImageLoader(context)
        }
        return instance!!
    }
}

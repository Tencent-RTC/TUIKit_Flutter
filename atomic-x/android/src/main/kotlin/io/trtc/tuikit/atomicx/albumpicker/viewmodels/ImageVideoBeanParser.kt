package io.trtc.tuikit.atomicx.albumpicker.viewmodels

import android.database.Cursor
import android.net.Uri
import android.provider.MediaStore
import io.trtc.tuikit.atomicx.albumpicker.model.BaseBean
import io.trtc.tuikit.atomicx.albumpicker.model.ImageBean
import io.trtc.tuikit.atomicx.albumpicker.model.VideoBean

object ImageVideoBeanParser {
    fun parse(cursor: Cursor?, isVideo: Boolean): List<BaseBean> {
        val baseBeans: MutableList<BaseBean> = ArrayList()
        if (cursor == null) {
            return baseBeans
        }

        while (cursor.moveToNext()) {
            val baseBean = if (isVideo) {
                parseVideo(cursor)
            } else {
                parseImage(cursor)
            }
            baseBeans.add(baseBean)
        }
        return baseBeans
    }

    private fun parseImage(cursor: Cursor): ImageBean {
        val imageBean = ImageBean()
        val dateAddTimeIndex = cursor.getColumnIndex(MediaStore.Images.ImageColumns.DATE_ADDED)
        val bucketDisplayNameIndex = cursor.getColumnIndex(MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME)
        val idIndex = cursor.getColumnIndex(MediaStore.Images.ImageColumns._ID)
        if (bucketDisplayNameIndex != -1) {
            imageBean.bucketName = cursor.getString(bucketDisplayNameIndex) ?: "0"
        }
        if (dateAddTimeIndex != -1) {
            imageBean.addTime = cursor.getLong(dateAddTimeIndex)
        }

        if (idIndex != -1) {
            imageBean.id = cursor.getInt(idIndex)
            imageBean.uri = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, imageBean.id.toString())
        }
        return imageBean
    }

    private fun parseVideo(cursor: Cursor): VideoBean {
        val videoBean = VideoBean()
        val dataIndex = cursor.getColumnIndex(MediaStore.Video.VideoColumns.DATA)
        val dateAddIndex = cursor.getColumnIndex(MediaStore.Video.VideoColumns.DATE_ADDED)
        val bucketDisplayNameIndex = cursor.getColumnIndex(MediaStore.Video.VideoColumns.BUCKET_DISPLAY_NAME)
        val ownPackageNameIndex = cursor.getColumnIndex(MediaStore.Video.VideoColumns.OWNER_PACKAGE_NAME)
        val durationIndex = cursor.getColumnIndex(MediaStore.Video.VideoColumns.DURATION)
        val idIndex = cursor.getColumnIndex(MediaStore.Video.VideoColumns._ID)
        if (dataIndex != -1) {
            videoBean.path = cursor.getString(dataIndex)
        }
        if (bucketDisplayNameIndex != -1) {
            videoBean.bucketName = cursor.getString(bucketDisplayNameIndex) ?: "0"
        }
        if (dateAddIndex != -1) {
            videoBean.addTime = cursor.getLong(dateAddIndex)
        }
        if (ownPackageNameIndex != -1) {
            videoBean.ownPackageName = cursor.getString(ownPackageNameIndex)
        }
        if (idIndex != -1) {
            videoBean.id = cursor.getInt(idIndex)
            videoBean.uri = Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, videoBean.id.toString())
        }
        if (durationIndex != -1) {
            videoBean.duration = cursor.getInt(durationIndex)
        }
        return videoBean
    }
}

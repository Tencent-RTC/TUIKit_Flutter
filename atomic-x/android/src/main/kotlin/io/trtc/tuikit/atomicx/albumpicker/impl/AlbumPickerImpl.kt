package io.trtc.tuikit.atomicx.albumpicker.impl

import android.content.Intent
import android.net.Uri
import android.text.TextUtils
import android.webkit.MimeTypeMap
import com.tencent.qcloud.tuicore.TUICore
import com.tencent.qcloud.tuicore.interfaces.ITUINotification
import io.trtc.tuikit.atomicx.albumpicker.AbstractAlbumPicker
import io.trtc.tuikit.atomicx.albumpicker.AlbumPickerModel
import io.trtc.tuikit.atomicx.albumpicker.AlbumPickerConfig
import io.trtc.tuikit.atomicx.albumpicker.PickMediaType
import io.trtc.tuikit.atomicx.albumpicker.interfaces.AlbumPickerListener
import io.trtc.tuikit.atomicx.albumpicker.ui.picker.AlbumPickerActivity
import io.trtc.tuikit.atomicx.albumpicker.util.AlbumPickerUtil
import io.trtc.tuikit.atomicx.basecomponent.utils.ContextProvider
import io.trtc.tuikit.atomicx.messageinput.utils.FileUtils
import java.util.UUID

class AlbumPickerImpl : AbstractAlbumPicker {
    companion object {
        const val TAG = "TUIMultimediaAlbumPicker"
    }

    override fun pickMedia(config: AlbumPickerConfig, listener: AlbumPickerListener) {
        val random = UUID.randomUUID().toString()
        val eventKey = "TUIMultimediaAlbumPickerEvent$random"
        val eventSubKey = "SubKeyOnPicked$random"
        lateinit var notificationListener: ITUINotification
        notificationListener = ITUINotification { key, subKey, param ->
            TUICore.unRegisterEvent(notificationListener)
            if (param == null) {
                listener.onFinishedSelect(0)
                return@ITUINotification
            }
            val dataList: ArrayList<*>? = param.get("data") as? ArrayList<*>
            if (dataList.isNullOrEmpty()) {
                listener.onFinishedSelect(0)
                return@ITUINotification
            }
            listener.onFinishedSelect(dataList.size)
            val context = ContextProvider.appContext
            dataList.forEachIndexed { index, any ->
                val uri = any as? Uri ?: return@forEachIndexed
                val path = uri.toString()
                var mediaType = getPickMediaType(uri)
                val thumbPath = if (mediaType == PickMediaType.VIDEO) {
                    AlbumPickerUtil.ensureVideoThumbnailPath(context, uri)
                } else null
                val model = AlbumPickerModel(
                    id = AlbumPickerUtil.generateId(path),
                    mediaPath = path,
                    mediaType = mediaType,
                    videoThumbnailPath = thumbPath,
                    isOrigin = true
                )
                listener.onProgress(model, index, 1.0)
            }
        }
        TUICore.registerEvent(eventKey, eventSubKey, notificationListener)
        val context = ContextProvider.appContext
        val intent = Intent(context, AlbumPickerActivity::class.java)
        intent.putExtra("eventKey", eventKey)
        intent.putExtra("eventSubKey", eventSubKey)
        intent.putExtra("config", config)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    private fun getPickMediaType(uri: Uri) : PickMediaType {
        val fileName: String = FileUtils.getFileName(ContextProvider.appContext, uri) ?: ""
        val fileExtension: String = FileUtils.getFileExtensionFromUrl(fileName)
        val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(fileExtension)
        val isVideo = mimeType!!.contains("video")
        if (isVideo) {
            return PickMediaType.VIDEO
        }

        if (TextUtils.equals(mimeType, "image/gif")) {
            return PickMediaType.GIF
        }

        return PickMediaType.IMAGE;
    }
}

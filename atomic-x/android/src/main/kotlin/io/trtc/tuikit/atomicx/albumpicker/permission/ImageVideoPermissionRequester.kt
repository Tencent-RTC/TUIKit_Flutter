package io.trtc.tuikit.atomicx.albumpicker.permission

import android.Manifest
import android.os.Build
import com.tencent.qcloud.tuicore.ServiceInitializer
import com.tencent.qcloud.tuicore.permission.PermissionCallback
import com.tencent.qcloud.tuicore.permission.PermissionRequester
import io.trtc.tuikit.atomicx.R
import io.trtc.tuikit.atomicx.albumpicker.util.AlbumPickerUtil

object ImageVideoPermissionRequester {
    private const val TAG = "ImageVideoPermissionReq"

    fun checkPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (PermissionRequester.newInstance(
                    Manifest.permission.READ_MEDIA_IMAGES,
                    Manifest.permission.READ_MEDIA_VIDEO
                ).has()
            ) {
                return true
            }
        }
        if (Build.VERSION.SDK_INT >= 34) {
            if (PermissionRequester.newInstance("android.permission.READ_MEDIA_VISUAL_USER_SELECTED").has()) {
                return true
            }
        }
        return PermissionRequester.newInstance(Manifest.permission.READ_EXTERNAL_STORAGE).has()
    }

    fun checkVisualPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= 34) {
            return PermissionRequester.newInstance("android.permission.READ_MEDIA_VISUAL_USER_SELECTED").has()
        }
        return false
    }

    fun requestPermissions(callback: PermissionCallback) {
        var title = ServiceInitializer.getAppContext().getString(
            R.string.album_request_permission_media_title, AlbumPickerUtil.getAppName()
        )
        var description =
            ServiceInitializer.getAppContext().getString(R.string.album_request_permission_media_reason)
        var tip = ServiceInitializer.getAppContext().getString(
            R.string.album_request_permission_media_tip, AlbumPickerUtil.getAppName()
        )

        if (Build.VERSION.SDK_INT >= 34) {
            PermissionRequester
                .newInstance(
                    "android.permission.READ_MEDIA_VISUAL_USER_SELECTED", Manifest.permission.READ_MEDIA_IMAGES,
                    Manifest.permission.READ_MEDIA_VIDEO
                )
                .title(title)
                .description(description)
                .settingsTip(tip)
                .callback(callback)
                .request()
        } else if (Build.VERSION.SDK_INT == Build.VERSION_CODES.TIRAMISU) {
            PermissionRequester.newInstance(Manifest.permission.READ_MEDIA_IMAGES, Manifest.permission.READ_MEDIA_VIDEO)
                .title(title)
                .description(description)
                .settingsTip(tip)
                .callback(callback)
                .request()
        } else {
            title = ServiceInitializer.getAppContext().getString(
                R.string.album_request_permission_storage_title, AlbumPickerUtil.getAppName()
            )
            description = ServiceInitializer.getAppContext().getString(
                R.string.album_request_permission_storage_reason
            )
            tip = ServiceInitializer.getAppContext().getString(
                R.string.album_request_permission_storage_tip, AlbumPickerUtil.getAppName()
            )
            PermissionRequester.newInstance(Manifest.permission.READ_EXTERNAL_STORAGE)
                .title(title)
                .description(description)
                .settingsTip(tip)
                .callback(callback)
                .request()
        }
    }
}

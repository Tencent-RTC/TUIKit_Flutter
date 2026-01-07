package io.trtc.tuikit.atomicx.videorecorder.utils;

import android.content.pm.ApplicationInfo;
import android.content.res.Resources;
import android.text.TextUtils;
import androidx.annotation.IntDef;
import com.tencent.qcloud.tuicore.ServiceInitializer;
import com.tencent.qcloud.tuicore.util.PermissionRequester;
import io.trtc.tuikit.atomicx.R;
import io.trtc.tuikit.atomicx.basecomponent.utils.ContextProvider;

public class VideoRecorderPermissionHelper {
    public static final int PERMISSION_MICROPHONE = 1;
    public static final int PERMISSION_CAMERA = 2;
    public static final int PERMISSION_STORAGE = 3;

    @IntDef({PERMISSION_MICROPHONE, PERMISSION_CAMERA, PERMISSION_STORAGE})
    public @interface PermissionType {}

    public static void requestPermission(@PermissionType int type, PermissionCallback callback) {
        String permission = null;
        String reason = null;
        String reasonTitle = null;
        String deniedAlert = null;
        ApplicationInfo applicationInfo = ContextProvider.getAppContext().getApplicationInfo();
        int permissionIcon = 0;
        CharSequence labelCharSequence = applicationInfo.loadLabel(ContextProvider.getAppContext().getPackageManager());
        String appName = "App";
        if (!TextUtils.isEmpty(labelCharSequence)) {
            appName = labelCharSequence.toString();
        }
        Resources resources = VideoRecorderResourceUtils.getResources();
        switch (type) {
            case PERMISSION_MICROPHONE: {
                permission = PermissionRequester.PermissionConstants.MICROPHONE;
                reasonTitle = resources.getString(R.string.video_recorder_permission_mic_reason_title, appName);
                reason = resources.getString(R.string.video_recorder_permission_mic_reason);
                deniedAlert = resources.getString(R.string.video_recorder_permission_mic_dialog_alert, appName);
                permissionIcon = R.drawable.video_recorder_permission_icon_mic;
                break;
            }
            case PERMISSION_CAMERA: {
                permission = PermissionRequester.PermissionConstants.CAMERA;
                reasonTitle = resources.getString(R.string.video_recorder_permission_camera_reason_title, appName);
                reason = resources.getString(R.string.video_recorder_permission_camera_reason);
                deniedAlert = resources.getString(R.string.video_recorder_permission_camera_dialog_alert, appName);
                permissionIcon = R.drawable.video_recorder_permission_icon_camera;
                break;
            }
            case PERMISSION_STORAGE: {
                permission = PermissionRequester.PermissionConstants.STORAGE;
                reasonTitle = resources.getString(R.string.video_recorder_permission_storage_reason_title, appName);
                reason = resources.getString(R.string.video_recorder_permission_storage_reason);
                deniedAlert = resources.getString(R.string.video_recorder_permission_storage_dialog_alert, appName);
                permissionIcon = R.drawable.vide_recorder_permission_icon_file;
                break;
            }
            default:
                break;
        }
        PermissionRequester.SimpleCallback simpleCallback = new PermissionRequester.SimpleCallback() {
            @Override
            public void onGranted() {
                if (callback != null) {
                    callback.onGranted();
                }
            }

            @Override
            public void onDenied() {
                if (callback != null) {
                    callback.onDenied();
                }
            }
        };
        if (!TextUtils.isEmpty(permission)) {
            PermissionRequester.permission(permission)
                .reason(reason)
                .reasonTitle(reasonTitle)
                .reasonIcon(permissionIcon)
                .deniedAlert(deniedAlert)
                .callback(simpleCallback)
                .request();
        }
    }

    public interface PermissionCallback {
        void onGranted();

        void onDenied();
    }
}

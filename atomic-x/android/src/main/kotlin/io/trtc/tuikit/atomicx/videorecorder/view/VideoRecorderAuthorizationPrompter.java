package io.trtc.tuikit.atomicx.videorecorder.view;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.TextView;
import androidx.appcompat.app.AlertDialog;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import io.trtc.tuikit.atomicx.R;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderResourceUtils;
import java.util.Objects;

public class VideoRecorderAuthorizationPrompter {

    private static boolean isAppDebuggable(Context context) {
        return (context.getApplicationInfo().flags & android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0;
    }

    public enum PrompterType {
        NO_SIGNATURE,
        NO_LITEAV_SDK
    }

    public static void showPermissionPrompterDialog(Context context, PrompterType prompterType) {
        if (!isAppDebuggable(context)) {
            return;
        }

        View dialogView = LayoutInflater.from(context).inflate(R.layout.video_recorder_authorization_prompter, null);
        TextView prompterTv = dialogView.findViewById(R.id.video_recorder_authorization_prompter_tv);

        if (prompterType == PrompterType.NO_SIGNATURE) {
            prompterTv.setText(R.string.authorization_prompter_no_signature);
        } else {
            prompterTv.setText(R.string.authorization_prompter_no_liteav_sdk);
        }

        MaterialAlertDialogBuilder builder = new MaterialAlertDialogBuilder(context, R.style.AuthorizationPrompterDialog)
                .setView(dialogView)
                .setPositiveButton(VideoRecorderResourceUtils.getString(R.string.video_recorder_confirm), null)
                .setOnDismissListener(dialog -> {
                });

        AlertDialog dialog = builder.create();

        Window window = dialog.getWindow();
        if (window != null) {
            WindowManager.LayoutParams params = window.getAttributes();
            params.width = WindowManager.LayoutParams.WRAP_CONTENT;
            params.height = WindowManager.LayoutParams.WRAP_CONTENT;
            window.setAttributes(params);
        }

        Objects.requireNonNull(dialog.getWindow())
                .setBackgroundDrawableResource(R.drawable.video_recorder_bg_dialog_rounded);

        dialog.show();

        Button positiveButton = dialog.getButton(AlertDialog.BUTTON_POSITIVE);
        if (positiveButton != null) {
            ViewGroup.MarginLayoutParams params = (ViewGroup.MarginLayoutParams) positiveButton.getLayoutParams();
            params.leftMargin = VideoRecorderResourceUtils.dip2px(context, 24);
        }
    }
}
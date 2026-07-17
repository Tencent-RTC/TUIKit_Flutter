package com.tencent.cloud.tuikit.flutter.tuilivekit.utils;

import android.app.Activity;
import android.app.PictureInPictureParams;
import android.content.ComponentName;
import android.content.Context;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;
import android.util.Rational;

import org.json.JSONException;
import org.json.JSONObject;

import io.flutter.plugin.common.EventChannel;

public class PictureInPictureManager implements EventChannel.StreamHandler {

    private static final String TAG             = "PictureInPictureManager";
    private static final String STATE_ENTER_PIP = "state_enter_pip";
    private static final String STATE_LEAVE_PIP = "state_leave_pip";

    private static final int FLAG_SUPPORTS_PICTURE_IN_PICTURE = 0x00400000;
    private static final int CANVAS_WIDTH = 720;
    private static final int CANVAS_HEIGHT = 1280;

    private boolean                mEnablePictureInPicture = false;
    private int                    mCanvasWidth            = CANVAS_WIDTH;
    private int                    mCanvasHeight           = CANVAS_HEIGHT;
    private EventChannel.EventSink mEventSink;

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        mEventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        mEventSink = null;
    }

    public boolean enablePictureInPicture(Activity activity, String params) {
        Log.i(TAG, "enablePictureInPicture, params:" + params);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                activity.getPackageManager().hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)) {
            if (!isActivityDeclaredSupportsPip(activity)) {
                logMissingSupportsPipDeclaration(activity);
                return false;
            }
            try {
                JSONObject jsonObject = new JSONObject(params);
                JSONObject paramsJson = jsonObject.getJSONObject("params");
                mEnablePictureInPicture = paramsJson.getBoolean("enable");
                JSONObject canvasJson = paramsJson.getJSONObject("canvas");
                mCanvasWidth = canvasJson.getInt("width");
                mCanvasHeight = canvasJson.getInt("height");
                if (mCanvasWidth <= 0 || mCanvasHeight <= 0) {
                    mCanvasWidth = CANVAS_WIDTH;
                    mCanvasHeight = CANVAS_HEIGHT;
                }
                return true;
            } catch (JSONException e) {
                error(activity, e.toString());
                return false;
            }
        }
        return false;
    }

    public void enterPictureInPicture(Activity activity) {
        if (!mEnablePictureInPicture) {
            error(activity, "mEnablePictureInPicture = " + mEnablePictureInPicture);
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (!isActivityDeclaredSupportsPip(activity)) {
                logMissingSupportsPipDeclaration(activity);
                return;
            }
            Rational aspectRatio = new Rational(mCanvasWidth, mCanvasHeight);
            PictureInPictureParams params = new PictureInPictureParams.Builder().setAspectRatio(aspectRatio).build();
            try {
                boolean ok = activity.enterPictureInPictureMode(params);
                info(activity, "enterPictureInPictureMode: " + ok);
                onEnterPip(ok);
            } catch (Exception e) {
                error(activity, e.toString());
            }
        }
    }

    public boolean exitPictureInPicture(Activity activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (activity.isInPictureInPictureMode()) {
                return activity.moveTaskToBack(false);
            }
        }
        return false;
    }

    public void onLeavePip() {
        Log.i(TAG, "onLeavePip");
        if (mEventSink != null) {
            mEventSink.success(STATE_LEAVE_PIP);
        }
    }

    private void onEnterPip(boolean success) {
        Log.i(TAG, "onEnterPip:" + success);
        if (mEventSink != null) {
            if (success) {
                mEventSink.success(STATE_ENTER_PIP);
            } else {
                mEventSink.error("-1", "enter PIP failed", "");
            }
        }
    }

    /**
     * Checks whether the current Activity has declared
     * android:supportsPictureInPicture="true" in AndroidManifest.xml.
     */
    private boolean isActivityDeclaredSupportsPip(Activity activity) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return false;
        }
        try {
            ComponentName componentName = activity.getComponentName();
            ActivityInfo activityInfo = activity.getPackageManager().getActivityInfo(componentName, 0);
            return (activityInfo.flags & FLAG_SUPPORTS_PICTURE_IN_PICTURE) != 0;
        } catch (PackageManager.NameNotFoundException e) {
            error(activity, "isActivityDeclaredSupportsPip, getActivityInfo failed: " + e.getMessage());
            return false;
        }
    }

    private void logMissingSupportsPipDeclaration(Activity activity) {
        String message = "This Activity is missing `android:supportsPictureInPicture=\"true\"` in AndroidManifest.xml";
        error(activity, message);
    }

    private void error(Context context, String message) {
        LiveKitLog.error(context, "", TAG, 0, message);
    }

    private void info(Context context, String message) {
        LiveKitLog.info(context, "", TAG, 0, message);
    }
}
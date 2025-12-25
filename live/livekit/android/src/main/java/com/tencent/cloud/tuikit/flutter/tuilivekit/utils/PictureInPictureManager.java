package com.tencent.cloud.tuikit.flutter.tuilivekit.utils;

import android.app.Activity;
import android.app.PictureInPictureParams;
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

    private boolean                mEnablePictureInPicture = false;
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
            try {
                JSONObject jsonObject = new JSONObject(params);
                JSONObject paramsJson = jsonObject.getJSONObject("params");
                mEnablePictureInPicture = paramsJson.getBoolean("enable");
                return true;
            } catch (JSONException e) {
                return false;
            }
        }
        return false;
    }

    public void enterPictureInPicture(Activity activity) {
        if (!mEnablePictureInPicture) {
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Rational aspectRatio = new Rational(9, 16);
            PictureInPictureParams params = new PictureInPictureParams.Builder().setAspectRatio(aspectRatio).build();
            try {
                boolean ok = activity.enterPictureInPictureMode(params);
                onEnterPip(ok);
            } catch (Exception e) {
                Log.e(TAG, e.toString());
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
}
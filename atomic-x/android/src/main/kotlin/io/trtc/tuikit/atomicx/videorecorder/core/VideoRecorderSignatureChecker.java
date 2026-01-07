package io.trtc.tuikit.atomicx.videorecorder.core;

import android.content.Context;
import android.os.Handler;
import android.util.Log;

import com.tencent.qcloud.tuicore.ServiceInitializer;

import org.json.JSONObject;

import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.HashMap;

// import io.trtc.tuikit.atomicxcore.api.login.LoginStore;

public class VideoRecorderSignatureChecker {
    private static final String TAG = "VideoRecorderSignature";

    private static final String KEY_APP_ID = "appid";
    private static final String KEY_SIGNATURE = "signature";
    private static final int SCHEDULE_UPDATE_SIGNATURE_INTERVAL_WHEN_FAIL = 1000;
    private static final int GET_SIGNATURE_RETRY_TIMES = 3;
    private static final int ERR_SDK_INTERFACE_NOT_SUPPORT = 7013;
    private static final int ERR_SDK_NOT_INITIALIZED = 6013;
    private final Handler handler = new Handler();
    private V2TIMManagerReflectCallExperimentalAPI mV2TIMManagerReflectCall;
    private String mSignature = "";
    private int mExpiredTime = 0;
    private int mRetryCount = 0;
    private ResultCode mResultCode = ResultCode.ERROR_NO_SIGNATURE;

    public static VideoRecorderSignatureChecker getInstance() {
        return VideoRecorderSignatureManagerHolder.sSignatureChecker;
    }

    public void startUpdateSignature() {
        if (!CreateV2TIMManagerReflectCall()) {
            Log.e(TAG, "mV2TIMManagerReflectCall init fail.because of has no im sdk");
            mResultCode = ResultCode.ERROR_NO_IM_SDK;
            return;
        }
        updateSignatureDelay(0);
    }

    public ResultCode getSetSignatureResult() {
        return mResultCode;
    }

    private void updateSignature() {
        long currentTime = System.currentTimeMillis() / 1000;
        if (currentTime < mExpiredTime) {
            mResultCode = ResultCode.ERROR_NO_SIGNATURE;
            updateSignatureDelay((mExpiredTime - currentTime) * 1000);
            return;
        }

        Log.i(TAG, "updateSignature");
        if (!mV2TIMManagerReflectCall.callExperimentalAPI("getVideoEditSignature")) {
            mResultCode = ResultCode.ERROR_NO_IM_SDK;
            Log.e(TAG,
                "mV2TIMManagerReflectCall callExperimentalAPIMethod getVideoEditSignature "
                    + "fail.because of has no im sdk");
        }
    }

    private void onGetVideoEditSignatureSuccess(Object object) {
        Log.i(TAG, "onSuccess, object:" + object);
        if (object == null) {
            return;
        }

        if (!(object instanceof HashMap)) {
            return;
        }
        mRetryCount = 0;
        HashMap<String, String> hashMap = (HashMap<String, String>) object;
        mSignature = hashMap.get("signature");
        String expiredTime = hashMap.get("expired_time");
        if (expiredTime != null) {
            mExpiredTime = Integer.parseInt(expiredTime);
        }
        Log.i(TAG, "getVideoEditSignature. signature = " + mSignature + " expiredTime = " + mExpiredTime);

        setSignature(ServiceInitializer.getAppContext());
        updateSignatureDelay(mExpiredTime * 1000L - System.currentTimeMillis());
    }

    private void onGetVideoEditSignatureError(int code, String desc) {
        Log.e(TAG, "getVideoEditSignature error, code:" + code + ", desc:" + desc);

        if (code == ERR_SDK_INTERFACE_NOT_SUPPORT) {
            handler.removeCallbacksAndMessages(null);
            return;
        }

        if (code == ERR_SDK_NOT_INITIALIZED) {
            mRetryCount = 0;
        }

        if (mRetryCount++ > GET_SIGNATURE_RETRY_TIMES) {
            Log.e(TAG, "The maximum number of attempts to retry obtaining signatures has been reached");
            mRetryCount = 0;
        } else {
            updateSignatureDelay(SCHEDULE_UPDATE_SIGNATURE_INTERVAL_WHEN_FAIL);
        }
    }

    private boolean CreateV2TIMManagerReflectCall() {
        if (mV2TIMManagerReflectCall != null) {
            return true;
        }

        mV2TIMManagerReflectCall =
            new V2TIMManagerReflectCallExperimentalAPI(new V2TIMManagerReflectCallExperimentalAPI.Callback() {
                @Override
                public void onSuccess(Object object) {
                    onGetVideoEditSignatureSuccess(object);
                }

                @Override
                public void onError(int code, String desc) {
                    onGetVideoEditSignatureError(code, desc);
                }
            });
        boolean result = mV2TIMManagerReflectCall.init();
        if (!result) {
            mV2TIMManagerReflectCall = null;
        }
        return result;
    }

    private void setSignature(Context context) {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("api", "setSignature");
            JSONObject params = new JSONObject();
            String sdkAppID = getSdkAppID();
            if (sdkAppID.isEmpty()) {
                return;
            }
            params.put(KEY_APP_ID, sdkAppID);
            params.put(KEY_SIGNATURE, mSignature);
            jsonObject.put("params", params);
            Log.i(TAG, " jsonObject = " + jsonObject);
            if (!setSignatureToUgcSdk(context, jsonObject.toString())) {
                return;
            }
        } catch (Exception e) {
            Log.e(TAG, "set signature fail. error msg :" + e);
            return;
        }
        Log.i(TAG, "set signature success.");
        mResultCode = ResultCode.SUCCESS;
    }

    private void updateSignatureDelay(long delay) {
        handler.removeCallbacksAndMessages(null);
        handler.postDelayed(this::updateSignature, delay);
    }

    private boolean setSignatureToUgcSdk(Context context, String jsonString) {
        try {
            Class<?> txUGCBaseClass = Class.forName("com.tencent.ugc.TXUGCBase");
            Method getInstanceMethod = txUGCBaseClass.getMethod("getInstance");
            Object txUGCBaseInstance = getInstanceMethod.invoke(null);
            Method callExperimentalAPIMethod =
                txUGCBaseClass.getMethod("callExperimentalAPI", Context.class, String.class);
            callExperimentalAPIMethod.invoke(txUGCBaseInstance, context, jsonString);
            return true;
        } catch (Exception e) {
            mResultCode = ResultCode.ERROR_NO_LITEAV_SDK;
            Log.e(TAG, "set signature to ug sdk fail. error msg :" + e);
            return false;
        }
    }

    private String getSdkAppID() {
        // return LoginStore.shared.getSdkAppID() + "";
        return "";
    }

    public enum ResultCode {
        SUCCESS(0),
        ERROR_NO_LITEAV_SDK(-7),
        ERROR_NO_IM_SDK(-8),
        ERROR_TUI_CORE(-9),
        ERROR_NO_SIGNATURE(-10);

        private final int code;

        ResultCode(int code) {
            this.code = code;
        }

        public int getValue() {
            return code;
        }
    }

    private static class VideoRecorderSignatureManagerHolder {
        private static final VideoRecorderSignatureChecker sSignatureChecker = new VideoRecorderSignatureChecker();
    }

    protected static class V2TIMManagerReflectCallExperimentalAPI {
        private final Callback<Object> callback;
        private Method callExperimentalAPIMethod;
        private Object v2TIManagerInstance;
        private Object proxyCallback;

        public V2TIMManagerReflectCallExperimentalAPI(Callback<Object> callback) {
            this.callback = callback;
        }

        public boolean init() {
            try {
                Class<?> v2TIManagerClass = Class.forName("com.tencent.imsdk.v2.V2TIMManager");
                Method getInstanceMethod = v2TIManagerClass.getMethod("getInstance");
                v2TIManagerInstance = getInstanceMethod.invoke(null);

                Class<?> callbackClass = Class.forName("com.tencent.imsdk.v2.V2TIMValueCallback");
                callExperimentalAPIMethod =
                    v2TIManagerClass.getMethod("callExperimentalAPI", String.class, Object.class, callbackClass);

                proxyCallback = Proxy.newProxyInstance(
                    callbackClass.getClassLoader(), new Class<?>[] {callbackClass}, (proxy, method, args) -> {
                        String methodName = method.getName();
                        if ("onSuccess".equals(methodName)) {
                            callback.onSuccess(args[0]);
                        } else if ("onError".equals(methodName)) {
                            callback.onError((Integer) args[0], (String) args[1]);
                        }
                        return null;
                    });
            } catch (Exception e) {
                Log.i(TAG, "V2TIMManager Reflect init fail. error msg:" + e);
                return false;
            }
            return true;
        }

        public boolean callExperimentalAPI(String api) {
            try {
                callExperimentalAPIMethod.invoke(v2TIManagerInstance, api, null, proxyCallback);
            } catch (Exception e) {
                Log.i(TAG, "callExperimentalAPI " + api + "fail. error msg:" + e);
                return false;
            }
            return true;
        }

        public interface Callback<T> {
            void onSuccess(T object);
            void onError(int code, String desc);
        }
    }
}
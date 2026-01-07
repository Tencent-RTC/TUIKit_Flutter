package io.trtc.tuikit.atomicx.videorecorder.core;

import android.content.Context;
import android.graphics.Bitmap;
import android.util.Log;
import android.view.TextureView;
import java.io.FileOutputStream;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

public class UGCReflectVideoRecorderCore implements IVideoRecorderCoreInterface {
    private static final String TAG = "VideoRecorderReflector";

    private final Context mContext;
    private final Object mTXUGCVideoRecorder;

    private Object mListenerProxy;
    private Class<?> mListenerInterface;
    private IVideoRecordListener mListener;

    public static boolean isAvailable() {
        try {
            Class<?> clazz = Class.forName("com.tencent.ugc.TXUGCRecord");
        } catch (Exception e) {
            return false;
        }
        return true;
    }

    public UGCReflectVideoRecorderCore(Context context) throws Exception {
        mContext = context;
        Class<?> clazz = Class.forName("com.tencent.ugc.TXUGCRecord");
        Method getInstance = clazz.getMethod("getInstance", Context.class);
        mTXUGCVideoRecorder = getInstance.invoke(null, context.getApplicationContext());
        initReflectorListener();
    }

    @Override
    public void setVideoRecordListener(IVideoRecordListener listener) {
        mListener = listener;
        invokeClassInstanceMethod(mTXUGCVideoRecorder, "setVideoRecordListener", new Class<?>[] {mListenerInterface},
            new Object[] {mListenerProxy});
    }

    @Override
    public void startCameraCustomPreview(VideoRecordCustomConfig videoRecordCustomConfig, TextureView textureView) {
        if (textureView == null) {
            Log.i(TAG, "surfaceView view is null or surfaceView holder is null");
            return;
        }

        try {
            Class<?> configClass = Class.forName("com.tencent.ugc.TXRecordCommon$TXUGCCustomConfig");
            Object configObject = configClass.newInstance();
            fillReflectObjectWithAnalogousObject(configObject, videoRecordCustomConfig);

            Class<?> txCloudVideoViewClass = Class.forName("com.tencent.rtmp.ui.TXCloudVideoView");
            Constructor<?> txCloudconStructor = txCloudVideoViewClass.getConstructor(Context.class);
            Object txCloudInstance = txCloudconStructor.newInstance(mContext);

            invokeClassInstanceMethod(
                txCloudInstance, "addVideoView", new Class<?>[] {TextureView.class}, new Object[] {textureView});

            invokeClassInstanceMethod(mTXUGCVideoRecorder, "startCameraCustomPreview",
                new Class<?>[] {configClass, txCloudVideoViewClass}, new Object[] {configObject, txCloudInstance});
        } catch (Exception e) {
            Log.i(TAG, "Failed to start camera custom preview. error is " + e);
        }
    }

    @Override
    public void stopCameraPreview() {
        invokeClassInstanceMethod(mTXUGCVideoRecorder, "stopCameraPreview", new Class<?>[] {}, new Object[] {});
    }

    @Override
    public void deleteAllParts() {
        Object txUGCPartsManager =
            invokeClassInstanceMethod(mTXUGCVideoRecorder, "getPartsManager", new Class<?>[] {}, new Object[] {});
        invokeClassInstanceMethod(txUGCPartsManager, "deleteAllParts", new Class<?>[] {}, new Object[] {});
    }

    @Override
    public int startRecord(String videoFilePath) {
        invokeClassInstanceMethod(mTXUGCVideoRecorder, "startRecord", new Class<?>[] {String.class, String.class},
            new Object[] {videoFilePath, ""});
        return 0;
    }

    @Override
    public int stopRecord() {
        invokeClassInstanceMethod(mTXUGCVideoRecorder, "stopRecord", new Class<?>[] {}, new Object[] {});
        return 0;
    }

    @Override
    public void release() {
        invokeClassInstanceMethod(mTXUGCVideoRecorder, "release", new Class<?>[] {}, new Object[] {});
    }

    @Override
    public boolean setMicVolume(float x) {
        invokeClassInstanceMethod(mTXUGCVideoRecorder, "setMicVolume", new Class[] {float.class}, new Object[] {x});
        return true;
    }

    @Override
    public boolean switchCamera(boolean isFront) {
        invokeClassInstanceMethod(
            mTXUGCVideoRecorder, "switchCamera", new Class[] {boolean.class}, new Object[] {isFront});
        return true;
    }

    @Override
    public void setAspectRatio(int displayType) {
        invokeClassInstanceMethod(
            mTXUGCVideoRecorder, "setAspectRatio", new Class[] {int.class}, new Object[] {displayType});
    }

    @Override
    public void snapshot(ISnapshotListener listener, String path) {
        Class<?> listenerInterface;
        try {
            listenerInterface = Class.forName("com.tencent.ugc.TXRecordCommon$ITXSnapshotListener");
        } catch (ClassNotFoundException e) {
            Log.i(TAG, "snapshot fail. error : " + e);
            return;
        }

        Object listenerProxy = Proxy.newProxyInstance(
            listenerInterface.getClassLoader(), new Class[] {listenerInterface}, (proxy, method, args) -> {
                String methodName = method.getName();
                if ("onSnapshot".equals(methodName) && listener != null) {
                    listener.onSnapshotCompleted(savaBitmap((Bitmap) args[0], path));
                }
                return null;
            });

        invokeClassInstanceMethod(
            mTXUGCVideoRecorder, "snapshot", new Class<?>[] {listenerInterface}, new Object[] {listenerProxy});
    }

    @Override
    public void setFilter(
        Bitmap leftBitmap, float leftIntensity, Bitmap rightBitmap, float rightIntensity, float leftRatio) {
        invokeClassInstanceMethod(mTXUGCVideoRecorder, "setFilter",
            new Class[] {Bitmap.class, float.class, Bitmap.class, float.class, float.class},
            new Object[] {leftBitmap, leftIntensity, rightBitmap, rightIntensity, leftRatio});
    }

    @Override
    public boolean toggleTorch(boolean enable) {
        invokeClassInstanceMethod(
            mTXUGCVideoRecorder, "toggleTorch", new Class[] {boolean.class}, new Object[] {enable});
        return true;
    }

    @Override
    public int getMaxZoom() {
        Object retObject =
            invokeClassInstanceMethod(mTXUGCVideoRecorder, "getMaxZoom", new Class[] {}, new Object[] {});
        return retObject != null ? (Integer) retObject : 0;
    }

    @Override
    public boolean setZoom(int value) {
        invokeClassInstanceMethod(mTXUGCVideoRecorder, "setZoom", new Class[] {int.class}, new Object[] {value});
        return true;
    }

    @Override
    public void setFocusPosition(float eventX, float eventY) {
        invokeClassInstanceMethod(mTXUGCVideoRecorder, "setFocusPosition", new Class[] {float.class, float.class},
            new Object[] {eventX, eventY});
    }

    @Override
    public void setVideoRenderMode(int renderMode) {
        invokeClassInstanceMethod(
            mTXUGCVideoRecorder, "setVideoRenderMode", new Class[] {int.class}, new Object[] {renderMode});
    }

    @Override
    public void setHomeOrientation(int homeOrientation) {
        invokeClassInstanceMethod(
            mTXUGCVideoRecorder, "setHomeOrientation", new Class[] {int.class}, new Object[] {homeOrientation});
    }

    @Override
    public void setRenderRotation(int renderRotation) {
        invokeClassInstanceMethod(
            mTXUGCVideoRecorder, "setRenderRotation", new Class[] {int.class}, new Object[] {renderRotation});
    }

    @Override
    public IBeautyManager getBeautyManager() {
        Object TXBeautyManagerInstance =
            invokeClassInstanceMethod(mTXUGCVideoRecorder, "getBeautyManager", new Class[] {}, new Object[] {});
        return new TXBeautyManagerReflect(TXBeautyManagerInstance);
    }

    private Object invokeClassInstanceMethod(
        Object instance, String methodName, Class<?>[] parameterTypes, Object[] parameter) {
        if (instance == null) {
            Log.i(TAG, "Failed to invoke class method. because instance is null ");
            return null;
        }

        try {
            Method method = instance.getClass().getMethod(methodName, parameterTypes);
            return method.invoke(instance, parameter);
        } catch (Exception e) {
            Log.i(TAG, "Failed to invoke class method. error is " + e);
        }
        return null;
    }

    private void initReflectorListener() {
        try {
            mListenerInterface = Class.forName("com.tencent.ugc.TXRecordCommon$ITXVideoRecordListener");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(e);
        }

        mListenerProxy = Proxy.newProxyInstance(
            mListenerInterface.getClassLoader(), new Class[] {mListenerInterface}, (proxy, method, args) -> {
                String methodName = method.getName();
                if ("onRecordProgress".equals(methodName) && mListener != null) {
                    mListener.onRecordProgress((Long) args[0]);
                } else if ("onRecordComplete".equals(methodName) && mListener != null) {
                    mListener.onRecordComplete(parseRecordResult(args[0]));
                }
                return null;
            });
    }

    private void setField(Class<?> clazz, Object target, String fieldName, Object value) throws Exception {
        Method setter = findSetter(clazz, fieldName);
        if (setter != null) {
            setter.invoke(target, value);
        } else {
            Field field = clazz.getField(fieldName);
            field.set(target, value);
        }
    }

    private Method findSetter(Class<?> clazz, String fieldName) {
        String setterName = "set" + Character.toUpperCase(fieldName.charAt(0)) + fieldName.substring(1);
        for (Method method : clazz.getMethods()) {
            if (method.getName().equals(setterName) && method.getParameterTypes().length == 1) {
                return method;
            }
        }
        return null;
    }

    private void fillReflectObjectWithAnalogousObject(Object reflectObject, Object analogousObject) throws Exception {
        Class<?> configClass = reflectObject.getClass();
        Class<?> videoRecordCustomConfigClass = analogousObject.getClass();
        Field[] fields = videoRecordCustomConfigClass.getDeclaredFields();

        for (Field field : fields) {
            setField(configClass, reflectObject, field.getName(), field.get(analogousObject));
        }
    }

    private VideoRecordResult parseRecordResult(Object resultObj) throws Exception {
        VideoRecordResult result = new VideoRecordResult();
        Class<?> resultClass = Class.forName("com.tencent.ugc.TXRecordCommon$TXRecordResult");

        Field retCodeField = resultClass.getField("retCode");
        result.retCode = retCodeField.getInt(resultObj);

        Field descMsgField = resultClass.getField("descMsg");
        result.descMsg = (String) descMsgField.get(resultObj);

        Field videoPathField = resultClass.getField("videoPath");
        result.videoPath = (String) videoPathField.get(resultObj);
        return result;
    }

    private boolean savaBitmap(Bitmap bitmap, String path) {
        if (bitmap == null) {
            return false;
        }

        FileOutputStream outputStream = null;
        try {
            outputStream = new FileOutputStream(path);
            bitmap.compress(Bitmap.CompressFormat.JPEG, 90, outputStream);
        } catch (Throwable e) {
            Log.e(TAG, "save bitmap fail,%s", e);
            return false;
        } finally {
            if (outputStream != null) {
                try {
                    outputStream.close();
                } catch (Exception e) {
                    Log.e(TAG, "close bitmap file fail,%s", e);
                }
            }
        }
        return true;
    }

    public class TXBeautyManagerReflect implements IBeautyManager {
        Object mBeautyManagerInstance;
        public TXBeautyManagerReflect(Object beautyManagerInstance) {
            mBeautyManagerInstance = beautyManagerInstance;
        }

        @Override
        public void setBeautyStyle(int beautyStyle) {
            invokeClassInstanceMethod(
                mBeautyManagerInstance, "setBeautyStyle", new Class<?>[] {int.class}, new Object[] {beautyStyle});
        }

        @Override
        public void setBeautyLevel(float beautyLevel) {
            invokeClassInstanceMethod(
                mBeautyManagerInstance, "setBeautyLevel", new Class<?>[] {float.class}, new Object[] {beautyLevel});
        }

        @Override
        public void setWhitenessLevel(float whitenessLevel) {
            invokeClassInstanceMethod(mBeautyManagerInstance, "setWhitenessLevel", new Class<?>[] {float.class},
                new Object[] {whitenessLevel});
        }

        @Override
        public void setFilterStrength(float strength) {
            invokeClassInstanceMethod(
                mBeautyManagerInstance, "setFilterStrength", new Class<?>[] {float.class}, new Object[] {strength});
        }

        @Override
        public void setRuddyLevel(float ruddyLevel) {
            invokeClassInstanceMethod(
                mBeautyManagerInstance, "setRuddyLevel", new Class<?>[] {float.class}, new Object[] {ruddyLevel});
        }

        @Override
        public void setFilter(Bitmap image) {
            invokeClassInstanceMethod(
                mBeautyManagerInstance, "setFilter", new Class<?>[] {Bitmap.class}, new Object[] {image});
        }
    }
}

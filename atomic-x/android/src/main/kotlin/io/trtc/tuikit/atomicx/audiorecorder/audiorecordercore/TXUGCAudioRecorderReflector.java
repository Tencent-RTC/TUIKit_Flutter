package io.trtc.tuikit.atomicx.audiorecorder.audiorecordercore;

import android.content.Context;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

public class TXUGCAudioRecorderReflector {
    private Object mTXUGCAudioRecorder;
    private Object mListenerProxy;
    private Class<?> mListenerInterface;
    private TXUGCAudioRecorderReflectorListener mReflectorListener;

    interface TXUGCAudioRecorderReflectorListener {
        void onProgress(long milliSecond);
        void onComplete(RecordResult result);
    }

    public void init(Context context) throws Exception {
        Class<?> clazz = Class.forName("com.tencent.ugc.TXUGCAudioRecorder");
        Method getInstance = clazz.getMethod("getInstance", Context.class);
        mTXUGCAudioRecorder = getInstance.invoke(null, context.getApplicationContext());
        initReflectorListener();
    }

    private void initReflectorListener() {
        try {
            mListenerInterface = Class.forName(
                    "com.tencent.ugc.TXUGCAudioRecorder$ITXAudioRecorderListener");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(e);
        }

        mListenerProxy = Proxy.newProxyInstance(
                mListenerInterface.getClassLoader(),
                new Class[]{mListenerInterface},
                (proxy, method, args) -> {
                    String methodName = method.getName();
                    if ("onRecordProgress".equals(methodName) && mReflectorListener != null) {
                        mReflectorListener.onProgress((Long) args[0]);
                    } else if ("onRecordComplete".equals(methodName) && mReflectorListener != null) {
                        mReflectorListener.onComplete(parseRecordResult(args[0]));
                    }
                    return null;
                }
        );
    }

    public void setListener(TXUGCAudioRecorderReflectorListener listener) {
        mReflectorListener = listener;

        try {
            Method setRecordListener = mTXUGCAudioRecorder.getClass().getMethod("setAudioRecordListener",
                    mListenerInterface);
            setRecordListener.invoke(mTXUGCAudioRecorder, mListenerProxy);
        } catch (Exception e) {
            throw new RuntimeException("Failed to set audio recorder listener", e);
        }
    }

    public int startRecord(String outputPath, AudioConfig config) {
        try {
            Class<?> configClass = Class.forName("com.tencent.ugc.TXRecordCommon$TXUGCAudioConfig");
            Object audioConfig = configClass.newInstance();

            setField(configClass, audioConfig, "minDurationMs", config.minDuration);
            setField(configClass, audioConfig, "maxDurationMs", config.maxDuration);
            setField(configClass, audioConfig, "sampleRate", config.sampleRate);
            setField(configClass, audioConfig, "bitrateBps", config.bitrateBps);
            setField(configClass, audioConfig, "channel", config.channel);
            setField(configClass, audioConfig, "enableAIDeNoise", config.enableAIDeNoise);

            Method startRecord = mTXUGCAudioRecorder.getClass().getMethod("startRecord", String.class, configClass);
            return (int) startRecord.invoke(mTXUGCAudioRecorder, outputPath, audioConfig);
        } catch (Exception e) {
            throw new RuntimeException("Failed to start recording", e);
        }
    }

    public void stopRecord() {
        try {
            Method stopRecord = mTXUGCAudioRecorder.getClass().getMethod("stopRecord");
            stopRecord.invoke(mTXUGCAudioRecorder);
        } catch (Exception e) {
            throw new RuntimeException("Failed to stop recording", e);
        }
    }

    private void setField(Class<?> clazz, Object target, String fieldName, Object value) throws Exception {
        Method setter = findSetter(clazz, fieldName);
        if (setter != null) {
            setter.invoke(target, value);
        } else {
            java.lang.reflect.Field field = clazz.getField(fieldName);
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

    private RecordResult parseRecordResult(Object resultObj) throws Exception {
        RecordResult result = new RecordResult();
        Class<?> resultClass = Class.forName("com.tencent.ugc.TXRecordCommon$TXRecordResult");

        java.lang.reflect.Field retCodeField = resultClass.getField("retCode");
        result.retCode = retCodeField.getInt(resultObj);

        java.lang.reflect.Field descMsgField = resultClass.getField("descMsg");
        result.descMsg = (String) descMsgField.get(resultObj);

        java.lang.reflect.Field videoPathField = resultClass.getField("videoPath");
        result.videoPath = (String) videoPathField.get(resultObj);

        return result;
    }

    public static class AudioConfig {
        public int minDuration = 1000;
        public int maxDuration = 300000;
        public int sampleRate = 48000;
        public int bitrateBps = 50 * 1024;
        public int channel = 1;
        public boolean enableAIDeNoise = false;
    }

    public static class RecordResult {
        public int retCode;
        public String descMsg;
        public String videoPath;
    }
}
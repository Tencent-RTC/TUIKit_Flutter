package io.trtc.tuikit.atomicx.videorecorder.core;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.TextureView;
import io.trtc.tuikit.atomicx.videorecorder.VideoQuality;
import io.trtc.tuikit.atomicx.videorecorder.config.VideoRecorderConstants;
import io.trtc.tuikit.atomicx.videorecorder.core.IVideoRecorderCoreInterface.IBeautyManager;
import io.trtc.tuikit.atomicx.videorecorder.core.IVideoRecorderCoreInterface.IVideoRecordListener;
import io.trtc.tuikit.atomicx.videorecorder.core.IVideoRecorderCoreInterface.VideoRecordResult;
import io.trtc.tuikit.atomicx.videorecorder.core.IVideoRecorderCoreInterface.VideoRecordCustomConfig;
import io.trtc.tuikit.atomicx.videorecorder.core.VideoRecorderSignatureChecker.ResultCode;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.RecordInfo;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.RecordInfo.RecordStatus;

public class VideoRecorderRecordCore {
    private final static float DEFAULT_VOLUME = 0.5f;
    private final static int DEFAULT_VIDEO_GOP = 3;
    private final static int LOW_QUALITY_BITRATE = 1000;
    private final static int MEDIUM_QUALITY_BITRATE = 3000;
    private final static int HIGH_QUALITY_BITRATE = 5000;
    private final static int EDIT_BITRATE = 12000;
    private final static int LOW_QUALITY_FPS = 25;
    private final static int MEDIUM_QUALITY_FPS = 25;
    private final static int HIGH_QUALITY_FPS = 30;
    private final static int LOW_QUALITY_RESOLUTION = VideoRecordCoreConstant.VIDEO_RESOLUTION_720_1280;
    private final static int MEDIUM_QUALITY_RESOLUTION = VideoRecordCoreConstant.VIDEO_RESOLUTION_720_1280;
    private final static int HIGH_QUALITY_RESOLUTION = VideoRecordCoreConstant.VIDEO_RESOLUTION_1080_1920;
    private final static int DEFAULT_MAX_RECORD_DURATION_MS = 15000;
    private final static int DEFAULT_MIN_RECORD_DURATION_MS = 2000;

    private static boolean sUseUnauthorizedAdvancedFeatures = false;

    private final String TAG = VideoRecorderRecordCore.class.getSimpleName() + "_" + hashCode();
    private IVideoRecorderCoreInterface mVideoRecorder;
    private final RecordInfo mRecordInfo;

    private IBeautyManager mBeautyManager;
    private Bitmap mFilterBitmap;
    private VideoQuality mVideoQuality = VideoQuality.LOW;
    private Boolean mIsNeedEdit = false;
    private int mMaxDuration = DEFAULT_MAX_RECORD_DURATION_MS;
    private int mMinDuration = DEFAULT_MIN_RECORD_DURATION_MS;

    private long mStartRecordTime;
    private Handler mMainHandler;
    private boolean mStopProgressUpdates;
    
    private final IVideoRecordListener mVideoRecordListener = new IVideoRecordListener() {
        @Override
        public void onStartPreviewError(int eventCode) {
            Log.i(TAG, "onRecordEvent code = " + eventCode);
        }

        @Override
        public void onRecordProgress(long progress) {
            Log.i(TAG, "onRecordProgress progress = " + progress);
            if (progress >= 0 && mStartRecordTime == 0) {
                mStartRecordTime = System.currentTimeMillis();
                startProgressUpdates();
            }
        }

        @Override
        public void onRecordComplete(VideoRecordResult txRecordResult) {
            Log.i(TAG,"on record complete. retCode = " + txRecordResult.retCode + " descMsg = "
                    + txRecordResult.descMsg + " videoPath " + txRecordResult.videoPath);
            handleRecordeComplete(txRecordResult);
        }
    };

    public VideoRecorderRecordCore(Context context, RecordInfo recordInfo) {
        mVideoRecorder = null;
        try {
            mVideoRecorder = new UGCReflectVideoRecorderCore(context);
        } catch (Exception e) {
            Log.i(TAG,"TXVideoRecorderReflector construct fail. error:" + e.toString());
            mVideoRecorder = new SystemVideoRecorderCore(context);
        }
        mRecordInfo = recordInfo;
    }

    public void release() {
        Log.i(TAG, "release");
        mVideoRecorder.setVideoRecordListener(null);
        mVideoRecorder.deleteAllParts();
        setFilterAndStrength(null, 0);
        setBeautyStyleAndLevel(0, 0);
        setWhitenessLevel(0);
        setRuddyLevel(0);
        mVideoRecorder.release();
        mRecordInfo.recordStatus.set(RecordStatus.IDLE);
        mBeautyManager = null;
        mMainHandler = null;
    }

    public void startCameraPreview(TextureView surfaceView) {
        Log.i(TAG, "start camera preview. videoView " + surfaceView);
        VideoRecordCustomConfig customConfig = new VideoRecordCustomConfig();
        initRecordConfig(customConfig);

        mVideoRecorder.startCameraCustomPreview(customConfig, surfaceView);
        mVideoRecorder.setHomeOrientation(VideoRecordCoreConstant.VIDEO_ANGLE_HOME_DOWN);
        mVideoRecorder.setRenderRotation(VideoRecordCoreConstant.RENDER_ROTATION_PORTRAIT);
        mVideoRecorder.setAspectRatio(VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_9_16);
        mVideoRecorder.setVideoRenderMode(VideoRecordCoreConstant.VIDEO_RENDER_MODE_ADJUST_RESOLUTION);
        mVideoRecorder.setMicVolume(DEFAULT_VOLUME);
    }

    public void stopCameraPreview() {
        Log.i(TAG, "stop camera preview");
        mVideoRecorder.stopCameraPreview();
    }

    public int startRecord(String videoFilePath) {
        if (mRecordInfo.recordStatus.get() == RecordStatus.RECORDING) {
            Log.e(TAG, "start record, but current status is recording.");
            return 0;
        }
        Log.i(TAG, "start record. vide file Path is " + videoFilePath);
        mVideoRecorder.setVideoRecordListener(mVideoRecordListener);
        int resultCode = mVideoRecorder.startRecord(videoFilePath);
        if (resultCode >= 0) {
            mStartRecordTime = 0;
            mRecordInfo.recordStatus.set(RecordStatus.RECORDING);
        } else {
            Log.e(TAG,"record start fail. error code is " + resultCode);
        }
        return resultCode;
    }

    public void stopRecord() {
        Log.i(TAG, "stop record.current stats is " + mRecordInfo.recordStatus.get());
        if (mRecordInfo.recordStatus.get() != RecordStatus.RECORDING) {
            return;
        }
        mVideoRecorder.stopRecord();
        mStopProgressUpdates = true;
    }

    public void setAspectRatio(int aspectRatio) {
        Log.i(TAG, "set aspect ration is " + aspectRatio);
        mRecordInfo.aspectRatio.set(aspectRatio);
        mVideoRecorder.setAspectRatio(aspectRatio);
    }

    public int takePhoto(String photoFilePath) {
        Log.i(TAG, "take photo.current status is " + mRecordInfo.recordStatus.get());
        if (mRecordInfo.recordStatus.get() == RecordStatus.RECORDING) {
            return 0;
        }

        mRecordInfo.recordStatus.set(RecordStatus.TAKE_PHOTOING);

        Log.i(TAG,"signature valid is " + isSupportAdvanceFunction()  +
                (sUseUnauthorizedAdvancedFeatures ? " use " : " do not use ")  + " advanced features ");
        if (!isSupportAdvanceFunction() && isUGCRecorderCore() && sUseUnauthorizedAdvancedFeatures) {
            mRecordInfo.recordStatus.set(RecordStatus.STOP);
            return VideoRecordCoreConstant.START_RECORD_ERR_LICENCE_VERIFICATION_FAILED;
        }

        mVideoRecorder.snapshot(isSuccess -> {
            Log.i(TAG, "onSnapshot. snap file Path is " + photoFilePath);
            handleSnapshotComplete(isSuccess, photoFilePath);
        }, photoFilePath);

        return 0;
    }

    public void switchCamera(boolean isFront) {
        Log.i(TAG, "switch camera. is front " + isFront);
        if (isFront) {
            toggleTorch(false);
        }
        mRecordInfo.isFrontCamera.set(isFront);
        mVideoRecorder.switchCamera(isFront);
    }

    public boolean toggleTorch(boolean enable) {
        Log.i(TAG, "toggleTorch enable is " + enable);
        mRecordInfo.isFlashOn.set(enable);
        return mVideoRecorder.toggleTorch(enable);
    }

    public int getMaxZoom() {
        return mVideoRecorder.getMaxZoom();
    }

    public boolean setZoom(int value) {
        Log.i(TAG, "set zoom value = " + value);
        return mVideoRecorder.setZoom(value);
    }

    public void setFocusPosition(float eventX, float eventY) {
        Log.i(TAG, "set focus position [" + eventX + "," + eventY + "]");
        mVideoRecorder.setFocusPosition(eventX, eventY);
    }

    public void setBeautyStyleAndLevel(int style, float level) {
        Log.i(TAG, "set beauty style:" + style + " level:" + level);
        IBeautyManager beautyManager = getBeautyManager();
        if (beautyManager == null) {
            return;
        }

        if (style >= 3 || style < 0) {
            return;
        }
        beautyManager.setBeautyStyle(style);
        beautyManager.setBeautyLevel(level);
        sUseUnauthorizedAdvancedFeatures |= level > 0;
    }

    public void setWhitenessLevel(float whitenessLevel) {
        Log.i(TAG, "set whiteness level:" + whitenessLevel);
        IBeautyManager beautyManager = getBeautyManager();
        if (beautyManager == null) {
            return;
        }
        beautyManager.setWhitenessLevel(whitenessLevel);
        sUseUnauthorizedAdvancedFeatures |= whitenessLevel > 0;
    }

    public void setRuddyLevel(float ruddyLevel) {
        Log.i(TAG, "set ruddy level:" + ruddyLevel);
        IBeautyManager beautyManager = getBeautyManager();
        if (beautyManager == null) {
            return;
        }
        beautyManager.setRuddyLevel(ruddyLevel);
        sUseUnauthorizedAdvancedFeatures |= ruddyLevel > 0;
    }

    public void setFilterAndStrength(Bitmap bitmap, int strength) {
        Log.i(TAG, "set filter bitmap:" + bitmap + " strength:" + strength);
        IBeautyManager beautyManager = getBeautyManager();
        if (beautyManager == null) {
            return;
        }

        if (mFilterBitmap != bitmap) {
            beautyManager.setFilter(bitmap);
            mFilterBitmap = bitmap;
            sUseUnauthorizedAdvancedFeatures |= (bitmap != null);
        }

        strength = (bitmap == null) ? 0 : strength;
        beautyManager.setFilterStrength(strength / 10.0f);
    }

    public void setFilter(Bitmap leftBitmap, float leftIntensity, Bitmap rightBitmap,
            float rightIntensity, float leftRatio) {
        Log.i(TAG, "set filter. left intensity is " + leftIntensity
                + "  right intensity is " + " left ration is " + leftRatio);
        sUseUnauthorizedAdvancedFeatures = true;
        mVideoRecorder.setFilter(leftBitmap, leftIntensity, rightBitmap, rightIntensity, leftRatio);
        mFilterBitmap = null;
    }

    public void setMinDuration(int duration) {
        mMinDuration = duration;
    }

    public int getMaxDuration() {
        return mMaxDuration;
    }

    public void setMaxDuration(int duration) {
        mMaxDuration = duration;
    }

    public void setVideoQuality(VideoQuality videoQuality) {
        Log.i(TAG, "set video quality " + videoQuality);
        mVideoQuality = videoQuality;
    }

    public void setIsNeedEdit(Boolean isNeedEdit) {
        mIsNeedEdit = isNeedEdit;
    }

    public boolean isSupportAdvanceFunction() {
        return isUGCRecorderCore() &&
                VideoRecorderSignatureChecker.getInstance().getSetSignatureResult() == ResultCode.SUCCESS;
    }

    public boolean isUGCRecorderCore() {
        return mVideoRecorder instanceof UGCReflectVideoRecorderCore;
    }

    private void handleRecordeComplete(VideoRecordResult txRecordResult) {
        runInMainHandler(() -> {
            Log.i(TAG, "on Record Complete finish");
            toggleTorch(false);
            if (txRecordResult.retCode == VideoRecordCoreConstant.RECORD_RESULT_OK ||
                    txRecordResult.retCode == VideoRecordCoreConstant.RECORD_RESULT_OK_REACHED_MAXDURATION) {
                mRecordInfo.recordResult.isSuccess = true;
                mRecordInfo.recordResult.type = VideoRecorderConstants.RECORD_TYPE_VIDEO;
                mRecordInfo.recordResult.path = txRecordResult.videoPath;
            } else {
                mRecordInfo.recordResult.isSuccess = false;
            }
            mRecordInfo.recordResult.code = txRecordResult.retCode;
            mRecordInfo.recordStatus.set(RecordStatus.STOP);
            mVideoRecorder.deleteAllParts();
        });
    }

    private void handleSnapshotComplete(Boolean isSuccess, String photoFilePath) {
        runInMainHandler(()->{
            Log.i(TAG, "on Snapshot finish");
            toggleTorch(false);
            mRecordInfo.recordResult.type = VideoRecorderConstants.RECORD_TYPE_PHOTO;
            mRecordInfo.recordResult.path = photoFilePath;
            mRecordInfo.recordResult.isSuccess = isSuccess;
            mRecordInfo.recordStatus.set(RecordStatus.STOP);
        });
    }

    private void initRecordConfig(VideoRecordCustomConfig customConfig) {
        setBaseVideoEncodeParamWithQuality(mVideoQuality, customConfig);

        customConfig.videoGop = DEFAULT_VIDEO_GOP;
        customConfig.profile = VideoRecordCoreConstant.RECORD_PROFILE_HIGH;

        customConfig.maxDuration = mMaxDuration;
        customConfig.minDuration = mMinDuration;
        customConfig.touchFocus = false;
        customConfig.needEdit = false;
        customConfig.isFront = mRecordInfo.isFrontCamera.get();
    }

    private void setBaseVideoEncodeParamWithQuality(VideoQuality quality,
            VideoRecordCustomConfig customConfig) {
        switch (quality) {
            case HIGH:
                customConfig.videoFps = HIGH_QUALITY_FPS;
                customConfig.videoResolution = HIGH_QUALITY_RESOLUTION;
                customConfig.videoBitrate = isUseEditBitRate() ? EDIT_BITRATE : HIGH_QUALITY_BITRATE;
                break;
            case MEDIUM:
                customConfig.videoFps = MEDIUM_QUALITY_FPS;
                customConfig.videoResolution = MEDIUM_QUALITY_RESOLUTION;
                customConfig.videoBitrate = isUseEditBitRate() ? EDIT_BITRATE : MEDIUM_QUALITY_BITRATE;
                break;
            case LOW:
            default:
                customConfig.videoFps = LOW_QUALITY_FPS;
                customConfig.videoResolution = LOW_QUALITY_RESOLUTION;
                customConfig.videoBitrate = isUseEditBitRate() ? EDIT_BITRATE : LOW_QUALITY_BITRATE;
                break;
        }
    }

    private boolean isUseEditBitRate() {
        return isSupportAdvanceFunction() && mIsNeedEdit;
    }

    private IBeautyManager getBeautyManager() {
        if (mBeautyManager != null) {
            return mBeautyManager;
        }

        if (mVideoRecorder == null) {
            return null;
        }

        mBeautyManager = mVideoRecorder.getBeautyManager();
        return mBeautyManager;
    }

    private void runInMainHandler(Runnable runnable) {
        if (Looper.getMainLooper() == Looper.myLooper()) {
            runnable.run();
        } else {
            getMainHandler().post(runnable);
        }
    }

    private void startProgressUpdates() {
        mStopProgressUpdates = false;
        getMainHandler().postDelayed(new Runnable() {
            @Override
            public void run() {
                if (mRecordInfo.recordStatus.get() != RecordStatus.RECORDING || mStopProgressUpdates) {
                    return;
                }
                long elapsed = System.currentTimeMillis() - mStartRecordTime;
                mRecordInfo.recordProcess.set(elapsed * 1.0f / mMaxDuration);
                getMainHandler().postDelayed(this, 100);
            }
        }, 100);
    }

    private Handler getMainHandler() {
        if (mMainHandler == null) {
            mMainHandler = new Handler(Looper.getMainLooper());
        }
        return mMainHandler;
    }
}
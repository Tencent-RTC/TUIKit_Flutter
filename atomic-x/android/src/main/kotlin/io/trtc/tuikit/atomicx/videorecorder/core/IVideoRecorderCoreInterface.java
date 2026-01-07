package io.trtc.tuikit.atomicx.videorecorder.core;

import android.graphics.Bitmap;
import android.view.TextureView;

public interface IVideoRecorderCoreInterface {

    void setVideoRecordListener(IVideoRecordListener listener);

    void startCameraCustomPreview(VideoRecordCustomConfig config, TextureView surfaceView);

    void stopCameraPreview();

    void deleteAllParts();

    int startRecord(String videoFilePath);

    int stopRecord();

    void release();

    boolean setMicVolume(float x);

    boolean switchCamera(boolean isFront);

    void setAspectRatio(int displayType);

    void snapshot(ISnapshotListener listener, String path);

    void setFilter(Bitmap leftBitmap, float leftIntensity, Bitmap rightBitmap, float rightIntensity,
            float leftRatio);

    boolean toggleTorch(boolean enable);

    int getMaxZoom();

    boolean setZoom(int value);

    void setFocusPosition(float eventX, float eventY);

    void setVideoRenderMode(int renderMode);

    void setHomeOrientation(int homeOrientation);

    void setRenderRotation(int renderRotation);

    IBeautyManager getBeautyManager();

    final class VideoRecordResult {
        public int retCode;
        public String descMsg;
        public String videoPath;

        public VideoRecordResult() {}

        public VideoRecordResult(int retCode, String descMsg, String videoPath) {
            this.retCode = retCode;
            this.descMsg = descMsg;
            this.videoPath = videoPath;
        }
    }

    interface IVideoRecordListener {

        void onStartPreviewError(int errorCode);

        void onRecordProgress(long milliSecond);

        void onRecordComplete(VideoRecordResult result);
    }

    final class VideoRecordCustomConfig {
        public int videoResolution = VideoRecordCoreConstant.VIDEO_RESOLUTION_720_1280;
        public int videoFps = 20;
        public int videoBitrate = 1800;
        public int videoGop = 3;

        public boolean isFront = true;
        public boolean touchFocus = false;
        public int minDuration = 5000;
        public int maxDuration = 60000;
        public boolean needEdit = true;
        public int profile = VideoRecordCoreConstant.RECORD_PROFILE_DEFAULT;
    }

    interface IBeautyManager {
        void setBeautyStyle(int beautyStyle) ;
        void setBeautyLevel(float beautyLevel);
        void setWhitenessLevel(float whitenessLevel);
        void setFilterStrength(float strength);
        void setRuddyLevel(float ruddyLevel);
        void setFilter(Bitmap image);
    }

    interface ISnapshotListener {
        void onSnapshotCompleted(Boolean isSuccess);
    }
}

package io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data;

import io.trtc.tuikit.atomicx.videorecorder.config.VideoRecorderConfigInternal;
import io.trtc.tuikit.atomicx.videorecorder.core.VideoRecordCoreConstant;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderData;

public class RecordInfo {

    public VideoRecorderData<RecordStatus> recordStatus = new VideoRecorderData<>(RecordStatus.IDLE);
    public VideoRecorderData<Float> recordProcess = new VideoRecorderData<>(0.0f);
    public VideoRecorderData<Integer> aspectRatio = new VideoRecorderData<>(VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_9_16);
    public VideoRecorderData<Boolean> isFrontCamera = new VideoRecorderData<>(VideoRecorderConfigInternal.getInstance()
            .getIsDefaultFrontCamera());
    public VideoRecorderData<Boolean> isFlashOn = new VideoRecorderData<>(false);
    public VideoRecorderData<Boolean> isShowBeautyView = new VideoRecorderData<>(false);
    public RecordResult recordResult = new RecordResult();
    public BeautyInfo beautyInfo;

    public enum RecordStatus {
        IDLE, STOP, RECORDING,TAKE_PHOTOING
    }

    static public class RecordResult {

        public String path;
        public int type;
        public boolean isSuccess;
        public int code;
    }
}

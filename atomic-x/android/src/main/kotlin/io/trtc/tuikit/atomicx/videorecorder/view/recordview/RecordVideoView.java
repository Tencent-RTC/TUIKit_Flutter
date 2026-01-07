package io.trtc.tuikit.atomicx.videorecorder.view.recordview;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Point;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.TextureView;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;

import io.trtc.tuikit.atomicx.R;
import io.trtc.tuikit.atomicx.videorecorder.core.VideoRecordCoreConstant;
import io.trtc.tuikit.atomicx.videorecorder.core.VideoRecorderRecordCore;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderResourceUtils;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.RecordInfo;

@SuppressLint("ViewConstructor")
public class RecordVideoView extends FrameLayout {

    private final String TAG = RecordVideoView.class.getSimpleName() + "_" + hashCode();
    private final Context mContext;
    private final VideoRecorderRecordCore mRecordCore;
    private final RecordInfo mRecordInfo;

    private TextureView mVideoView;

    //private final VideoRecorderDataObserver<Integer> mAspectRatioObserver = this::setVideoViewSize;

    public RecordVideoView(@NonNull Context context, VideoRecorderRecordCore recordCore, RecordInfo recordInfo) {
        super(context);
        mContext = context;
        mRecordCore = recordCore;
        mRecordInfo = recordInfo;
    }

    @Override
    public void onAttachedToWindow() {
        Log.i(TAG, "onAttachedToWindow");
        super.onAttachedToWindow();
        initView();
        addObserver();
    }

    @Override
    public void onDetachedFromWindow() {
        Log.i(TAG, "onDetachedFromWindow");
        super.onDetachedFromWindow();
        mRecordCore.stopCameraPreview();
        removeObserver();
        removeAllViews();
    }

    public void initView() {
        LayoutInflater.from(mContext).inflate(R.layout.video_recorder_video_play_view, this, true);
        mVideoView = findViewById(R.id.record_video_view);
        //setVideoViewSize(mRecordInfo.aspectRatio.get());
        // todo:Temporary adjustment fixed to 16:9 ratio
        setVideoViewSize(VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_9_16);
        mRecordCore.startCameraPreview(mVideoView);
    }

    public void addObserver() {
        // todo:Temporary adjustment fixed to 16:9 ratio
        //mRecordInfo.aspectRatio.observe(mAspectRatioObserver);
    }

    public void removeObserver() {
        // todo:Temporary adjustment fixed to 16:9 ratio
        //mRecordInfo.aspectRatio.removeObserver(mAspectRatioObserver);
    }

    private void setVideoViewSize(int aspectRatio) {
        Point screenSize = VideoRecorderResourceUtils.getScreenSize(mContext);
        Log.i(TAG, "screenSize = " + screenSize);
        switch (aspectRatio) {
            case VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_9_16:
                mVideoView.setLayoutParams(new LayoutParams(screenSize.x, screenSize.x * 16 / 9));
                break;
            case VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_3_4:
                LayoutParams layoutParams = (LayoutParams) mVideoView.getLayoutParams();
                layoutParams.width = screenSize.x;
                layoutParams.height = screenSize.x * 4 / 3;
                layoutParams.topMargin = (screenSize.y - layoutParams.height) / 2;
                mVideoView.setLayoutParams(layoutParams);
                break;
//            case TXRecordCommon.VIDEO_ASPECT_RATIO_FULL_SRCREEN:
//                mVideoView.setLayoutParams(new FrameLayout.LayoutParams(screenSize.x, screenSize.y));
//                break;
            default:
                break;
        }
    }
}
package io.trtc.tuikit.atomicx.videorecorder.view;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;

import android.content.Context;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import io.trtc.tuikit.atomicx.R;
import io.trtc.tuikit.atomicx.videorecorder.config.VideoRecorderConfigInternal;
import io.trtc.tuikit.atomicx.videorecorder.config.VideoRecorderConstants;
import io.trtc.tuikit.atomicx.videorecorder.core.VideoRecordCoreConstant;
import io.trtc.tuikit.atomicx.videorecorder.core.VideoRecorderRecordCore;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderData.VideoRecorderDataObserver;
import io.trtc.tuikit.atomicx.videorecorder.view.preview.PicturePreviewFragment;
import io.trtc.tuikit.atomicx.videorecorder.view.preview.VideoPreviewFragment;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.RecordFunctionView;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.RecordVideoView;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.RecordInfo;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.RecordInfo.RecordResult;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.RecordInfo.RecordStatus;

public class VideoRecorderFragment extends Fragment {

    private final String TAG = VideoRecorderFragment.class.getSimpleName() + "_" + hashCode();
    private final Context mContext;
    private final VideoRecorderRecordCore mVideoRecorderRecordCore;
    private final RecordInfo mRecordInfo;
    private final VideoRecorderDataObserver<RecordStatus> mRecordStatusObserver = new VideoRecorderDataObserver<RecordStatus>() {
        @Override
        public void onChanged(RecordStatus recordStatus) {
            Log.i(TAG, "record status onChanged. current status is " + recordStatus
                    + " record result : " + mRecordInfo.recordResult.isSuccess);
            if (recordStatus == RecordStatus.STOP && mRecordInfo.recordResult.isSuccess) {
                editRecordFile(mRecordInfo.recordResult);
            }
        }
    };
    private RecordVideoView mRecordVideoView;
    private RecordFunctionView mRecordFunctionView;
    private RelativeLayout mVideoViewContainer;
    private RelativeLayout mRecordFunctionContainer;
    private boolean isFlashOnWhenPause;

    public VideoRecorderFragment(Context context) {
        mContext = context;
        mRecordInfo = new RecordInfo();
        mVideoRecorderRecordCore = new VideoRecorderRecordCore(context, mRecordInfo);
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        initParameters();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View contentView = inflater.inflate(R.layout.video_recorder_fragment, container, false);
        mVideoViewContainer = contentView.findViewById(R.id.rl_video_view_container);
        mRecordFunctionContainer = contentView.findViewById(R.id.rl_function_view_container);
        addObserver();
        addChildView();
        return contentView;
    }

    @Override
    public void onDestroyView() {
        Log.i(TAG, "onDestroyView");
        super.onDestroyView();
        removeChildView();
        removeObserver();
    }

    @Override
    public void onDestroy() {
        Log.i(TAG, "onDestroy");
        super.onDestroy();
        mVideoRecorderRecordCore.release();
    }

    @Override
    public void onResume() {
        super.onResume();
        mVideoRecorderRecordCore.toggleTorch(isFlashOnWhenPause);
    }

    @Override
    public void onPause() {
        super.onPause();
        isFlashOnWhenPause = mRecordInfo.isFlashOn.get();
        mVideoRecorderRecordCore.toggleTorch(false);
    }

    private void addObserver() {
        mRecordInfo.recordStatus.observe(mRecordStatusObserver);
    }

    private void removeObserver() {
        mRecordInfo.recordStatus.removeObserver(mRecordStatusObserver);
    }

    private void initParameters() {
        mVideoRecorderRecordCore.setMaxDuration(VideoRecorderConfigInternal.getInstance().getMaxRecordDurationMs());
        mVideoRecorderRecordCore.setMinDuration(VideoRecorderConfigInternal.getInstance().getMinRecordDurationMs());
        mVideoRecorderRecordCore.setVideoQuality(VideoRecorderConfigInternal.getInstance().getVideoQuality());
        mVideoRecorderRecordCore.setIsNeedEdit(false);
    }

    private void removeChildView() {
        mVideoViewContainer.removeAllViews();
        mRecordFunctionContainer.removeAllViews();
    }

    private void addChildView() {
        mVideoViewContainer.removeAllViews();
        if (mRecordVideoView == null) {
            mRecordVideoView = new RecordVideoView(mContext, mVideoRecorderRecordCore, mRecordInfo);
        }
        mVideoViewContainer
                .addView(mRecordVideoView, new RelativeLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT));

        mRecordFunctionContainer.removeAllViews();
        if (mRecordFunctionView == null) {
            mRecordFunctionView = new RecordFunctionView(mContext, mVideoRecorderRecordCore, mRecordInfo);
        }
        mRecordFunctionContainer
                .addView(mRecordFunctionView, new RelativeLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT));
    }

    private void editRecordFile(RecordResult recordResult) {
        Log.i(TAG,"editRecordFile file path: " + recordResult.path);
        Fragment fragment;
        if (recordResult.type == VideoRecorderConstants.RECORD_TYPE_PHOTO) {
            fragment = new PicturePreviewFragment(mContext);
        } else {
            fragment = new VideoPreviewFragment(mContext);
        }

        Bundle bundle = new Bundle();
        bundle.putString(VideoRecorderConstants.PARAM_NAME_EDIT_FILE_PATH, recordResult.path);
        bundle.putFloat(VideoRecorderConstants.PARAM_NAME_EDIT_FILE_RATIO,
                convertAspectRation(mRecordInfo.aspectRatio.get()));
        bundle.putBoolean(VideoRecorderConstants.PARAM_NAME_IS_RECODE_FILE, true);

        fragment.setArguments(bundle);
        ((AppCompatActivity) mContext).getSupportFragmentManager()
                .beginTransaction()
                .replace(R.id.fl_record_fragment_container, fragment)
                .addToBackStack(null).commit();

    }

    private float convertAspectRation(int aspectRatio) {
        switch (aspectRatio) {
            case VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_16_9:
                return 16.0f / 9.0f;
            case VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_3_4:
                return 3.0f / 4.0f;
            case VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_4_3:
                return 4.0f / 3.0f;
            case VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_1_1:
                return 1.0f;
            case VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_9_16:
            default:
                return 9.0f / 16.0f;
        }
    }
}
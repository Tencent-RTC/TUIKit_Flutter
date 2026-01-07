package io.trtc.tuikit.atomicx.videorecorder.view.preview;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
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
import io.trtc.tuikit.atomicx.videorecorder.config.VideoRecorderConstants;
import io.trtc.tuikit.atomicx.videorecorder.config.VideoRecorderConfigInternal;
import io.trtc.tuikit.atomicx.videorecorder.core.VideoPreviewCore;
import io.trtc.tuikit.atomicx.videorecorder.view.preview.PreviewCommonCtrlView.CommonMediaEditListener;
import io.trtc.tuikit.atomicx.videorecorder.view.preview.PreviewCommonCtrlView.EditType;

public class VideoPreviewFragment extends Fragment {
    private final String TAG = VideoPreviewFragment.class.getSimpleName() + "_" + hashCode();
    private final Context mContext;

    private PreviewCommonCtrlView mPreviewCommonCtrlView;
    private View mRootView;
    private String mEditFilePath;
    private float mAspectRatio = 9.0f / 16.0f;
    private boolean mIsRecordFile = false;
    private String mSourceFilePath;
    private VideoPreviewCore mVideoPreviewCore;

    public VideoPreviewFragment(Context context) {
        mContext = context;
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        Log.i(TAG, "onCreate");
        initExternalParameters();
        super.onCreate(savedInstanceState);
        mVideoPreviewCore = new VideoPreviewCore(mContext);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        Log.i(TAG, "onCreateView");
        mRootView = inflater.inflate(R.layout.video_recorder_preview_video_fragment, container, false);
        initView();
        return mRootView;
    }

    @Override
    public void onDestroyView() {
        Log.i(TAG, "onDestroyView");
        super.onDestroyView();
    }

    @Override
    public void onDestroy() {
        Log.i(TAG, "onDestroy");
        super.onDestroy();
        mVideoPreviewCore.release();
    }

    @Override
    public void onResume() {
        super.onResume();
        mVideoPreviewCore.startPreview();
    }

    @Override
    public void onPause() {
        super.onPause();
        mVideoPreviewCore.stopPreview();
    }

    public void initView() {
        mPreviewCommonCtrlView = new PreviewCommonCtrlView(mContext, EditType.VIDEO, mIsRecordFile);
        mPreviewCommonCtrlView.setMediaAspectRatio(mAspectRatio);
        ((RelativeLayout) mRootView.findViewById(R.id.edit_common_ctrl_view_container))
                .addView(mPreviewCommonCtrlView, new RelativeLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT));
        previewVideo(mEditFilePath);
        mPreviewCommonCtrlView.setCommonMediaEditListener(new CommonMediaEditListener() {
            @Override
            public void onGenerateMedia() {
                generateVideo();
            }

            @Override
            public void onCancelEdit() {
                ((AppCompatActivity) mContext).getSupportFragmentManager().popBackStack();
            }
        });
    }

    private void previewVideo(String videoFilePath) {
        Log.i(TAG, "preview video. file path = " + videoFilePath);
        mSourceFilePath = videoFilePath;
        if (videoFilePath == null || videoFilePath.isEmpty()) {
            Log.e(TAG, "vide file path is null");
            return;
        }

        mVideoPreviewCore.setSource(videoFilePath);
        VideoPreview editorVideoView = new VideoPreview(mContext,
                mVideoPreviewCore);
        mPreviewCommonCtrlView.setMediaView(editorVideoView);
    }

    private void generateVideo() {
        finishEdit(mEditFilePath);
    }

    private void finishEdit(String editedFilePath) {
        Log.i(TAG, "finish edit. path = " + editedFilePath);
        Intent resultIntent = new Intent();
        if (editedFilePath != null) {
            resultIntent.putExtra(VideoRecorderConstants.PARAM_NAME_EDITED_FILE_PATH, editedFilePath);
            resultIntent.putExtra(VideoRecorderConstants.PARAM_NAME_RECORD_TYPE, VideoRecorderConstants.RECORD_TYPE_VIDEO);
        }
        ((Activity) mContext).setResult(Activity.RESULT_OK, resultIntent);
        ((Activity) mContext).finish();
    }

    private void initExternalParameters() {
        Bundle bundle = getArguments();
        if (bundle == null) {
            return;
        }
        mEditFilePath = bundle.getString(VideoRecorderConstants.PARAM_NAME_EDIT_FILE_PATH, "");
        mAspectRatio = bundle.getFloat(VideoRecorderConstants.PARAM_NAME_EDIT_FILE_RATIO, 9.0f / 16.0f);
        mIsRecordFile = bundle.getBoolean(VideoRecorderConstants.PARAM_NAME_IS_RECODE_FILE, false);
        Log.i(TAG, "init external parameters mEditFilePath = " + mEditFilePath
                + " video quality = " + VideoRecorderConfigInternal.getInstance().getVideoQuality()
                + ", video ratio = " + mAspectRatio);
    }
}
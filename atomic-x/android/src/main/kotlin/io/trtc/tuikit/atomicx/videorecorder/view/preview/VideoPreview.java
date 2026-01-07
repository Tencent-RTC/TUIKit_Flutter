package io.trtc.tuikit.atomicx.videorecorder.view.preview;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import io.trtc.tuikit.atomicx.R;
import io.trtc.tuikit.atomicx.videorecorder.core.VideoPreviewCore;

@SuppressLint("ViewConstructor")
public class VideoPreview extends FrameLayout {

    private final String TAG = VideoPreview.class.getSimpleName() + "_" + hashCode();
    private final Context mContext;
    private final VideoPreviewCore mEditorCore;

    public VideoPreview(@NonNull Context context, VideoPreviewCore editorCore) {
        super(context);
        mContext = context;
        mEditorCore = editorCore;
    }

    @Override
    public void onAttachedToWindow() {
        Log.i(TAG, "onAttachedToWindow");
        super.onAttachedToWindow();
        initView();
    }

    @Override
    public void onDetachedFromWindow() {
        Log.i(TAG, "onDetachedFromWindow");
        super.onDetachedFromWindow();
        mEditorCore.stopPreview();
        removeAllViews();
    }

    public void initView() {
        View rootView = LayoutInflater.from(mContext).inflate(R.layout.video_recorder_preview_video_fragment, this, true);
        ((ViewGroup) rootView).removeAllViews();
        ((ViewGroup) rootView).addView(mEditorCore.getVideoView(), new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT));
        mEditorCore.startPreview();
    }
}

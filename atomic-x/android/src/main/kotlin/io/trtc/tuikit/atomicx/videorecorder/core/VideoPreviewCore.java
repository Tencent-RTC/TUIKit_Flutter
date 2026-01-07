package io.trtc.tuikit.atomicx.videorecorder.core;

import android.content.Context;
import android.util.Log;
import android.widget.VideoView;

public class VideoPreviewCore {
    private final String TAG = VideoPreviewCore.class.getSimpleName() + hashCode();

    private final VideoView mVideoView;

    public VideoPreviewCore(Context context) {
        mVideoView = new VideoView(context);
        mVideoView.setOnCompletionListener(mp -> {
            Log.i(TAG, "videoView on completion");
            mVideoView.start();
        });
    }

    public void stopPreview() {
        mVideoView.stopPlayback();
    }

    public void setSource(String path) {
        mVideoView.setVideoPath(path);
    }

    public void startPreview() {
        if (!mVideoView.isPlaying()) {
            mVideoView.start();
        }
    }

    public void release() {

    }

    public void resumePreview() {
        mVideoView.resume();
    }

    public void pausePreview() {
        mVideoView.pause();
    }

    public VideoView getVideoView() {
        return mVideoView;
    }
}

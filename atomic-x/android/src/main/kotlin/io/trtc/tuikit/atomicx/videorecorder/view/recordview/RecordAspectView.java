package io.trtc.tuikit.atomicx.videorecorder.view.recordview;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import io.trtc.tuikit.atomicx.R;

import io.trtc.tuikit.atomicx.videorecorder.core.VideoRecorderRecordCore;
import io.trtc.tuikit.atomicx.videorecorder.core.VideoRecordCoreConstant;
import io.trtc.tuikit.atomicx.videorecorder.view.VideoRecorderAuthorizationPrompter;
import io.trtc.tuikit.atomicx.videorecorder.view.VideoRecorderAuthorizationPrompter.PrompterType;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.RecordInfo;

@SuppressLint("ViewConstructor")
public class RecordAspectView extends RelativeLayout {

    private final String TAG = RecordAspectView.class.getSimpleName() + "_" + hashCode();
    private final Context mContext;
    private final VideoRecorderRecordCore mRecordCore;
    private final RecordInfo mRecordInfo;

    private ImageView mImageAspectCurr;
    private int mFirstAspect;


    public RecordAspectView(Context context, VideoRecorderRecordCore recordCore, RecordInfo recordInfo) {
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
    }

    @Override
    public void onDetachedFromWindow() {
        Log.i(TAG, "onDetachedFromWindow");
        super.onDetachedFromWindow();
        removeAllViews();
    }

    private void initView() {
        View root = LayoutInflater.from(mContext).inflate(R.layout.video_recorder_aspect_view, this, true);
        mImageAspectCurr = findViewById(R.id.iv_aspect);
        ((TextView)findViewById(R.id.tv_aspect)).setText(R.string.video_recorder_aspect);
        selectAnotherAspect(mRecordInfo.aspectRatio.get());
        root.setOnClickListener(view -> {
            if (!mRecordCore.isUGCRecorderCore()) {
                VideoRecorderAuthorizationPrompter.showPermissionPrompterDialog(mContext, PrompterType.NO_LITEAV_SDK);
                return;
            }
            selectAnotherAspect(mFirstAspect);
        });
    }

    private void selectAnotherAspect(int targetScale) {
        mRecordCore.setAspectRatio(targetScale);
        switch (targetScale) {
            case VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_9_16:
                mImageAspectCurr.setImageResource(R.drawable.video_recorder_aspect_916);
                mFirstAspect = VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_3_4;
                break;
            case VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_3_4:
                mImageAspectCurr.setImageResource(R.drawable.video_recorder_aspect_34);
                mFirstAspect = VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_9_16;
                break;
//            case TXRecordCommon.VIDEO_ASPECT_RATIO_FULL_SRCREEN:
//                mImageAspectCurr.setImageResource(R.drawable.video_recorder_ic_aspect_11);
//                mFirstAspect = TXRecordCommon.VIDEO_ASPECT_RATIO_9_16;
//                break;
            default:
                break;
        }
    }
}

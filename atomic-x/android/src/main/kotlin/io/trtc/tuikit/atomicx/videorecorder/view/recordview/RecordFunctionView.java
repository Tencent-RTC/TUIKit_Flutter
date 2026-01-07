package io.trtc.tuikit.atomicx.videorecorder.view.recordview;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Point;
import android.view.LayoutInflater;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

import androidx.annotation.NonNull;

import io.trtc.tuikit.atomicx.R;
import io.trtc.tuikit.atomicx.videorecorder.core.VideoRecorderRecordCore;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderData.VideoRecorderDataObserver;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderResourceUtils;
import io.trtc.tuikit.atomicx.videorecorder.view.VideoRecorderAuthorizationPrompter;
import io.trtc.tuikit.atomicx.videorecorder.view.VideoRecorderAuthorizationPrompter.PrompterType;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.RecordInfo;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.RecordInfo.RecordStatus;

@SuppressLint("ViewConstructor")
public class RecordFunctionView extends LinearLayout {

    private final static int DEFAULT_OPERATION_VIEW_HEIGHT_DP = 215;
    private final static int MIN_OPERATION_VIEW_HEIGHT_DP = 155;
    private final static int DEFAULT_OPERATION_TIPS_VIEW_HEIGHT_DP = 40;
    private final Context mContext;
    private final VideoRecorderRecordCore mRecordCore;
    private final RecordInfo mRecordInfo;

    private RecordSettingView mRecordSettingView;
    private RecordOperationView mRecordOperationView;

    private RelativeLayout mOperationViewContainer;
    private final VideoRecorderDataObserver<Boolean> mIsShowBeautyView = new VideoRecorderDataObserver<Boolean>() {
        @Override
        public void onChanged(Boolean isShowBeautyView) {
            if (mOperationViewContainer != null) {
                mOperationViewContainer.setVisibility(isShowBeautyView ? GONE : VISIBLE);
            }
            if (isShowBeautyView && !mRecordCore.isSupportAdvanceFunction()) {
                VideoRecorderAuthorizationPrompter.showPermissionPrompterDialog(mContext,
                        mRecordCore.isUGCRecorderCore() ? PrompterType.NO_SIGNATURE : PrompterType.NO_LITEAV_SDK);
            }
        }
    };
    private RelativeLayout mSettingViewContainer;
    private final VideoRecorderDataObserver<RecordStatus> mRecodeStatusOnChanged = new VideoRecorderDataObserver<RecordStatus>() {
        @Override
        public void onChanged(RecordStatus recordStatus) {
            if (mSettingViewContainer != null) {
                int visibility = (recordStatus == RecordStatus.RECORDING
                        || recordStatus == RecordStatus.TAKE_PHOTOING) ? GONE : VISIBLE;
                mSettingViewContainer.setVisibility(visibility);
            }
        }
    };

    public RecordFunctionView(@NonNull Context context, VideoRecorderRecordCore recordCore, RecordInfo recordInfo) {
        super(context);
        mContext = context;
        mRecordCore = recordCore;
        mRecordInfo = recordInfo;
    }

    @Override
    public void onAttachedToWindow() {
        super.onAttachedToWindow();
        initView();
        addObserver();
    }

    @Override
    public void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        removeObserver();
        removeAllViews();
    }

    @Override
    public void removeAllViews() {
        if (mOperationViewContainer != null) {
            mOperationViewContainer.removeAllViews();
        }

        if (mSettingViewContainer != null) {
            mSettingViewContainer.removeAllViews();
        }
        super.removeAllViews();
    }

    public void initView() {
        LayoutInflater.from(mContext).inflate(R.layout.video_recorder_function_view, this, true);

        initRecordOperationView();

        mSettingViewContainer = findViewById(R.id.rl_setting_view_container);
        mSettingViewContainer.removeAllViews();
        if (mRecordSettingView == null) {
            mRecordSettingView = new RecordSettingView(mContext, mRecordCore, mRecordInfo);
        }
        mSettingViewContainer.addView(mRecordSettingView, new RelativeLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT));
    }

    private void initRecordOperationView() {
        mOperationViewContainer = findViewById(R.id.rl_operation_view_container);
        mOperationViewContainer.removeAllViews();
        if (mRecordOperationView == null) {
            mRecordOperationView = new RecordOperationView(mContext, mRecordCore, mRecordInfo);
        }
        adjustRecordOperationViewPosition(mRecordInfo.aspectRatio.get());
    }

    private void adjustRecordOperationViewPosition(int aspectRation) {
        if (mOperationViewContainer == null || mRecordOperationView == null) {
            return;
        }

        mOperationViewContainer.removeAllViews();
        Point screenSize = VideoRecorderResourceUtils.getScreenSize(mContext);
//        int viewHeight = VideoRecorderResourceUtils.dip2px(mContext, DEFAULT_OPERATION_VIEW_HEIGHT_DP);
//        if (aspectRation == VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_9_16) {
//            viewHeight = screenSize.y - screenSize.x * 16 / 9 + VideoRecorderResourceUtils
//                    .dip2px(mContext, DEFAULT_OPERATION_TIPS_VIEW_HEIGHT_DP);
//        } else if (aspectRation == VideoRecordCoreConstant.VIDEO_ASPECT_RATIO_3_4) {
//            viewHeight = screenSize.y / 2 - (screenSize.x * 4 / 3) / 2 + VideoRecorderResourceUtils
//                    .dip2px(mContext, DEFAULT_OPERATION_TIPS_VIEW_HEIGHT_DP);
//        }

         // todo:Temporary adjustment fixed to 16:9 ratio
         int viewHeight = screenSize.y - screenSize.x * 16 / 9 + VideoRecorderResourceUtils
                .dip2px(mContext, DEFAULT_OPERATION_TIPS_VIEW_HEIGHT_DP);

        int minViewHeight = VideoRecorderResourceUtils.dip2px(mContext, MIN_OPERATION_VIEW_HEIGHT_DP);
        viewHeight = Math.max(viewHeight, minViewHeight);
        LayoutParams linearLayoutCompat = new LayoutParams(MATCH_PARENT, viewHeight);
        mOperationViewContainer.addView(mRecordOperationView, linearLayoutCompat);
    }

    private void addObserver() {
        mRecordInfo.isShowBeautyView.observe(mIsShowBeautyView);
        mRecordInfo.recordStatus.observe(mRecodeStatusOnChanged);
        mRecordInfo.aspectRatio.observe(this::adjustRecordOperationViewPosition);
    }

    private void removeObserver() {
        mRecordInfo.isShowBeautyView.removeObserver(mIsShowBeautyView);
        mRecordInfo.recordStatus.removeObserver(mRecodeStatusOnChanged);
        mRecordInfo.aspectRatio.removeObserver(this::adjustRecordOperationViewPosition);
    }
}

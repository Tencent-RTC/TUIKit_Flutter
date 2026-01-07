package io.trtc.tuikit.atomicx.videorecorder.view.preview;


import android.content.Context;
import android.graphics.Point;
import android.graphics.Rect;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewTreeObserver;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

import io.trtc.tuikit.atomicx.R;
import io.trtc.tuikit.atomicx.videorecorder.config.VideoRecorderConfigInternal;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderResourceUtils;

public class PreviewCommonCtrlView extends RelativeLayout {

    private final static int COMMON_FUNCTION_ICON_SIZE_DP = 28;
    private final static int BGM_FUNCTION_ICON_MARGIN_DP = 34;

    private final String TAG = PreviewCommonCtrlView.class.getSimpleName() + "_" + hashCode();
    private final Context mContext;
    private final EditType mEditType;

    private ViewTreeObserver.OnGlobalLayoutListener mOnGlobalLayoutListener;
    private RelativeLayout mOperationLayout;
    private LinearLayout mFunctionButtonLayout;
    private ImageView mReturnBackView;
    private View mRootView;

    private float mAspectRatio = 9.0f / 16.0f;
    private View mMediaView;

    private TransformLayout mPreviewContainer;
    private final OnClickListener mOnPreviewClickListener = new OnClickListener() {
        @Override
        public void onClick(View v) {
            showOperationView(true);
        }
    };
    private Rect mPreviewRect;
    private CommonMediaEditListener mCommonMediaEditListener;

    public PreviewCommonCtrlView(Context context, EditType editType, boolean isRecordFile) {
        super(context);
        mContext = context;
        mEditType = editType;
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
        mRootView.getViewTreeObserver().removeOnGlobalLayoutListener(mOnGlobalLayoutListener);
        removeAllViews();
    }

    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
        super.onLayout(changed, l, t, r, b);
        if (!changed) {
            return;
        }

        adjustFunctionButtonLayout();
        adjustPreviewLayout();
    }

    public void initView() {
        mRootView = LayoutInflater.from(mContext).inflate(R.layout.video_recorder_preview_view, this);
        mOperationLayout = mRootView.findViewById(R.id.operation_layout);
        mReturnBackView = mRootView.findViewById(R.id.edit_return_back);
        mPreviewContainer = mRootView.findViewById(R.id.rl_preview);
        mFunctionButtonLayout = mRootView.findViewById(R.id.function_button_layout);
        mPreviewContainer.enableTransform(mEditType == EditType.PHOTO);
        mPreviewContainer.setOnClickListener(mOnPreviewClickListener);
        mPreviewContainer.setOnClickListener(view -> switchOperationBtnShow());

        mReturnBackView.setOnClickListener(view -> {
            if (mCommonMediaEditListener != null) {
                mCommonMediaEditListener.onCancelEdit();
            }
        });

        initSendBtn();
        adjustPreviewLayout();
        setMediaView(mMediaView);
        mOnGlobalLayoutListener = this::adjustFunctionButtonLayout;
        mRootView.getViewTreeObserver().addOnGlobalLayoutListener(mOnGlobalLayoutListener);
    }

    public void setMediaView(View view) {
        if (view == null) {
            return;
        }

        adjustPreviewLayout();
        if (mPreviewContainer != null) {
            LayoutParams layoutParams = new LayoutParams(mPreviewRect.width(), mPreviewRect.height());
            layoutParams.leftMargin = mPreviewRect.left;
            layoutParams.topMargin = mPreviewRect.top;
            mPreviewContainer.addView(view, 0, layoutParams);
        }
        mMediaView = view;
    }

    public void setMediaAspectRatio(float aspectRatio) {
        Log.i(TAG, "set media aspect ratio. aspect ratio:" + aspectRatio);
        mAspectRatio = aspectRatio;
        adjustPreviewLayout();
    }

    private void initSendBtn() {
        Button button = mRootView.findViewById(R.id.send_btn);
        button.setBackground(
                VideoRecorderResourceUtils.getDrawable(mContext, R.drawable.video_edit_send_button,
                        VideoRecorderConfigInternal.getInstance().getThemeColor()));
        button.setGravity(Gravity.CENTER);
        button.setText(VideoRecorderResourceUtils.getString(R.string.video_recorder_send));

        button.setOnClickListener(view -> {
            showOperationView(false);
            if (mCommonMediaEditListener != null) {
                mCommonMediaEditListener.onGenerateMedia();
            }
        });
    }

    public void setCommonMediaEditListener(CommonMediaEditListener commonMediaEditListener) {
        mCommonMediaEditListener = commonMediaEditListener;
    }

    public void showOperationView(boolean show) {
        int visible = show ? View.VISIBLE : View.GONE;
        mReturnBackView.setVisibility(visible);
        mOperationLayout.setVisibility(visible);
        mPreviewContainer.enableTransform(mEditType == EditType.PHOTO);
    }

    private void adjustPreviewLayout() {
        if (mPreviewContainer == null) {
            return;
        }

        int previewContainerWidth = mPreviewContainer.getWidth();
        int previewContainerHeight = mPreviewContainer.getHeight();

        if (previewContainerWidth == 0 || previewContainerHeight == 0) {
            Point screenSize = VideoRecorderResourceUtils.getScreenSize(mContext);
            previewContainerWidth = screenSize.x;
            previewContainerHeight = screenSize.y;
        }

        int previewHeight = (int) (previewContainerWidth / mAspectRatio);
        int previewTop = (previewContainerHeight - previewHeight) / 2;
        Rect previewRect = new Rect(0, previewTop, previewContainerWidth, previewTop + previewHeight);

        if (previewRect.equals(mPreviewRect)) {
            return;
        }
        mPreviewRect = previewRect;
        mPreviewContainer.initContentLayout(mPreviewRect);
    }

    private void adjustFunctionButtonLayout() {
        int width = mFunctionButtonLayout.getWidth();
        int count = mFunctionButtonLayout.getChildCount();
        int viewWidth = count * VideoRecorderResourceUtils.dip2px(mContext, COMMON_FUNCTION_ICON_SIZE_DP);
        int margin = (width - viewWidth) / (count + 1);
        for (int i = 0; i < count; i++) {
            View child = mFunctionButtonLayout.getChildAt(i);
            LinearLayout.LayoutParams layoutParams = (LinearLayout.LayoutParams) child.getLayoutParams();
            layoutParams.setMarginStart(margin);
            layoutParams.setMarginEnd(0);
            child.setLayoutParams(layoutParams);
        }
    }

    private void switchOperationBtnShow() {
        if (mReturnBackView != null) {
            mReturnBackView.setVisibility(
                    mReturnBackView.getVisibility() == VISIBLE ? INVISIBLE : VISIBLE);
        }

        if (mOperationLayout != null) {
            mOperationLayout.setVisibility(
                    mOperationLayout.getVisibility() == VISIBLE ? INVISIBLE : VISIBLE);
        }
    }

    public enum EditType {
        VIDEO, PHOTO
    }

    public interface CommonMediaEditListener {

        void onGenerateMedia();

        void onCancelEdit();
    }
}
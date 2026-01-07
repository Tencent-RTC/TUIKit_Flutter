package io.trtc.tuikit.atomicx.videorecorder.view.recordview;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;
import static android.view.ViewGroup.LayoutParams.WRAP_CONTENT;

import android.content.Context;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import androidx.annotation.NonNull;

import io.trtc.tuikit.atomicx.R;
import io.trtc.tuikit.atomicx.videorecorder.config.VideoRecorderConfigInternal;
import io.trtc.tuikit.atomicx.videorecorder.core.UGCReflectVideoRecorderCore;
import io.trtc.tuikit.atomicx.videorecorder.core.VideoRecorderRecordCore;
import io.trtc.tuikit.atomicx.videorecorder.core.VideoRecorderSignatureChecker;
import io.trtc.tuikit.atomicx.videorecorder.core.VideoRecorderSignatureChecker.ResultCode;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderData.VideoRecorderDataObserver;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderResourceUtils;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.BeautyFilterScrollView;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.BeautyPanelView;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.BeautyInfo;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.RecordInfo;

public class RecordSettingView extends RelativeLayout {

    private static boolean isAppDebuggable(Context context) {
        return (context.getApplicationInfo().flags & android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0;
    }

    private static final int SCROLL_FILTER_RIGHT_LEFT_MARGIN_SP = 15;
    private static final int SETTING_ITEM_VIEW_BOTTOM_MARGIN_SP = 24;
    private final String TAG = RecordSettingView.class.getSimpleName() + "_" + hashCode();
    private final Context mContext;
    private final VideoRecorderRecordCore mRecordCore;

    private RecordInfo mRecordInfo;
    private BeautyPanelView mBeautyPanelView;
    private BeautyFilterScrollView mBeautyFilterScrollView;
    private SettingItemViewHolder mSettingItemTorch;
    private RecordAspectView mAspectView;
    private LinearLayout mLayoutSetting;
    private RelativeLayout mBeautyPanelViewContainer;
    private RelativeLayout mScrollFilterViewContainer;
    
    private final VideoRecorderDataObserver<Boolean> flashStatusObserver = isOnAndFront -> {
        if (mSettingItemTorch == null) {
            return;
        }

        Log.i(TAG,"is front camera:" + mRecordInfo.isFrontCamera.get()
                + " is flash on: " + mRecordInfo.isFlashOn.get());

        if (mRecordInfo.isFrontCamera.get()) {
            mSettingItemTorch.setIconRes(R.drawable.video_recorder_torch_close_disable);
            mSettingItemTorch.setClickable(false);
            return;
        }

        int resId = mRecordInfo.isFlashOn.get() ? R.drawable.video_recorder_torch_open : R.drawable.video_recorder_torch_close;
        mSettingItemTorch.setIconRes(resId);
        mSettingItemTorch.setClickable(true);
    };

    public RecordSettingView(@NonNull Context context, VideoRecorderRecordCore recordCore, RecordInfo recordInfo) {
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
        removeAllViews();
        removeObserver();
    }

    @Override
    public void removeAllViews() {
        if (mBeautyPanelViewContainer != null) {
            mBeautyPanelViewContainer.removeAllViews();
        }

        if (mScrollFilterViewContainer != null) {
            mScrollFilterViewContainer.removeAllViews();
        }

        mLayoutSetting.removeAllViews();
        super.removeAllViews();
    }

    public void initView() {
        View rootView = LayoutInflater.from(mContext).inflate(R.layout.video_recorder_setting_view, this, true);
        rootView.setOnClickListener(v -> {
            if (mBeautyPanelView != null) {
                mBeautyPanelView.setVisibility(GONE);
            }
        });
        mLayoutSetting = findViewById(R.id.layout_setting_item);

        initTorchView();
        initBeautyView();
        initScrollBeautyFilterView();
        initAspectView();
    }

    private void initTorchView() {
        if (!VideoRecorderConfigInternal.getInstance().isSupportRecordTorch()) {
            return;
        }

        mSettingItemTorch = addSettingItem(R.drawable.video_recorder_torch_close, R.string.video_recorder_torch);
        mSettingItemTorch.setOnClickListener(v -> {
            boolean isFlashOn = mRecordInfo.isFlashOn.get();
            mRecordCore.toggleTorch(!isFlashOn);
        });
    }

    private void initBeautyView() {
        if (!VideoRecorderConfigInternal.getInstance().isSupportRecordBeauty() || !isSupportAdvanceFunction()) {
            return;
        }

        SettingItemViewHolder mBeautySetting = addSettingItem(R.drawable.video_recorder_beauty, R.string.video_recorder_beauty);
        mBeautySetting.setOnClickListener(view -> {
            createBeautyPanelViewIfNeed();
            mBeautyPanelView.setVisibility(!mRecordInfo.isShowBeautyView.get() ? VISIBLE : INVISIBLE);
        });

        if (mRecordInfo.beautyInfo == null) {
            mRecordInfo.beautyInfo = BeautyInfo.CreateDefaultBeautyInfo();
        }

        mBeautyPanelViewContainer = findViewById(R.id.rl_beauty_panel_view_container);
        mBeautyPanelViewContainer.removeAllViews();
    }

    private void createBeautyPanelViewIfNeed() {
        if (mBeautyPanelView == null) {
            mBeautyPanelView = new BeautyPanelView(getContext(), mRecordCore, mRecordInfo);
        }
        if (mBeautyPanelViewContainer.getChildCount() == 0) {
            mBeautyPanelViewContainer.addView(mBeautyPanelView, new LayoutParams(MATCH_PARENT, WRAP_CONTENT));
        }
    }

    private void initScrollBeautyFilterView() {
        if (!VideoRecorderConfigInternal.getInstance().isSupportRecordScrollFilter() || !isSupportAdvanceFunction()) {
            return;
        }

        if (mRecordInfo.beautyInfo == null) {
            mRecordInfo.beautyInfo = BeautyInfo.CreateDefaultBeautyInfo();
        }

        if (mBeautyFilterScrollView == null) {
            mBeautyFilterScrollView = new BeautyFilterScrollView(mContext, mRecordCore, mRecordInfo.beautyInfo);
        }

        mScrollFilterViewContainer = findViewById(R.id.rl_beauty_filter_scroll_view_container);
        mScrollFilterViewContainer.removeAllViews();
        LayoutParams layoutParams =
                new LayoutParams(MATCH_PARENT,
                        MATCH_PARENT);
        layoutParams.leftMargin = (int) VideoRecorderResourceUtils.spToPx(mContext, SCROLL_FILTER_RIGHT_LEFT_MARGIN_SP);
        layoutParams.rightMargin = (int) VideoRecorderResourceUtils.spToPx(mContext, SCROLL_FILTER_RIGHT_LEFT_MARGIN_SP);
        mScrollFilterViewContainer.addView(mBeautyFilterScrollView, layoutParams);
        mBeautyFilterScrollView.setOnClickListener(v -> {
            if (mBeautyPanelView != null) {
                mBeautyPanelView.setVisibility(GONE);
            }
        });
    }

    private void initAspectView() {
        if (!VideoRecorderConfigInternal.getInstance().isSupportRecordAspect() || !isSupportAdvanceFunction()) {
            return;
        }

        if (mAspectView == null) {
            mAspectView = new RecordAspectView(getContext(), mRecordCore, mRecordInfo);
        }

        LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT);
        layoutParams.bottomMargin = VideoRecorderResourceUtils.dip2px(mContext, SETTING_ITEM_VIEW_BOTTOM_MARGIN_SP);
        layoutParams.gravity = Gravity.CENTER;
        mLayoutSetting.addView(mAspectView,layoutParams);
    }

    private SettingItemViewHolder addSettingItem(int iconResId, int titleResId) {
        View view = LayoutInflater.from(mContext)
                .inflate(R.layout.video_recorder_setting_item_view, this, false);
        SettingItemViewHolder settingItemViewHolder = new SettingItemViewHolder(view);
        settingItemViewHolder.setIconRes(iconResId);
        settingItemViewHolder.setTitle(titleResId);
        LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT);
        layoutParams.bottomMargin = VideoRecorderResourceUtils.dip2px(mContext, SETTING_ITEM_VIEW_BOTTOM_MARGIN_SP);
        layoutParams.gravity = Gravity.CENTER;
        mLayoutSetting.addView(view,layoutParams);
        return settingItemViewHolder;
    }

    private void addObserver() {
        mRecordInfo.isFrontCamera.observe(flashStatusObserver);
        mRecordInfo.isFlashOn.observe(flashStatusObserver);
    }

    private void removeObserver() {
        mRecordInfo.isFrontCamera.removeObserver(flashStatusObserver);
        mRecordInfo.isFlashOn.removeObserver(flashStatusObserver);
    }

    private boolean isSupportAdvanceFunction() {
        if (isAppDebuggable(getContext())) {
            return true;
        }

        return VideoRecorderSignatureChecker.getInstance().getSetSignatureResult() == ResultCode.SUCCESS
                && UGCReflectVideoRecorderCore.isAvailable();
    }

    static class SettingItemViewHolder{
        private final View mRootView;
        private final ImageView mIcon;
        private final TextView mTitle;

        public SettingItemViewHolder(View rootView) {
            mRootView = rootView;
            mIcon = mRootView.findViewById(R.id.icon);
            mTitle = mRootView.findViewById(R.id.title);
        }

        public void setIconRes(int iconResId) {
            mIcon.setBackgroundResource(iconResId);
        }

        public void setTitle(int titleResId) {
            mTitle.setText(VideoRecorderResourceUtils.getString(titleResId));
        }

        public void setOnClickListener(OnClickListener onClickListener) {
            mRootView.setOnClickListener(onClickListener);
        }

        public void setClickable(boolean clickable) {
            mRootView.setClickable(clickable);
        }
    }
}

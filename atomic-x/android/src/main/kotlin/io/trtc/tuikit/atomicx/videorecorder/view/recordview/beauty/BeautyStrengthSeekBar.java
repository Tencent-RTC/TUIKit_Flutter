package io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty;


import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.view.View;
import io.trtc.tuikit.atomicx.R;
import io.trtc.tuikit.atomicx.videorecorder.config.VideoRecorderConfigInternal;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderResourceUtils;

public class BeautyStrengthSeekBar extends androidx.appcompat.widget.AppCompatSeekBar {

    static final int SLIDE_SIZE_DP = 24;
    static final int SLIDE_INNER_RING_SIZE_DP = 10;
    static final int INDICATOR_WIDTH_DP = 30;
    static final int INDICATOR_HEIGHT_DP = 30;
    static final int THUMB_SPACING = 4;
    static final int TEXT_SIZE_SP = 12;
    static final int LINE_WIDTH_DP = 4;

    private final Context mContext;
    private Paint mPaint;

    private Drawable mSlideInnerRingDrawable;
    private Drawable mSlideDrawable;
    private Drawable mIndicatorDrawable;

    private int mSlideInnerRingSize;
    private int mSlideSize;
    private int mIndicatorWidth;
    private int mIndicatorHeight;
    private int mSlideSpacing;

    public BeautyStrengthSeekBar(Context context) {
        this(context, null);
    }

    public BeautyStrengthSeekBar(Context context, AttributeSet attrs) {
        this(context, attrs, android.R.attr.seekBarStyle);
    }

    public BeautyStrengthSeekBar(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        mContext = context;
        init();
    }

    private void init() {
        mSlideInnerRingDrawable = VideoRecorderResourceUtils
                .getDrawable(mContext, R.drawable.video_recorder_rebuild_seekbar_progress_thumb,
                        VideoRecorderConfigInternal.getInstance().getThemeColor());

        mSlideDrawable = VideoRecorderResourceUtils.getDrawable(R.drawable.video_recorder_rebuild_seekbar_progress_thumb);
        mIndicatorDrawable = VideoRecorderResourceUtils.getDrawable(R.drawable.video_recorder_beauty_filter_strength_seek_indicator);

        mPaint = new Paint();
        mPaint.setColor(Color.BLACK);
        mPaint.setAntiAlias(true);
        mPaint.setStyle(Paint.Style.FILL);
        mPaint.setTextSize(VideoRecorderResourceUtils.spToPx(mContext, TEXT_SIZE_SP));
        mPaint.setStrokeWidth(VideoRecorderResourceUtils.dip2px(mContext, LINE_WIDTH_DP));

        mSlideInnerRingSize = VideoRecorderResourceUtils.dip2px(getContext(), SLIDE_INNER_RING_SIZE_DP);
        mSlideSize = VideoRecorderResourceUtils.dip2px(getContext(), SLIDE_SIZE_DP);
        mIndicatorWidth = VideoRecorderResourceUtils.dip2px(getContext(), INDICATOR_WIDTH_DP);
        mIndicatorHeight = VideoRecorderResourceUtils.dip2px(getContext(), INDICATOR_HEIGHT_DP);
        mSlideSpacing = VideoRecorderResourceUtils.dip2px(getContext(), THUMB_SPACING);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
    }

    @Override
    protected synchronized void onDraw(Canvas canvas) {
        float progressPercent = getProgress() * 1.0f / getMax();
        int centerX = (int) (progressPercent * (getWidth() - mSlideSize)) + mSlideSize / 2;

        if (getResources().getConfiguration().getLayoutDirection() == View.LAYOUT_DIRECTION_RTL) {
            centerX = getWidth() - centerX;
        }
        centerX = Math.min(centerX, getWidth());
        drawProcessIndicator(canvas, centerX);
        drawProcessLine(canvas, centerX);
        drawSlide(canvas, centerX);
    }

    private void drawProcessIndicator(Canvas canvas, int centerX) {
        int halfIndicatorWidth = mIndicatorWidth / 2;
        int indicatorTop = 0;
        mIndicatorDrawable.setBounds(centerX - halfIndicatorWidth, indicatorTop, centerX + halfIndicatorWidth,
                indicatorTop + mIndicatorHeight);
        mIndicatorDrawable.draw(canvas);
        mPaint.setColor(Color.BLACK);
        String process = Math.min(getProgress() * 10 / getMax(), 9) + "";
        canvas.drawText(process, centerX - VideoRecorderResourceUtils.spToPx(mContext, 4),
                indicatorTop + VideoRecorderResourceUtils.dip2px(mContext, 20), mPaint);
    }

    private void drawProcessLine(Canvas canvas, int centerX) {
        int halfSlideWidth = mSlideSize / 2;
        int lineTop = mIndicatorHeight + mSlideSpacing + mSlideSize / 2;
        mPaint.setColor(VideoRecorderConfigInternal.getInstance().getThemeColor());
        canvas.drawLine(halfSlideWidth, lineTop, centerX, lineTop, mPaint);
        mPaint.setColor(Color.WHITE);
        canvas.drawLine(centerX, lineTop, getWidth() - halfSlideWidth, lineTop, mPaint);
    }

    private void drawSlide(Canvas canvas, int centerX) {
        int halfSlideSize = mSlideSize / 2;
        int slideTop = mIndicatorHeight + mSlideSpacing;
        mSlideDrawable.setBounds(centerX - halfSlideSize, slideTop, centerX + halfSlideSize,
                slideTop + mSlideSize);
        mSlideDrawable.draw(canvas);

        int halfSlideInnerRingSize = mSlideInnerRingSize / 2;
        int slideInnerRingTop = slideTop + (mSlideSize - mSlideInnerRingSize) / 2;
        mSlideInnerRingDrawable
                .setBounds(centerX - halfSlideInnerRingSize, slideInnerRingTop, centerX + halfSlideInnerRingSize,
                        slideInnerRingTop + mSlideInnerRingSize);
        mSlideInnerRingDrawable.draw(canvas);
    }

    @SuppressLint("MissingSuperCall")
    @Override
    protected void drawableStateChanged() {
        invalidate();
    }

    @SuppressLint("MissingSuperCall")
    @Override
    public void jumpDrawablesToCurrentState() {
        invalidate();
    }
}


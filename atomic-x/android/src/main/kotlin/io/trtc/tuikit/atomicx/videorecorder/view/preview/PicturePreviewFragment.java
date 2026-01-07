package io.trtc.tuikit.atomicx.videorecorder.view.preview;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import com.bumptech.glide.Glide;
import io.trtc.tuikit.atomicx.R;
import io.trtc.tuikit.atomicx.videorecorder.config.VideoRecorderConstants;
import io.trtc.tuikit.atomicx.videorecorder.view.preview.PreviewCommonCtrlView.CommonMediaEditListener;
import io.trtc.tuikit.atomicx.videorecorder.view.preview.PreviewCommonCtrlView.EditType;

public class PicturePreviewFragment extends Fragment {

    private final String TAG = PicturePreviewFragment.class.getSimpleName() + "_" + hashCode();
    private final Context mContext;

    private View mRootView;
    private String mPictureFilePath;
    private Bitmap mCurrentBitmap;
    private Bitmap mOriginBitmap;
    private ImageView mImageView;
    private PreviewCommonCtrlView mEditCommonCtrlView;
    private boolean mIsRecordFile = true;

    public PicturePreviewFragment(Context context) {
        mContext = context;
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        Log.i(TAG, "onCreate");
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        Log.i(TAG, "onCreateView");
        mRootView = inflater.inflate(R.layout.video_recorder_preview_picture_fragment, container, false);
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
    }

    public void initView() {
        initExternalParameters();

        mEditCommonCtrlView = new PreviewCommonCtrlView(mContext, EditType.PHOTO, mIsRecordFile);
        ((RelativeLayout) mRootView.findViewById(R.id.edit_common_ctrl_view_container))
                .addView(mEditCommonCtrlView, new RelativeLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT));

        Log.i(TAG, "preview picture. file path = " + mPictureFilePath);
        mOriginBitmap = BitmapFactory.decodeFile(mPictureFilePath);
        mCurrentBitmap = mOriginBitmap;
        if (mCurrentBitmap == null) {
            Log.e(TAG, "decode bitmap fail");
            return;
        }

        mImageView = new ImageView(mContext);
        mEditCommonCtrlView.setMediaView(mImageView);
        mEditCommonCtrlView.setMediaAspectRatio(mCurrentBitmap.getWidth() * 1.0f / mCurrentBitmap.getHeight());
        previewPicture(0);

        mEditCommonCtrlView.setCommonMediaEditListener(new CommonMediaEditListener() {
            @Override
            public void onGenerateMedia() {
                onGeneratePicture();
            }

            @Override
            public void onCancelEdit() {
                onCancelGeneratePicture();
            }
        });
    }


    private void previewPicture(float rotation) {
        if (mImageView == null || mCurrentBitmap == null) {
            return;
        }
        Log.i(TAG, "previewPicture rotation : " + rotation);
        Glide.with(mContext).load(mCurrentBitmap).into(mImageView);
    }

    private void onGeneratePicture() {
        finishEdit();
    }

    private void onCancelGeneratePicture() {
        ((AppCompatActivity) mContext).getSupportFragmentManager().popBackStack();
    }

    private void finishEdit() {
        Log.i(TAG, "finish edit. path = " + mPictureFilePath);
        Intent resultIntent = new Intent();
        if (mPictureFilePath != null) {
            resultIntent.putExtra(VideoRecorderConstants.PARAM_NAME_EDITED_FILE_PATH, mPictureFilePath);
            resultIntent.putExtra(VideoRecorderConstants.PARAM_NAME_RECORD_TYPE, VideoRecorderConstants.RECORD_TYPE_PHOTO);
        }
        ((Activity) mContext).setResult(Activity.RESULT_OK, resultIntent);
        ((Activity) mContext).finish();
    }

    private void initExternalParameters() {
        Bundle bundle = getArguments();
        if (bundle == null) {
            return;
        }
        mPictureFilePath = bundle.getString(VideoRecorderConstants.PARAM_NAME_EDIT_FILE_PATH);
        mIsRecordFile = bundle.getBoolean(VideoRecorderConstants.PARAM_NAME_IS_RECODE_FILE, false);
    }
}

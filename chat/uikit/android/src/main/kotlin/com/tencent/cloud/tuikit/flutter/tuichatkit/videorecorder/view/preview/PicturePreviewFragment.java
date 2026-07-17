package com.tencent.cloud.tuikit.flutter.tuichatkit.videorecorder.view.preview;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import com.tencent.cloud.tuikit.flutter.tuichatkit.videorecorder.config.VideoRecorderConstants;
import io.trtc.tuikit.albumpickercore.api.ImageEditListener;
import io.trtc.tuikit.albumpickercore.api.ImageEditView;
import java.io.File;
import java.io.FileOutputStream;

public class PicturePreviewFragment extends Fragment {

    private final String TAG = PicturePreviewFragment.class.getSimpleName() + "_" + hashCode();
    private static final int EDITED_IMAGE_QUALITY = 90;

    private final Context mContext;

    private String mPictureFilePath;
    private ImageEditView mImageEditView;

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
        initExternalParameters();

        Log.i(TAG, "preview picture. file path = " + mPictureFilePath);
        Bitmap sourceBitmap = decodeBitmapWithExif(mPictureFilePath);
        if (sourceBitmap == null) {
            Log.e(TAG, "decode bitmap fail");
            FrameLayout placeholder = new FrameLayout(mContext);
            placeholder.post(this::onEditCancel);
            return placeholder;
        }

        mImageEditView = new ImageEditView(mContext, sourceBitmap, new ImageEditListener() {
            @Override
            public void onEditCompleted(@NonNull Bitmap editedBitmap) {
                onEditConfirmed(editedBitmap);
            }

            @Override
            public void onEditCancelled() {
                onEditCancel();
            }
        });
        return mImageEditView;
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        registerBackPressedHandler();
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

    private void registerBackPressedHandler() {
        OnBackPressedCallback callback = new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                if (mImageEditView != null && mImageEditView.onBackPressed()) {
                    return;
                }
                setEnabled(false);
                requireActivity().getOnBackPressedDispatcher().onBackPressed();
            }
        };
        requireActivity().getOnBackPressedDispatcher().addCallback(getViewLifecycleOwner(), callback);
    }

    private void onEditConfirmed(Bitmap editedBitmap) {
        String editedPath = saveBitmapToFile(editedBitmap);
        if (editedPath == null) {
            Log.e(TAG, "save edited bitmap fail, fallback to origin path");
            editedPath = mPictureFilePath;
        }
        finishEdit(editedPath);
    }

    private void onEditCancel() {
        ((AppCompatActivity) mContext).getSupportFragmentManager().popBackStack();
    }

    private void finishEdit(String editedFilePath) {
        Log.i(TAG, "finish edit. path = " + editedFilePath);
        Intent resultIntent = new Intent();
        if (editedFilePath != null) {
            resultIntent.putExtra(VideoRecorderConstants.PARAM_NAME_EDITED_FILE_PATH, editedFilePath);
            resultIntent.putExtra(VideoRecorderConstants.PARAM_NAME_RECORD_TYPE, VideoRecorderConstants.RECORD_TYPE_PHOTO);
        }
        ((Activity) mContext).setResult(Activity.RESULT_OK, resultIntent);
        ((Activity) mContext).finish();
    }

    private Bitmap decodeBitmapWithExif(String filePath) {
        if (filePath == null || filePath.isEmpty()) {
            return null;
        }
        Bitmap bitmap = BitmapFactory.decodeFile(filePath);
        if (bitmap == null) {
            return null;
        }
        return applyExifOrientation(bitmap, readExifOrientation(filePath));
    }

    private int readExifOrientation(String filePath) {
        try {
            ExifInterface exif = new ExifInterface(filePath);
            return exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
        } catch (Exception e) {
            Log.e(TAG, "read exif orientation fail, " + e);
            return ExifInterface.ORIENTATION_NORMAL;
        }
    }

    private Bitmap applyExifOrientation(Bitmap bitmap, int orientation) {
        Matrix matrix = new Matrix();
        switch (orientation) {
            case ExifInterface.ORIENTATION_ROTATE_90:
                matrix.postRotate(90);
                break;
            case ExifInterface.ORIENTATION_ROTATE_180:
                matrix.postRotate(180);
                break;
            case ExifInterface.ORIENTATION_ROTATE_270:
                matrix.postRotate(270);
                break;
            case ExifInterface.ORIENTATION_FLIP_HORIZONTAL:
                matrix.postScale(-1, 1);
                break;
            case ExifInterface.ORIENTATION_FLIP_VERTICAL:
                matrix.postScale(1, -1);
                break;
            case ExifInterface.ORIENTATION_TRANSPOSE:
                matrix.postRotate(90);
                matrix.postScale(-1, 1);
                break;
            case ExifInterface.ORIENTATION_TRANSVERSE:
                matrix.postRotate(270);
                matrix.postScale(-1, 1);
                break;
            default:
                return bitmap;
        }
        return createRotatedBitmap(bitmap, matrix);
    }

    private Bitmap createRotatedBitmap(Bitmap bitmap, Matrix matrix) {
        try {
            Bitmap rotated = Bitmap.createBitmap(
                    bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
            if (rotated != bitmap) {
                bitmap.recycle();
            }
            return rotated;
        } catch (OutOfMemoryError e) {
            Log.e(TAG, "apply exif orientation oom, " + e);
            return bitmap;
        }
    }

    @Nullable
    private String saveBitmapToFile(Bitmap bitmap) {
        if (bitmap == null) {
            return null;
        }
        File outputFile = new File(mContext.getCacheDir(),
                "video_recorder_edited_" + System.currentTimeMillis() + ".jpg");
        FileOutputStream outputStream = null;
        try {
            outputStream = new FileOutputStream(outputFile);
            bitmap.compress(Bitmap.CompressFormat.JPEG, EDITED_IMAGE_QUALITY, outputStream);
        } catch (Throwable e) {
            Log.e(TAG, "save edited bitmap fail, " + e);
            return null;
        } finally {
            if (outputStream != null) {
                try {
                    outputStream.close();
                } catch (Exception e) {
                    Log.e(TAG, "close edited bitmap file fail, " + e);
                }
            }
        }
        return outputFile.getAbsolutePath();
    }

    private void initExternalParameters() {
        Bundle bundle = getArguments();
        if (bundle == null) {
            return;
        }
        mPictureFilePath = bundle.getString(VideoRecorderConstants.PARAM_NAME_EDIT_FILE_PATH);
    }
}

package io.trtc.tuikit.atomicx.videorecorder.core;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.ImageFormat;
import android.graphics.Matrix;
import android.hardware.camera2.CameraDevice.StateCallback;
import android.hardware.camera2.TotalCaptureResult;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.media.Image;
import android.media.ImageReader;
import android.media.MediaRecorder;
import android.os.Looper;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.os.Handler;
import android.os.HandlerThread;
import android.util.Log;
import android.util.Size;
import android.view.Surface;
import android.view.TextureView;

import android.view.TextureView.SurfaceTextureListener;
import androidx.annotation.NonNull;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.Objects;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

public class SystemVideoRecorderCore implements IVideoRecorderCoreInterface {
    private static final String TAG = "VideoRecorderSystem";
    private static final int DEFAULT_PREVIEW_WIDTH = 1080;
    private static final int DEFAULT_PREVIEW_HEIGHT = 1920;

    private final Context mContext;
    private MediaRecorder mMediaRecorder;
    private ImageReader mImageReader;
    private CameraDevice mCameraDevice;
    private CameraCaptureSession mCaptureSession;
    private CaptureRequest.Builder mPreviewRequestBuilder;

    private Handler mCameraBackgroundHandler;
    private HandlerThread mCameraBackgroundThread;
    private Handler mWorkHandler;
    private HandlerThread mWorkThread;
    private Handler mMainHandler;

    private SurfaceTexture mPreviewSurface;
    private Surface mSurface;

    private IVideoRecordListener mRecordListener;
    private String mVideoPath;
    private VideoRecordCustomConfig mConfig;

    private boolean mIsRecording = false;
    private boolean mIsFrontCamera = false;
    private boolean mTorchEnabled = false;
    private long mStartRecordTime;
    private int mCameraAngle;

    private final Semaphore mCameraOpenCloseLock = new Semaphore(1);

    private final SurfaceTextureListener mSurfaceTexturelistener = new SurfaceTextureListener() {
        @Override
        public void onSurfaceTextureAvailable(@NonNull SurfaceTexture surfaceTexture, int i, int i1) {
            runInWorkThread(() -> {
                mPreviewSurface = surfaceTexture;
                startCameraPreview();
            });
        }

        @Override
        public void onSurfaceTextureSizeChanged(@NonNull SurfaceTexture surfaceTexture, int i, int i1) {
        }

        @Override
        public boolean onSurfaceTextureDestroyed(@NonNull SurfaceTexture surfaceTexture) {
            return false;
        }

        @Override
        public void onSurfaceTextureUpdated(@NonNull SurfaceTexture surfaceTexture) {
        }
    };

    private final StateCallback mCameraStateCallback = new StateCallback() {
        @Override
        public void onOpened(@NonNull CameraDevice camera) {
            runInWorkThread(()-> {
                Log.i(TAG, "camera device state callback on opened");
                mCameraDevice = camera;
                mCameraOpenCloseLock.release();
                createCameraPreviewSession();
            });
        }

        @Override
        public void onDisconnected(@NonNull CameraDevice camera) {
            runInWorkThread(() -> {
                Log.i(TAG, "camera device state callback on disconnected");
                mCameraOpenCloseLock.release();
                stopCameraPreview();
            });
        }

        @Override
        public void onError(@NonNull CameraDevice camera, int error) {
            runInWorkThread( () -> {
                Log.i(TAG, "camera device state callback on error");
                mCameraOpenCloseLock.release();
                stopCameraPreview();
            });
        }
    };

    public SystemVideoRecorderCore(Context context) {
        this.mContext = context.getApplicationContext();
    }

    @Override
    public void setVideoRecordListener(IVideoRecordListener listener) {
        runInWorkThread(()-> this.mRecordListener = listener);
    }

    @Override
    public void startCameraCustomPreview(VideoRecordCustomConfig config, TextureView textureView) {
        if (textureView == null) {
            Log.i(TAG, "surfaceView view is null or surfaceView holder is null");
            return;
        }

        runInWorkThread(()-> {
            Log.i(TAG,"start camera custom preview");
            mConfig = config;
            mIsFrontCamera = config.isFront;
            mPreviewSurface = textureView.getSurfaceTexture();
            if (textureView.isAvailable() && mPreviewSurface != null) {
                startCameraPreview();
            } else {
                textureView.setSurfaceTextureListener(mSurfaceTexturelistener);
            }
        });
    }

    private void startCameraPreview() {
        Log.i(TAG,"start camera preview");
        try {
            startBackgroundThread();
            CameraManager manager = (CameraManager) mContext.getSystemService(Context.CAMERA_SERVICE);
            String cameraId = getCameraId(mIsFrontCamera);
            if (cameraId == null) {
                Log.e(TAG, "start camera preview fail. camera id is null");
                return;
            }

            if (!mCameraOpenCloseLock.tryAcquire(2500, TimeUnit.MILLISECONDS)) {
                Log.e(TAG, "Getting camera access permission timed out");
                throw new RuntimeException("Getting camera access permission timed out");
            }

            manager.openCamera(cameraId, mCameraStateCallback, mCameraBackgroundHandler);
        } catch (Throwable throwable) {
            Log.e(TAG, "Camera access abnormality", throwable);
        }
    }

    private void createCameraPreviewSession() {
        Log.i(TAG,"create camera preview session");
        try {
            if (mCameraDevice == null) {
                return;
            }

            mCameraAngle = getCameraAngle();
            Size size = getOptimalSize(SurfaceTexture.class, new Size(DEFAULT_PREVIEW_WIDTH, DEFAULT_PREVIEW_HEIGHT));
            mPreviewSurface.setDefaultBufferSize(size.getWidth(), size.getHeight());
            mImageReader = ImageReader.newInstance(size.getWidth(),  size.getHeight(), ImageFormat.JPEG, 1);

            mPreviewRequestBuilder = mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
            mSurface = new Surface(mPreviewSurface);
            mPreviewRequestBuilder.addTarget(mSurface);

            mCameraDevice.createCaptureSession(Arrays.asList(mImageReader.getSurface(), mSurface),
                    new CameraCaptureSession.StateCallback() {
                        @Override
                        public void onConfigured(@NonNull CameraCaptureSession session) {
                            runInWorkThread(() -> onPreviewSessionConfigured(session));
                        }

                        @Override
                        public void onConfigureFailed(@NonNull CameraCaptureSession session) {
                            Log.e(TAG, "camera device create capture session on configure failed.");
                        }
                    }, mCameraBackgroundHandler);
        } catch (CameraAccessException e) {
            Log.e(TAG, "camera access exception.", e);
        }
    }

    private void onPreviewSessionConfigured(@NonNull CameraCaptureSession session) {
        Log.i(TAG,"create capture session on configured");
        if (mCameraDevice == null) {
            return;
        }

        mCaptureSession = session;
        try {
            configPreviewSetting();
            session.setRepeatingRequest(mPreviewRequestBuilder.build(), null,
                    mCameraBackgroundHandler);
        } catch (CameraAccessException e) {
            Log.e(TAG, "camera access exception.", e);
        }
    }

    private void configPreviewSetting() {
        mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_MODE,
                CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_VIDEO);

        mPreviewRequestBuilder.set(CaptureRequest.FLASH_MODE,
                mTorchEnabled ? CaptureRequest.FLASH_MODE_TORCH : CaptureRequest.FLASH_MODE_OFF);
    }

    @Override
    public void stopCameraPreview() {
        runInWorkThread(()->{
            Log.i(TAG,"stop camera preview");
            try {
                if (mImageReader != null) {
                    mImageReader.close();
                    mImageReader = null;
                }

                if (mCaptureSession != null) {
                    mCaptureSession.close();
                    mCaptureSession = null;
                }

                if (mCameraDevice != null) {
                    mCameraDevice.close();
                    mCameraDevice = null;
                }
            } finally {
                stopCameraBackgroundThread();
            }
        });
    }

    @Override
    public int startRecord(String videoFilePath) {
        Log.i(TAG,"start record. video file path :" + videoFilePath);
        if (mIsRecording) {
            Log.i(TAG, "start record fail. it is recording");
            return VideoRecordCoreConstant.START_RECORD_ERR_IS_IN_RECORDING;
        }

        runInWorkThread(()->{
            if (mCameraDevice == null || mCaptureSession == null) {
                Log.i(TAG, "start record fail. cameraDevice or captureSession is null");
                notifyRecordComplete(VideoRecordCoreConstant.RECORD_RESULT_COMPOSE_INTERNAL_ERR,"","");
                return;
            }

            mVideoPath = videoFilePath;

            try {
                startRecord();
            } catch (Exception e) {
                Log.i(TAG, "start record exception. msg is ", e);
                notifyRecordComplete(VideoRecordCoreConstant.RECORD_RESULT_COMPOSE_INTERNAL_ERR,"","");
            }
        });

        return VideoRecordCoreConstant.START_RECORD_OK;
    }

    private void startRecord() throws Exception {
        Log.i(TAG,"start record");
        mIsRecording = true;

        mCaptureSession.close();
        mCaptureSession = null;

        prepareMediaRecorder();
        Surface recorderSurface = mMediaRecorder.getSurface();

        mPreviewRequestBuilder =
                mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
        mPreviewRequestBuilder.addTarget(mSurface);
        mPreviewRequestBuilder.addTarget(recorderSurface);

        mCameraDevice.createCaptureSession(Arrays.asList(mSurface, recorderSurface),
                new CameraCaptureSession.StateCallback() {
                    @Override
                    public void onConfigured(@NonNull CameraCaptureSession session) {
                        runInWorkThread(()-> onRecordSessionConfigured(session));
                    }

                    @Override
                    public void onConfigureFailed(@NonNull CameraCaptureSession session) {
                        Log.e(TAG, "start record but camera device create capture session configure failed" );
                        notifyRecordComplete(VideoRecordCoreConstant.RECORD_RESULT_COMPOSE_INTERNAL_ERR, "", "");
                    }
                }, mCameraBackgroundHandler);
    }

    private void prepareMediaRecorder() throws Exception {
        Log.i(TAG,"prepare media recorder");
        if (mMediaRecorder != null) {
            Log.i(TAG,"prepare media recorder, but media recorder object is not null");
            return;
        }

        mMediaRecorder = new MediaRecorder();
        configureMediaRecorder(mMediaRecorder);
        mMediaRecorder.setOnErrorListener(
                (mediaRecorder, i, i1) -> Log.i(TAG,"mediaRecorder onError i:" + i + " i1:" + i1));

        mMediaRecorder.setOnInfoListener(
                (mediaRecorder, i, i1) -> {
                    Log.i(TAG,"mediaRecorder onInfo i:" + i + " i1:" + i1);
                    if (i == MediaRecorder.MEDIA_RECORDER_INFO_MAX_DURATION_REACHED) {
                        stopRecord();
                    }
                });
        mMediaRecorder.prepare();
    }

    private void configureMediaRecorder(MediaRecorder recorder) {
        Log.i(TAG,"configure media recorder.");
        recorder.setAudioSource(MediaRecorder.AudioSource.MIC);
        recorder.setVideoSource(MediaRecorder.VideoSource.SURFACE);
        recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
        recorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264);
        recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);

        Size recordSize = getOptimalSize(MediaRecorder.class, getSizeFromResolution(mConfig.videoResolution));
        recorder.setVideoSize(recordSize.getWidth(), recordSize.getHeight());
        recorder.setOrientationHint(mCameraAngle);
        recorder.setVideoFrameRate(mConfig.videoFps);
        recorder.setVideoEncodingBitRate(mConfig.videoBitrate * 1024);
        recorder.setOutputFile(mVideoPath);
        recorder.setMaxDuration(mConfig.maxDuration);
    }

    private void onRecordSessionConfigured(@NonNull CameraCaptureSession session) {
        Log.i(TAG,"on record session configured.");
        mCaptureSession = session;
        try {
            Log.i(TAG,"record capture session onConfigured.");
            mMediaRecorder.start();
            mStartRecordTime = System.currentTimeMillis();
            configPreviewSetting();
            startProgressUpdates();

            mCaptureSession.setRepeatingRequest(mPreviewRequestBuilder.build(), null,
                    mCameraBackgroundHandler);
        } catch (Exception e) {
            Log.e(TAG, "start record but camera device create capture session exception", e);
            notifyRecordComplete(VideoRecordCoreConstant.RECORD_RESULT_COMPOSE_INTERNAL_ERR
                    , "", "");
        }
    }

    private void startProgressUpdates() {
        getMainHandler().postDelayed(() -> {
            if (mIsRecording && mRecordListener != null) {
                long elapsed = System.currentTimeMillis() - mStartRecordTime;
                mRecordListener.onRecordProgress(elapsed);
                startProgressUpdates();
            }
        }, 100);
    }

    @Override
    public int stopRecord() {
        Log.i(TAG,"stop record");
        if (!mIsRecording ) {
            return -1;
        }
        mIsRecording = false;

        runInWorkThread(()-> {
            if (mMediaRecorder == null) {
                return;
            }
            int retCode = VideoRecordCoreConstant.RECORD_RESULT_OK;
//            if (System.currentTimeMillis() - mStartRecordTime < mConfig.minDuration) {
//                retCode = VideoRecordCoreConstant.RECORD_RESULT_OK_LESS_THAN_MINDURATION;
//            }

            stopCameraPreview();
            mMediaRecorder.stop();
            mMediaRecorder.release();
            mMediaRecorder = null;
            Log.i(TAG,"stop record finish");
            notifyRecordComplete(retCode, "", mVideoPath);
        });
        return 1;
    }

    @Override
    public void release() {
        runInWorkThread( ()-> {
            stopRecord();
            stopCameraPreview();
        });
        stopWorkThread();
    }

    @Override
    public boolean setMicVolume(float volume) {
        Log.w(TAG, "system video recorder do not support set mic volume.");
        return true;
    }

    @Override
    public boolean switchCamera(boolean isFront) {
        Log.i(TAG,"switch camera is front:" + isFront);
        if (mIsRecording) {
            return false;
        }

        runInWorkThread( ()-> {
            mIsFrontCamera = isFront;
            stopCameraPreview();
            startCameraPreview();
        });
        return true;
    }

    @Override
    public void snapshot(ISnapshotListener listener, String path) {
        Log.i(TAG,"snapshot");
        runInWorkThread(()-> snapshotInternal(listener, path));
    }

    private void snapshotInternal(ISnapshotListener listener, String path) {
        if (mCameraDevice == null || mCaptureSession == null) {
            Log.i(TAG, "snapshot fail. cameraDevice or captureSession is null");
            return;
        }

        mImageReader.setOnImageAvailableListener(imageReader ->
                runInWorkThread(()-> onSnapshotImageAvailable(imageReader, listener, path)), mCameraBackgroundHandler);

        CameraCaptureSession.CaptureCallback captureCallback =
                new CameraCaptureSession.CaptureCallback() {
                    @Override
                    public void onCaptureCompleted(@NonNull CameraCaptureSession session,
                            @NonNull CaptureRequest request,
                            @NonNull TotalCaptureResult result) {
                        runInWorkThread(()-> onSnapshotCaptureCompleted());
                    }
                };

        try {
            CaptureRequest.Builder captureBuilder =
                    mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);

            Surface surface = mImageReader.getSurface();
            if (!surface.isValid()) {
                Log.e(TAG,"surface is invalid");
            }

            captureBuilder.addTarget(surface);
            captureBuilder.set(CaptureRequest.CONTROL_AF_MODE,
                    CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_VIDEO);
            captureBuilder.set(CaptureRequest.JPEG_ORIENTATION, mCameraAngle);
            mCaptureSession.stopRepeating();
            mCaptureSession.capture(captureBuilder.build(), captureCallback, mCameraBackgroundHandler);
        } catch (CameraAccessException e) {
            Log.e(TAG, "snapshot fail", e);
        }
    }

    private void onSnapshotImageAvailable (ImageReader imageReader, ISnapshotListener listener, String path) {
        Log.i(TAG,"snapshot on image available ");
        try (Image image = imageReader.acquireNextImage()) {
            Boolean success = false;
            if (mIsFrontCamera) {
                Bitmap bitmap = imageToFlippedBitmap(image);
                if (bitmap != null) {
                    success = saveBitmapToJpg(bitmap, path);
                }
            } else {
                success = saveImage(image.getPlanes()[0].getBuffer(), path);
            }
            if (listener != null) {
                listener.onSnapshotCompleted(success);
            }
            mImageReader.setOnImageAvailableListener(null, mCameraBackgroundHandler);
        }
    }

    private static boolean saveBitmapToJpg(Bitmap bitmap, String filePath) {
        if (bitmap == null || filePath == null || filePath.isEmpty()) {
            return false;
        }

        FileOutputStream out = null;
        try {
            out = new FileOutputStream(filePath);
            boolean success = bitmap.compress(Bitmap.CompressFormat.JPEG, 95, out);
            out.flush();
            return success;
        } catch (Exception e) {
            Log.i(TAG,"save bitmap to jpg fail. exception msg : " + e);
            return false;
        } finally {
            try {
                if (out != null) {
                    out.close();
                }
            } catch (IOException e) {
                Log.i(TAG,"save bitmap to jpg fail. exception msg : " + e);
            }
        }
    }

    private void onSnapshotCaptureCompleted () {
        Log.i(TAG,"snapshot onCapture Completed");
        try {
            configPreviewSetting();
            mCaptureSession.setRepeatingRequest(
                    mPreviewRequestBuilder.build(), null, mCameraBackgroundHandler);
        } catch (CameraAccessException e) {
            Log.e(TAG, "Failed to restore preview from snapshot", e);
        }
    }

    private boolean saveImage(ByteBuffer buffer, String path) {
        byte[] bytes = new byte[buffer.remaining()];
        buffer.get(bytes);

        File file = new File(path);
        try (FileOutputStream output = new FileOutputStream(file)) {
            output.write(bytes);
        } catch (IOException e) {
            Log.e(TAG, "保存图片失败", e);
            return false;
        }
        return true;
    }

    @Override
    public boolean toggleTorch(boolean enable) {
        runInWorkThread(() -> {
            if (mCameraDevice == null || mCaptureSession == null) {
                mTorchEnabled = enable;
                return;
            }

            try {
                mPreviewRequestBuilder.set(CaptureRequest.FLASH_MODE,
                        enable ? CaptureRequest.FLASH_MODE_TORCH : CaptureRequest.FLASH_MODE_OFF);

                mCaptureSession.setRepeatingRequest(mPreviewRequestBuilder.build(), null, mCameraBackgroundHandler);
                mTorchEnabled = enable;
            } catch (Exception e) {
                Log.e(TAG, "toggle torch failed.", e);
            }
        });
        return  true;
    }

    @Override
    public void setAspectRatio(int displayType) {
        Log.w(TAG, "system video recorder do not support set aspect ratio");
    }

    @Override
    public void setFilter(Bitmap leftBitmap, float leftIntensity, Bitmap rightBitmap, float rightIntensity,
            float leftRatio) {
        Log.w(TAG, "system video recorder do not support set filter");
    }

    @Override
    public int getMaxZoom() {
        Log.w(TAG, "system video recorder do not support get max zoom");
        return 0;
    }

    @Override
    public boolean setZoom(int value) {
        Log.w(TAG, "system video recorder do not support set set zoom");
        return false;
    }

    @Override
    public void setFocusPosition(float eventX, float eventY) {
        Log.w(TAG, "system video recorder do not support set focus position");
    }

    @Override
    public void setVideoRenderMode(int renderMode) {
        Log.w(TAG, "system video recorder do not support set video render mode");
    }

    @Override
    public void setHomeOrientation(int homeOrientation) {
        Log.w(TAG, "system video recorder do not support set home orientation");
    }

    @Override
    public void setRenderRotation(int renderRotation) {
        Log.w(TAG, "system video recorder do not support set render rotation");
    }

    @Override
    public IBeautyManager getBeautyManager() {
        Log.w(TAG, "system video recorder do not support get beauty manager");
        return null;
    }

    @Override
    public void deleteAllParts() {
        Log.i(TAG, "system video recorder do not support delete all parts.");
    }

    private String getCameraId(boolean useFrontCamera) throws CameraAccessException {
        CameraManager manager = (CameraManager) mContext.getSystemService(Context.CAMERA_SERVICE);
        for (String cameraId : manager.getCameraIdList()) {
            CameraCharacteristics characteristics = manager.getCameraCharacteristics(cameraId);
            Integer facing = characteristics.get(CameraCharacteristics.LENS_FACING);
            if (useFrontCamera && facing != null && facing == CameraCharacteristics.LENS_FACING_FRONT) {
                return cameraId;
            } else if (!useFrontCamera && facing != null && facing == CameraCharacteristics.LENS_FACING_BACK) {
                return cameraId;
            }
        }
        return null;
    }

    private void startBackgroundThread() {
        if (mCameraBackgroundThread != null) {
            return;
        }

        mCameraBackgroundThread = new HandlerThread("CameraBackground");
        mCameraBackgroundThread.start();
        mCameraBackgroundHandler = new Handler(mCameraBackgroundThread.getLooper());
    }

    private void stopCameraBackgroundThread() {
        if (mCameraBackgroundThread == null) {
            return;
        }

        mCameraBackgroundThread.quitSafely();
        try {
            mCameraBackgroundThread.join();
            mCameraBackgroundThread = null;
            mCameraBackgroundHandler = null;
        } catch (InterruptedException e) {
            Log.e(TAG, "stop camera background thread fail.", e);
        }
    }

    private void notifyRecordComplete(int retCode, String descMsg, String videoPath) {
        if (mRecordListener == null) {
            return;
        }
        IVideoRecordListener listener = mRecordListener;

        getMainHandler().post(() -> {
            Log.i(TAG, "notify record complete. retCode:" + retCode
                    + " descMsg:" + descMsg + " videoPath:" + videoPath);
            VideoRecordResult recordResult = new VideoRecordResult();
            recordResult.retCode = retCode;
            recordResult.descMsg = descMsg;
            recordResult.videoPath = videoPath;
            listener.onRecordComplete(recordResult);
        });
    }

    private Size getOptimalSize(Class<?> type, Size exceptSize) {
        if (mCameraAngle == 90 || mCameraAngle == 270) {
            exceptSize = new Size (exceptSize.getHeight(), exceptSize.getWidth());
        }
        Log.i(TAG," type : " + type + " except size " + exceptSize + " camera angle : " + mCameraAngle);
        Size[] optionSizes = getOptionSizes(type);
        if (optionSizes == null) {
            return exceptSize;
        }

        float exceptAspectRatio = exceptSize.getWidth() * 1.0f / exceptSize.getHeight();
        Size optimalSize = null;
        float minAspectRatioDiff =  Float.MAX_VALUE;
        for(Size size : optionSizes) {
            if (size.getWidth() - exceptSize.getWidth() >  exceptSize.getWidth() * 0.05f) {
                continue;
            }

            if (size.getHeight() - exceptSize.getHeight() >  exceptSize.getHeight() * 0.05f) {
                continue;
            }

            float aspectRatio = size.getWidth() * 1.0f / size.getHeight();
            float diff = Math.abs(aspectRatio - exceptAspectRatio);
            if (diff < 0.05f) {
                optimalSize = size;
                break;
            }

            if (diff < minAspectRatioDiff) {
                minAspectRatioDiff = diff;
                optimalSize = size;
            }
        }

        if (optimalSize == null) {
            Log.i(TAG,"optimal size is null, so return except size");
            return exceptSize;
        }
        Log.i(TAG,"optimal size : " + optimalSize);
        return optimalSize;
    }

    private int getCameraAngle() {
        try {
            CameraManager manager = (CameraManager) mContext.getSystemService(Context.CAMERA_SERVICE);
            CameraCharacteristics characteristics = manager.getCameraCharacteristics(
                    Objects.requireNonNull(getCameraId(mIsFrontCamera)));
            return characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION).intValue();
        } catch (Exception e) {
            return 90;
        }
    }

    private Size[] getOptionSizes(Class<?> klass) {
        try {
            CameraManager manager = (CameraManager) mContext.getSystemService(Context.CAMERA_SERVICE);
            CameraCharacteristics characteristics = manager.getCameraCharacteristics(
                    Objects.requireNonNull(getCameraId(mIsFrontCamera)));
            StreamConfigurationMap map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
            return map != null ? map.getOutputSizes(klass) : null;
        } catch (Exception e) {
            return null;
        }
    }

    private Size getSizeFromResolution(int resolution) {
        switch (resolution) {
            case VideoRecordCoreConstant.VIDEO_RESOLUTION_360_640:
                return new Size(360, 640);
            case VideoRecordCoreConstant.VIDEO_RESOLUTION_480_640:
                return new Size(480, 640);
            case VideoRecordCoreConstant.VIDEO_RESOLUTION_540_960:
                return new Size(540, 960);
            case VideoRecordCoreConstant.VIDEO_RESOLUTION_720_1280:
                return new Size(720, 1280);
            case VideoRecordCoreConstant.VIDEO_RESOLUTION_1080_1920:
                return new Size(1080, 1920);
            default:
                return new Size(720, 1280);
        }
    }

    public Bitmap imageToFlippedBitmap(Image image) {
        Bitmap bitmap = imageToBitmap(image);
        if (bitmap == null) {
            return null;
        }
        Matrix matrix = new Matrix();
        matrix.preScale(-1.0f, 1.0f);
        Bitmap flippedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
        bitmap.recycle();
        return flippedBitmap;
    }

    private Bitmap imageToBitmap(Image image) {
        if (image == null) {
            return null;
        }

        ByteBuffer buffer = image.getPlanes()[0].getBuffer();
        byte[] bytes = new byte[buffer.remaining()];
        buffer.get(bytes);

        return BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
    }

    private void runInWorkThread(Runnable runnable) {
        if (runnable == null) {
            return;
        }

        if (mWorkThread == null) {
            mWorkThread = new HandlerThread("work thread");
            mWorkThread.start();
            mWorkHandler = new Handler(mWorkThread.getLooper());
        }

        if (Objects.requireNonNull(Looper.myLooper()).getThread().getId()
                == mWorkThread.getId()) {
            runnable.run();
        }  else {
            mWorkHandler.post(runnable);
        }
    }

    private void stopWorkThread() {
        if (mWorkThread != null) {
            mWorkThread.quitSafely();
            try {
                mWorkThread.join();
                mWorkThread = null;
                mWorkHandler = null;
            } catch (InterruptedException e) {
                Log.e(TAG, "stop work thread fail.", e);
            }
        }
    }

    private Handler getMainHandler() {
        if (mMainHandler == null) {
            mMainHandler = new Handler(Looper.getMainLooper());
        }
        return mMainHandler;
    }
}
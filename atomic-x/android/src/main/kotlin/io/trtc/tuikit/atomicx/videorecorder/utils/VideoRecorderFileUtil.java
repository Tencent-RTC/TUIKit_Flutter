package io.trtc.tuikit.atomicx.videorecorder.utils;

import android.os.Build;
import android.os.Environment;
import android.util.Log;
import com.tencent.qcloud.tuicore.ServiceInitializer;
import com.tencent.qcloud.tuicore.TUIConfig;
import com.tencent.qcloud.tuicore.util.TUIBuild;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Random;

public class VideoRecorderFileUtil {

    public static final String TAG = VideoRecorderFileUtil.class.getSimpleName();
    public static final String ASSET_FILE_PREFIX = "file:///asset/";

    public static boolean isFileExists(String path) {
        try {
            File file = new File(path);
            return file.exists() && file.isFile();
        } catch (Exception e) {
            return false;
        }
    }

    public static String readTextFromFile(String fileName) {
        if (fileName == null || fileName.isEmpty()) {
            return "";
        }

        boolean isAssetFile = fileName.startsWith(ASSET_FILE_PREFIX);

        StringBuilder sb = new StringBuilder();
        InputStream is = null;
        BufferedReader br = null;
        try {
            if (isAssetFile) {
                is = VideoRecorderResourceUtils.getContext().getAssets()
                        .open(fileName.substring(VideoRecorderFileUtil.ASSET_FILE_PREFIX.length()));
            } else {
                is = new FileInputStream(fileName);
            }
            br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8));
            String readLine;
            while ((readLine = br.readLine()) != null) {
                sb.append(readLine);
            }
        } catch (IOException e) {
            Log.i(TAG,"read text from file error:" + e);
        } finally {
            try {
                if (is != null) {
                    is.close();
                }
                if (br != null) {
                    br.close();
                }
            } catch (IOException e) {
                Log.i(TAG,"read text from file. close file error" + e);
            }
        }
        return sb.toString();
    }

    public static String generateRecodeFilePath(VideoRecodeFileType fileType) {
        String fileName = "";
        String suffix = "";
        switch (fileType) {
            case VIDEO_FILE:
                fileName = "video_recorder_";
                suffix = ".mp4";
                break;
            case PICTURE_FILE:
                fileName = "video_recorder_pic_";
                suffix = ".jpg";
                break;
        }

        if (TUIBuild.getVersionInt() < Build.VERSION_CODES.N) {
            File dir = new File(
                    Environment.getExternalStorageDirectory().getAbsolutePath() + File.separatorChar + TUIConfig
                            .getAppContext().getPackageName()
                            + TUIConfig.RECORD_DIR_SUFFIX);
            if (!dir.exists()) {
                dir.mkdirs();
            }
            return dir.getAbsolutePath() + File.separatorChar + fileName + System.nanoTime() + "_" + Math
                    .abs(new Random().nextInt()) + suffix;
        } else {
            String name = System.nanoTime() + "_" + Math.abs(new Random().nextInt());
            return TUIConfig.getRecordDir() + fileName + name + suffix;
        }
    }

    public enum VideoRecodeFileType {
        VIDEO_FILE,
        PICTURE_FILE
    }
}

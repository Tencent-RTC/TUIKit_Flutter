package io.trtc.tuikit.atomicx.videorecorder.core;

public class VideoRecordCoreConstant {
    public static final int VIDEO_RESOLUTION_360_640 = 0;        // 360×640     9:16
    public static final int VIDEO_RESOLUTION_480_640 = 1;        // 480×640
    public static final int VIDEO_RESOLUTION_540_960 = 2;        // 540×960     9:16
    public static final int VIDEO_RESOLUTION_720_1280 = 3;        // 720×1280    9:16
    public static final int VIDEO_RESOLUTION_1080_1920 = 4;        // 1080x1920    9:16


    public static final int VIDEO_ANGLE_HOME_RIGHT = 0;
    public static final int VIDEO_ANGLE_HOME_DOWN = 1;
    public static final int VIDEO_ANGLE_HOME_LEFT = 2;
    public static final int VIDEO_ANGLE_HOME_UP = 3;

    public static final int RENDER_ROTATION_PORTRAIT = 0;
    public static final int RENDER_ROTATION_LANDSCAPE = 270;

    public static final int VIDEO_ASPECT_RATIO_9_16 = 0;
    public static final int VIDEO_ASPECT_RATIO_3_4 = 1;
    public static final int VIDEO_ASPECT_RATIO_1_1 = 2;
    public static final int VIDEO_ASPECT_RATIO_16_9 = 3;
    public static final int VIDEO_ASPECT_RATIO_4_3 = 4;

    public static final int RECORD_PROFILE_DEFAULT = 0; // baseline
    public static final int RECORD_PROFILE_BASELINE = 1;
    public static final int RECORD_PROFILE_MAIN = 2;
    public static final int RECORD_PROFILE_HIGH = 3;

    public static final int RECORD_RESULT_OK = 0;        // 回调录制成功 或者 暂停（停止）接口返回成功                                                 pauseRecord和stopRecord接口返回值 或者 onRecordComplete回调值
    public static final int RECORD_RESULT_OK_LESS_THAN_MINDURATION = 1;        // 回调录制成功，时长小于最小值                                                             onRecordComplete回调值
    public static final int RECORD_RESULT_OK_REACHED_MAXDURATION = 2;        // 回调录制成功，时长达到最大值
    public static final int RECORD_RESULT_FAILED                    = -1;       // 回调录制失败。
    public static final int RECORD_RESULT_COMPOSE_INTERNAL_ERR      = -9;       // 回调合成失败，内部错误。

    public static final int START_RECORD_OK = 0;        // 开始录制
    public static final int START_RECORD_ERR_IS_IN_RECORDING = -1;       // 开始录制时存在未完成的任务，existing uncompleted record task
    public static final int START_RECORD_ERR_VIDEO_PATH_IS_EMPTY = -2;       // 开始录制时视频文件路径为空
    public static final int START_RECORD_ERR_API_IS_LOWER_THAN_18 = -3;       // 版本小于18
    public static final int START_RECORD_ERR_NOT_INIT = -4;       // 开始录制时还未初始化结束
    public static final int START_RECORD_ERR_LICENCE_VERIFICATION_FAILED = -5;       // licence校验失败
    public static final int START_RECORD_INTERNAL_ERROR = -6;       // licence校验失败


    public static final int START_RECORD_ERR_PARAMETER_ERROR = -6;       // 参数错误
    public static final int CAMERA_ACCESS_ABNORMALITY = -7; // 摄像头访问异常

    public static final int VIDEO_RENDER_MODE_FULL_FILL_SCREEN = 0;
    public static final int VIDEO_RENDER_MODE_ADJUST_RESOLUTION = 1;
}

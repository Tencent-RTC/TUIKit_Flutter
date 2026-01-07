// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

typedef NS_ENUM(NSInteger, VideoRecordCompressed) {
  VIDEO_COMPRESSED_360P = 0,
  VIDEO_COMPRESSED_480P = 1,
  VIDEO_COMPRESSED_540P = 2,
  VIDEO_COMPRESSED_720P = 3,
  VIDEO_COMPRESSED_1080P = 4,
};

typedef NS_ENUM(NSInteger, VideoRecordResolution) {
  VIDEO_RESOLUTION_360_640 = 0,
  VIDEO_RESOLUTION_540_960 = 1,
  VIDEO_RESOLUTION_720_1280 = 2,
  VIDEO_RESOLUTION_1080_1920 = 3,
};


typedef NS_ENUM(NSInteger, VideoRecordResultCode) {
  VIDEO_RECORD_RESULT_OK = 0,
  VIDEO_RECORD_RESULT_OK_INTERRUPT = 1,
  VIDEO_RECORD_RESULT_OK_UNREACH_MINDURATION = 2,
  VIDEO_RECORD_RESULT_OK_BEYOND_MAXDURATION = 3,
  VIDEO_RECORD_RESULT_FAILED = 1001,
};

typedef NS_ENUM(NSInteger, VideoRecordAspectRatio) {
  VIDEO_ASPECT_RATIO_3_4,
  VIDEO_ASPECT_RATIO_9_16,
  VIDEO_ASPECT_RATIO_1_1,
  VIDEO_ASPECT_RATIO_16_9,
  VIDEO_ASPECT_RATIO_4_3
};

typedef NS_ENUM(NSInteger, VideoRecordBeautyStyle) {
  VIDOE_BEAUTY_STYLE_SMOOTH = 0,
  VIDOE_BEAUTY_STYLE_NATURE = 1,
  VIDOE_BEAUTY_STYLE_PITU = 2,
};

@interface VideoRecordResult : NSObject
@property(nonatomic, assign) VideoRecordResultCode retCode;
@property(nonatomic, strong) NSString* descMsg;
@property(nonatomic, strong) NSString* videoPath;
@property(nonatomic, strong) UIImage* coverImage;
@end



@protocol VideoRecorderCoreListener<NSObject>
@optional
- (void)onRecordProgress:(NSInteger)milliSecond;
@optional
- (void)onRecordComplete:(VideoRecordResult*)result;
@optional
- (void)onRecordEvent:(NSDictionary*)evt;
@end


@interface VideoRecordCustomConfig : NSObject
@property(nonatomic, assign) VideoRecordResolution videoResolution;
@property(nonatomic, assign) int videoFPS;
@property(nonatomic, assign) int videoBitratePIN;
@property(nonatomic, assign) BOOL frontCamera;
@property(nonatomic, assign) float minDuration;
@property(nonatomic, assign) float maxDuration;
@end

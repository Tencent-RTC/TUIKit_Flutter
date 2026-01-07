// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <UIKit/UIKit.h>
#import "VideoRecorderBeautifySettings.h"

NS_ASSUME_NONNULL_BEGIN

@class VideoRecorderControlView;

typedef NS_ENUM(NSInteger, VideoRecorderAspectRatio) {
    VideoRecorderRecordAspectRatio1_1,
    VideoRecorderRecordAspectRatio3_4,
    VideoRecorderRecordAspectRatio4_3,
    VideoRecorderRecordAspectRatio9_16,
    VideoRecorderRecordAspectRatio16_9,
};
typedef void (^VideoRecorderRecordControlCallback)(VideoRecorderControlView *);

@protocol VideoRecorderControlViewDelegate <NSObject>
- (void)recordControlViewOnRecordStart;
- (void)recordControlViewOnRecordFinish;
- (void)recordControlViewPhoto;
- (void)recordControlViewOnFlashStateChange:(BOOL)flashState;
- (void)recordControlViewOnAspectChange;
- (void)recordControlViewOnExit;
- (void)recordControlViewOnCameraSwicth:(BOOL)isUsingFrontCamera;
- (void)recordControlViewOnBeautify;
@end


@interface VideoRecorderControlView : UIView
@property(nonatomic) BOOL flashState;
@property(nonatomic) VideoRecorderAspectRatio aspectRatio;
@property(nonatomic) BOOL isUsingFrontCamera;
@property(readonly, nonatomic) UIView *previewView;
@property(nonatomic) VideoRecorderBeautifySettings *beautifySettings;
@property(nonatomic) BOOL recordTipHidden;
@property(weak, nullable, nonatomic) id<VideoRecorderControlViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame;
- (instancetype)initWithFrame:(CGRect)frame beautifySettings:(VideoRecorderBeautifySettings *)beautifySettings;

- (void)setProgress:(float)progress duration:(float)duration;
@end

NS_ASSUME_NONNULL_END

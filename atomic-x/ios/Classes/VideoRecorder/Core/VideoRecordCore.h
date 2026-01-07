// Copyright (c) 2021 Tencent. All rights reserved.
// Author: eddardliu

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "VideoRecorderCommon.h"
#import "VideoRecorderTypeDef.h"

@class  VideoRecorderBeautyManager;

NS_ASSUME_NONNULL_BEGIN

@interface VideoRecordCore : NSObject

@property(nonatomic, weak) id<VideoRecorderCoreListener> recordDelegate;

- (instancetype)init;

- (int)startCameraCustom:(NSDictionary *)configDict preview:(UIView *)preview;

- (void)setZoom:(CGFloat)distance;

- (BOOL)switchCamera:(BOOL)isFront;

- (BOOL)toggleTorch:(BOOL)enable;

- (void)stopCameraPreview;

- (void)setAspectRatio:(VideoRecordAspectRatio)videoRatio;

- (int)startRecord:(NSString*) path;

- (int)stopRecord;

- (VideoRecorderBeautyManager *)getBeautyManager;

-(void) deleteTempFile;

- (void)setFilter:(UIImage *)leftFilter
     leftIntensity:(CGFloat)leftIntensity
       rightFilter:(UIImage *)rightFilter
    rightIntensity:(CGFloat)rightIntensity
         leftRatio:(CGFloat)leftRatio;

- (int)snapshot:(void (^)(UIImage *))snapshotCompletionBlock;

@end


@interface VideodioRecorderListenerProxy : NSObject

@property(nonatomic, weak) id<VideoRecorderCoreListener> recordDelegate;
- (void)onRecordProgress:(NSInteger)milliSecond;
- (void)onRecordComplete:(id)result;
- (void)onRecordEvent:(id)evt;
@end


NS_ASSUME_NONNULL_END

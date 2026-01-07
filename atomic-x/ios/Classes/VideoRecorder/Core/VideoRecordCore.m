// Copyright (c) 2021 Tencent. All rights reserved.
// Author: eddardliu

#import "VideoRecordCore.h"
#include <objc/objc.h>
#import "VideoRecorderBeautyManager.h"


@implementation VideoRecordCustomConfig
- (instancetype)init {
  self = [super init];
  return self;
}

@end

@interface VideoRecordCore () {
    id _instance;
    VideodioRecorderListenerProxy *_listenerProxy;
}


@end

@implementation VideoRecordCore


- (instancetype)init {
    return [super init];
}

- (void)dealloc {
    
}

- (void) setRecordDelegate:(id<VideoRecorderCoreListener>)recordDelegate {
    _recordDelegate = recordDelegate;
}

- (int)startCameraCustom:(NSDictionary *)configDict preview:(UIView *)preview {
    NSLog(@"recorder currently not supported start Camera Custom");
    return 1;
}

- (void)stopCameraPreview {
    NSLog(@"recorder currently not supported stop camera preview");
    return;
}

- (void)setZoom:(CGFloat)distance {
    NSLog(@"recorder currently not supported set zoom");
}

- (BOOL)switchCamera:(BOOL)isFront {
    NSLog(@"recorder currently not supported switch camera");
    return false;
}

- (BOOL)toggleTorch:(BOOL)enable {
    NSLog(@"recorder currently not supported toggle torch");
    return false;
}

- (void)setAspectRatio:(VideoRecordAspectRatio)videoRatio {
    NSLog(@"recorder currently not supported set aspect ratio");
}

- (int)startRecord:(NSString*) path {
    NSLog(@"recorder currently not supported start record");
    return 1;
}

- (int)stopRecord {
    NSLog(@"recorder currently not supported stop record");
    return 1;
}

- (VideoRecorderBeautyManager *)getBeautyManager {
    NSLog(@"recorder currently not supported get beauty manager");
    return nil;
}

-(void) deleteTempFile {
    NSLog(@"recorder currently not supported delete temp file");
    return;
}

- (void)setFilter:(UIImage *)leftFilter
     leftIntensity:(CGFloat)leftIntensity
       rightFilter:(UIImage *)rightFilter
    rightIntensity:(CGFloat)rightIntensity
        leftRatio:(CGFloat)leftRatio {
    NSLog(@"recorder currently not supported delete set filter");
    return;
}

- (int)snapshot:(void (^)(UIImage *))snapshotCompletionBlock {
    NSLog(@"recorder currently not supported delete snapshot");
    return 1;
}
@end


@implementation VideoRecordResult

@end

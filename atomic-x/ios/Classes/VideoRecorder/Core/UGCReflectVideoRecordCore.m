// Copyright (c) 2021 Tencent. All rights reserved.
// Author: eddardliu

#import "UGCReflectVideoRecordCore.h"

#include <objc/objc.h>
#import "ReflectUtil.h"
#import "VideoRecorderBeautyManager.h"

@interface UGCReflectVideoRecordCore () {
    id _txUGCRecorderInstance;
    VideodioRecorderListenerProxy *_listenerProxy;
}
@end

@implementation UGCReflectVideoRecordCore

- (instancetype)init {
  if (self = [super init]) {
      Class txClass = NSClassFromString(@"TXUGCRecord");
      if (txClass == nil) {
          NSLog(@"can not find TXUGCRecord");
          return nil;
      }
      
      SEL shareSelector = NSSelectorFromString(@"shareInstance");
      if ([txClass respondsToSelector:shareSelector]) {
          NSMethodSignature *signature = [txClass methodSignatureForSelector:shareSelector];
          NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
          [invocation setSelector:shareSelector];
          [invocation setTarget:txClass];
          [invocation invoke];
          
          __unsafe_unretained id temp = nil;
          [invocation getReturnValue:&temp];
         _txUGCRecorderInstance = temp;
      }
  }
    return _txUGCRecorderInstance ? self : nil;
}

- (void)dealloc {
    
}

- (void) setRecordDelegate:(id<VideoRecorderCoreListener>)recordDelegate {
    _listenerProxy = [[VideodioRecorderListenerProxy alloc] init];
    _listenerProxy.recordDelegate = recordDelegate;
    [ReflectUtil invokeMethod:_txUGCRecorderInstance methodName:@"setRecordDelegate:" withArguments:@[_listenerProxy]];
}

- (int)startCameraCustom:(NSDictionary *)configDict preview:(UIView *)preview {
    Class configClass = NSClassFromString(@"TXUGCCustomConfig");
    id customConfig = [configClass new];
    [configDict enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        if ([customConfig respondsToSelector:NSSelectorFromString(key)]) {
            [customConfig setValue:value forKey:key];
        }
    }];
    [ReflectUtil invokeMethod:_txUGCRecorderInstance methodName:@"startCameraCustom:preview:" withArguments:@[customConfig, preview]];
    return 1;
}

- (void)setZoom:(CGFloat)distance {
    [ReflectUtil invokeMethod:_txUGCRecorderInstance methodName:@"setZoom:" withArguments:@[@(distance)]];
}

- (BOOL)switchCamera:(BOOL)isFront {
    id ret = [ReflectUtil invokeMethod:_txUGCRecorderInstance methodName:@"switchCamera:" withArguments:@[@(isFront)]];
    return (ret == nil) ? NO : [ret boolValue];
}

- (BOOL)toggleTorch:(BOOL)enable {
    NSLog(@"toggleTorch @%d", enable);
    id ret = [ReflectUtil invokeMethod:_txUGCRecorderInstance methodName:@"toggleTorch:" withArguments:@[@(enable)]];
    return (ret == nil) ? NO : [ret boolValue];
}

- (void)stopCameraPreview {
    [ReflectUtil invokeMethod:_txUGCRecorderInstance methodName:@"stopCameraPreview" withArguments:@[]];
}

- (void)setAspectRatio:(VideoRecordAspectRatio)videoRatio {
    [ReflectUtil invokeMethod:_txUGCRecorderInstance  methodName:@"setAspectRatio:" withArguments:@[@(videoRatio)]];
}

- (int)startRecord:(NSString*) path {
    if (path == nil) {
        return -1;
    }
    
    NSString *withoutExtension = [path stringByDeletingPathExtension];
    NSString* coverPath = [withoutExtension stringByAppendingPathExtension:@"jpg"];
    
    id ret = [ReflectUtil invokeMethod:_txUGCRecorderInstance methodName:@"startRecord:coverPath:" withArguments:@[path,coverPath]];
    return (ret == nil) ? -1 : [ret intValue];
}

- (int)stopRecord {
    [ReflectUtil invokeMethod:_txUGCRecorderInstance methodName:@"stopRecord" withArguments:@[]];
    return 1;
}

- (VideoRecorderBeautyManager *)getBeautyManager {
    id ugcBeauty = [ReflectUtil invokeMethod:_txUGCRecorderInstance methodName:@"getBeautyManager" withArguments:@[]];
    VideoRecorderBeautyManager* beautyManager = [[VideoRecorderBeautyManager alloc] initWithUGCBeauty:ugcBeauty];
    return beautyManager;
}

- (void)setFilter:(UIImage *)leftFilter
     leftIntensity:(CGFloat)leftIntensity
       rightFilter:(UIImage *)rightFilter
    rightIntensity:(CGFloat)rightIntensity
        leftRatio:(CGFloat)leftRatio {
    [ReflectUtil invokeMethod:_txUGCRecorderInstance methodName:@"setFilter:leftIntensity:rightFilter:rightIntensity:leftRatio:"
         withArguments:@[@(leftIntensity), rightFilter, @(rightIntensity),@(leftRatio)]];
    return;
}

- (int)snapshot:(void (^)(UIImage *))snapshotCompletionBlock {
    id ret = [ReflectUtil invokeMethod:_txUGCRecorderInstance methodName:@"snapshot:" withArguments:@[snapshotCompletionBlock]];
    return (ret == nil) ? -1 : [ret intValue];
}

-(void) deleteTempFile {
    id partManager  = [ReflectUtil safeValueForProperty:_txUGCRecorderInstance propertyName:@"partsManager"];
    [ReflectUtil invokeMethod:partManager methodName:@"deleteAllParts" withArguments:@[]];
}
@end

@implementation VideodioRecorderListenerProxy

- (void)onRecordProgress:(NSInteger)milliSecond {
    NSLog(@"onRecordProgress:%d", milliSecond);
    if (_recordDelegate) {
        [_recordDelegate onRecordProgress:milliSecond];
    }
}

- (void)onRecordComplete:(id)result {
    if (_recordDelegate == nil) {
        return;
    }
    
    NSInteger retCode = -1;
    NSString *descMsg = @"";
    NSString *videoPath = @"";
    
    if ([result respondsToSelector:@selector(valueForKey:)]) {
        id retCodeValue = [result valueForKey:@"retCode"];
        if ([retCodeValue isKindOfClass:[NSNumber class]]) {
            retCode = [(NSNumber *)retCodeValue integerValue];
        }
        
        id descMsgValue = [result valueForKey:@"descMsg"];
        if ([descMsgValue isKindOfClass:[NSString class]]) {
            descMsg = (NSString *)descMsgValue;
        }
        
        id videoPathValue = [result valueForKey:@"videoPath"];
        if ([videoPathValue isKindOfClass:[NSString class]]) {
            videoPath = (NSString *)videoPathValue;
        }
    }
    
    NSLog(@"on record complete. retcode:%ld descMsg:%@ videoPath:%@", (long)retCode, descMsg, videoPath);
    
    VideoRecordResult* videoRecordResult = [[VideoRecordResult alloc] init];
    videoRecordResult.retCode = (VideoRecordResultCode)retCode;
    videoRecordResult.videoPath = videoPath;
    videoRecordResult.descMsg = descMsg;
    
    [_recordDelegate onRecordComplete:videoRecordResult];
}

- (void)onRecordEvent:(id)evt {
    
}

@end

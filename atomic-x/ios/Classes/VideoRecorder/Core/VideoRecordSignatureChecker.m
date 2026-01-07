// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import "VideoRecordSignatureChecker.h"
#import "VideoRecorderReflectUtil.h"
#import <objc/runtime.h>

#define SCHEDULE_UPDATE_SIGNATURE_INTERVAL_WHEN_START  0.f
#define SCHEDULE_UPDATE_SIGNATURE_INTERVAL_WHEN_SUCCESS  3600 * 1000.0f
#define SCHEDULE_UPDATE_SIGNATURE_INTERVAL_WHEN_FAIL  1000.0f
#define SCHEDULE_UPDATE_SIGNATURE_RETRY_TIMES  3
#define ERR_SDK_INTERFACE_NOT_SUPPORT         7013
#define ERR_SDK_NOT_INITIALIZED               6013

@interface VideoRecordSignatureChecker () {
    NSTimer* _timer;
    NSInvocation *getSignatureInvocation;
    
    NSString* _signature;
    NSInteger _expiredTime;
    NSString* _sdkAppId;
    VideoRecordSignatureResultCode _resultCode;
    
    void (^_succ)(NSObject *result);
    void (^_fail)(int code, NSString *desc);
}
@property (nonatomic, assign) NSInteger retryCount;
@end

@implementation VideoRecordSignatureChecker

+ (instancetype)shareInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _retryCount = 0;
        _expiredTime = 0;
        _resultCode =     VIDEO_RECORD_SIGNATURE_ERROR_NO_SIGNATURE;

    }
    return self;
}

- (void)startUpdateSignature :(NSString*)sdkAppId{
    NSLog(@"VideoRecorderSignatureChecker startUpdateSignature");
    if (![self createGetSignatureInvocation]) {
        _resultCode =     VIDEO_RECORD_SIGNATURE_ERROR_NO_IM_SDK;
        return;
    }
    _sdkAppId = sdkAppId;
    [self scheduleUpdateSignature:SCHEDULE_UPDATE_SIGNATURE_INTERVAL_WHEN_START];
}

- (Boolean)setSignatureToSDK{
    NSLog(@"setSignatureToSDK %@", _sdkAppId);
    if (_signature == nil || [_signature length] == 0) {
        return NO;
    }
    
    if (_sdkAppId == nil || [_sdkAppId length] == 0) {
        NSLog(@"sdk appid is empty");
        _resultCode =     VIDEO_RECORD_SIGNATURE_ERROR_APP_ID_EMPTY;
        return NO;
    }
    
    NSDictionary *param = @{
        @"api" : @"setSignature",
        @"params" : @{
            @"appid" : _sdkAppId,
            @"signature" : _signature,
        },
    };
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:param options:0 error:&error];
    if (error != nil) {
        NSLog(@"VideoRecorderSignatureChecker GetMultimediaIsSupport Error:%@", error);
    }
    NSString *paramStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"VideoRecorderSignatureChecker: setSignature:%@", paramStr);
    
    if (![self setSignatureToUGCSdk:paramStr]) {
        NSLog(@"callExperimentalAPI: method is not available.");
        _resultCode =         VIDEO_RECORD_SIGNATURE_ERROR_NO_LITEAV_SDK;
        return false;
    }
    
    _resultCode =         VIDEO_RECORD_SIGNATURE_SUCCESS;
    NSLog(@"VideoRecorderSignatureChecker: set signature to sdk success");
    return true;
}

- (VideoRecordSignatureResultCode)getSetSignatureResult {
    return _resultCode;
}

- (void)updateSignatureIfNeed {
    if ([NSDate.now timeIntervalSince1970] < _expiredTime && _resultCode ==         VIDEO_RECORD_SIGNATURE_SUCCESS) {
        [self scheduleUpdateSignature:(_expiredTime - [NSDate.now timeIntervalSince1970]) *1000];
        return;
    }
    _resultCode =     VIDEO_RECORD_SIGNATURE_ERROR_NO_SIGNATURE;
    
    if (getSignatureInvocation == nil) {
        NSLog(@"getSignatureInvocation is empty");
        _resultCode =     VIDEO_RECORD_SIGNATURE_ERROR_NO_IM_SDK;
        return;
    }
    
    [getSignatureInvocation invoke];
}

- (void)onGetSignatureSucc:(NSObject *) result {
    if (result == nil || ![result isKindOfClass:NSDictionary.class]) {
        NSLog(@"getVideoEditSignature: data = nil");
        return;
    }
    NSDictionary *data = (NSDictionary *)result;
    NSLog(@"getVideoEditSignature: data = %@", data);
    NSNumber *expiredTime = data[@"expired_time"];
    NSString *signature = data[@"signature"];
    if (![expiredTime isKindOfClass:NSNumber.class]) {
        NSLog(@"getVideoEditSignature: expiredTime type error");
        return;
    }
    if (![signature isKindOfClass:NSString.class]) {
        NSLog(@"getVideoEditSignature: signature type error");
        return;
    }
    
    self.retryCount = 0;
    self->_expiredTime = [expiredTime integerValue];
    self->_signature = signature;
    
    [self setSignatureToSDK];
    
    NSLog(@"getVideoEditSignature: succeed. signature=%@, expiredTime=%@", self->_signature, @(self->_expiredTime));
    [self scheduleUpdateSignature:([expiredTime integerValue] -  [NSDate.now timeIntervalSince1970]) * 1000];
}

- (void) onGetSignatureFail:(int) code desc:(NSString*) desc {
    NSLog(@"getVideoEditSignature: failed. code=%@, desc=%@", @(code), desc);
    if (code == ERR_SDK_INTERFACE_NOT_SUPPORT) {
        [self cancelTimer];
        return;
    }
    if (code == ERR_SDK_NOT_INITIALIZED) {
        self.retryCount = 0;
    }

    if (self.retryCount ++ > SCHEDULE_UPDATE_SIGNATURE_RETRY_TIMES) {
        self.retryCount = 0;
        return;
    } else {
        NSLog(@"getVideoEditSignature: Attempting to get signature for the %ld time",self.retryCount);
        [self scheduleUpdateSignature:SCHEDULE_UPDATE_SIGNATURE_INTERVAL_WHEN_FAIL];
    }
}

-(void)scheduleUpdateSignature:(float)interval {
    [self cancelTimer];
    interval = interval / 1000;
    _timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(updateSignatureIfNeed) userInfo:nil repeats:NO];
}

- (void)cancelTimer {
    if (_timer != nil) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (Boolean) createGetSignatureInvocation {
    id V2TIMManagerInstance = [VideoRecorderReflectUtil invokeStaticMethod:@"V2TIMManager" methodName:@"sharedInstance" withArguments:@[]];
    
    if (!V2TIMManagerInstance) {
        NSLog(@"VideoRecorderSignatureChecker can not get V2TIMManager instance");
        return NO;
    }
    
    NSString* param = @"signature";
    id _succ = ^(NSObject *result) {
        [self onGetSignatureSucc:result];
    };
    id _fail = ^(int code, NSString *desc) {
        [self onGetSignatureFail:code desc:desc];
    };
    [VideoRecorderReflectUtil invokeMethod:V2TIMManagerInstance methodName:@"callExperimentalAPI:param:succ:fail:" withArguments:@[@"getVideoEditSignature", param, _succ, _fail]];
    return YES;
}

- (Boolean) setSignatureToUGCSdk:(NSString *)param {
    id result =  [VideoRecorderReflectUtil invokeStaticMethod:@"TXUGCBase" methodName:@"callExperimentalAPI:" withArguments:@[param]];
    return result != nil;
}

@end

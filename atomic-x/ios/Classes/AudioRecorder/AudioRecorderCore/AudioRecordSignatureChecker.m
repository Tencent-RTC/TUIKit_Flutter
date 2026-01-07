// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import "AudioRecordSignatureChecker.h"
#import <objc/runtime.h>

#define SCHEDULE_UPDATE_SIGNATURE_INTERVAL_WHEN_START  0.f
#define SCHEDULE_UPDATE_SIGNATURE_INTERVAL_WHEN_SUCCESS  3600 * 1000.0f
#define SCHEDULE_UPDATE_SIGNATURE_INTERVAL_WHEN_FAIL  1000.0f
#define SCHEDULE_UPDATE_SIGNATURE_RETRY_TIMES  3
#define ERR_SDK_INTERFACE_NOT_SUPPORT         7013
#define ERR_SDK_NOT_INITIALIZED               6013

@interface AuidoRecordSignatureChecker () {
    NSTimer* _timer;
    NSInvocation *getSignatureInvocation;
    
    NSString* _signature;
    NSInteger _expiredTime;
    AudioRecordSignatureResultCode _resultCode;
    
    void (^_succ)(NSObject *result);
    void (^_fail)(int code, NSString *desc);
}
@property (nonatomic, assign) NSInteger retryCount;
@end

@implementation AuidoRecordSignatureChecker

+ (void)load {
    [[AuidoRecordSignatureChecker shareInstance] startUpdateSignature];
}

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
        _resultCode =     AudioRecordSignatureResultCodeEerrorNoSignature;

    }
    return self;
}

- (void)startUpdateSignature{
    NSLog(@"TUIMultimediaSignatureChecker startUpdateSignature");
    if (![self createGetSignatureInvocation]) {
        _resultCode = AudioRecordSignatureResultCodeEerrorNoIMSdk;
        return;
    }
    
    [self scheduleUpdateSignature:SCHEDULE_UPDATE_SIGNATURE_INTERVAL_WHEN_START];
}

- (Boolean)setSignatureToSDK:(NSString*)sdkAppId {
    if (_signature == nil || [_signature length] == 0) {
        return NO;
    }
    
    if (sdkAppId == nil || [sdkAppId length] == 0) {
        NSLog(@"sdk appid is empty");
        _resultCode = AudioRecordSignatureResultCodeEerrorAppIdIsEmpty;
        return NO;
    }
    
    NSDictionary *param = @{
        @"api" : @"setSignature",
        @"params" : @{
            @"appid" : sdkAppId,
            @"signature" : _signature,
        },
    };
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:param options:0 error:&error];
    if (error != nil) {
        NSLog(@"AuidoRecordSignatureChecker GetMultimediaIsSupport Error:%@", error);
    }
    NSString *paramStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"AuidoRecordSignatureChecker: setSignature:%@", paramStr);
    
    if (![self setSignatureToUGCSdk:paramStr]) {
        NSLog(@"callExperimentalAPI: method is not available.");
        _resultCode =     AudioRecordSignatureResultCodeErrorNoLiteavSdk;
        return false;
    }
    
    _resultCode = AudioRecordSignatureResultCodeSUCCESS;
    NSLog(@"AuidoRecordSignatureChecker: set signature to sdk success");
    return true;
}

- (AudioRecordSignatureResultCode)getSetSignatureResult {
    return _resultCode;
}

- (void)updateSignatureIfNeed {
    if ([NSDate.now timeIntervalSince1970] < _expiredTime && _resultCode == AudioRecordSignatureResultCodeSUCCESS) {
        [self scheduleUpdateSignature:(_expiredTime - [NSDate.now timeIntervalSince1970]) *1000];
        return;
    }
    _resultCode =     AudioRecordSignatureResultCodeEerrorNoSignature;
    
    if (getSignatureInvocation == nil) {
        NSLog(@"getSignatureInvocation is empty");
        _resultCode =     AudioRecordSignatureResultCodeEerrorNoIMSdk;
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
    Class V2TIMManagerClass = NSClassFromString(@"V2TIMManager");
    if (!V2TIMManagerClass) {
        NSLog(@"AuidoRecordSignatureChecker can not find V2TIMManager");
        return NO;
    }
    
    SEL sharedInstanceSelector = NSSelectorFromString(@"sharedInstance");
    if (![V2TIMManagerClass respondsToSelector:sharedInstanceSelector]) {
        NSLog(@"AuidoRecordSignatureChecker can not find V2TIMManager sharedInstance function");
        return NO;
    }
    
    NSMethodSignature *sharedInstanceSignature = [V2TIMManagerClass methodSignatureForSelector:sharedInstanceSelector];
    NSInvocation *sharedInstanceInvocation = [NSInvocation invocationWithMethodSignature:sharedInstanceSignature];
    sharedInstanceInvocation.target = V2TIMManagerClass;
    sharedInstanceInvocation.selector = sharedInstanceSelector;
    [sharedInstanceInvocation invoke];
    
    __unsafe_unretained id temp;
    [sharedInstanceInvocation getReturnValue:&temp];
    id sharedInstance = temp;
    
    if (!sharedInstance) {
        NSLog(@"AuidoRecordSignatureChecker can not get V2TIMManager instance");
        return NO;
    }
    
    SEL apiSelector = NSSelectorFromString(@"callExperimentalAPI:param:succ:fail:");
    if (![sharedInstance respondsToSelector:apiSelector]) {
        NSLog(@"AuidoRecordSignatureChecker has not callExperimentalAPI:param:succ:fail:");
        return NO;
    }
    
    NSMethodSignature *methodSignature = [sharedInstance methodSignatureForSelector:apiSelector];
    getSignatureInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    getSignatureInvocation.target = sharedInstance;
    getSignatureInvocation.selector = apiSelector;
    
    NSString *apiName = @"getVideoEditSignature";
    [getSignatureInvocation setArgument:&apiName atIndex:2];
    
    id param = nil;
    [getSignatureInvocation setArgument:&param atIndex:3];
    
    _succ = ^(NSObject *result) {
        [self onGetSignatureSucc:result];
    };
    [getSignatureInvocation setArgument:&_succ atIndex:4];
    
    _fail = ^(int code, NSString *desc) {
        [self onGetSignatureFail:code desc:desc];
    };
    [getSignatureInvocation setArgument:&_fail atIndex:5];
    
    return YES;
}

- (Boolean) setSignatureToUGCSdk:(NSString *)param {
    Class TXUGCBase = NSClassFromString(@"TXUGCBase");
    if (TXUGCBase == nil) {
        NSLog(@"AuidoRecordSignatureChecker can not find class TXUGCBase");
        return NO;
    }
    
    SEL selector = NSSelectorFromString(@"callExperimentalAPI:");
    if (![TXUGCBase respondsToSelector:selector]) {
        NSLog(@"AuidoRecordSignatureChecker TXUGCBase has not method callExperimentalAPI");
        return NO;
    }
    NSMethodSignature *signature = [TXUGCBase methodSignatureForSelector:selector];
    if (!signature) {
        NSLog(@"AuidoRecordSignatureChecker can not get method: %@", @"callExperimentalAPI");
        return NO;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = TXUGCBase;
    invocation.selector = selector;
    
    [invocation setArgument:&param atIndex:2];
    [invocation invoke];
    return  YES;
}

@end

// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AudioRecordSignatureResultCode) {
    AudioRecordSignatureResultCodeSUCCESS = 0,
    AudioRecordSignatureResultCodeErrorNoLiteavSdk = -7,
    AudioRecordSignatureResultCodeEerrorNoIMSdk = -8,
    AudioRecordSignatureResultCodeEerrorAppIdIsEmpty = -9,
    AudioRecordSignatureResultCodeEerrorNoSignature = -10
};

@interface AuidoRecordSignatureChecker : NSObject
+ (void)load;
+ (instancetype)shareInstance;
- (void)startUpdateSignature;
- (Boolean)setSignatureToSDK:(NSString*)sdkAppId;
- (AudioRecordSignatureResultCode)getSetSignatureResult;
@end

NS_ASSUME_NONNULL_END

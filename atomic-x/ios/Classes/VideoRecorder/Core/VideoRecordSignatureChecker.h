// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VideoRecordSignatureResultCode) {
    VIDEO_RECORD_SIGNATURE_SUCCESS = 0,
    VIDEO_RECORD_SIGNATURE_ERROR_NO_LITEAV_SDK = -7,
    VIDEO_RECORD_SIGNATURE_ERROR_NO_IM_SDK = -8,
    VIDEO_RECORD_SIGNATURE_ERROR_APP_ID_EMPTY = -9,
    VIDEO_RECORD_SIGNATURE_ERROR_NO_SIGNATURE = -10
};

@interface VideoRecordSignatureChecker : NSObject
+ (instancetype)shareInstance;
- (void)startUpdateSignature:(NSString*)sdkAppId;
- (VideoRecordSignatureResultCode)getSetSignatureResult;
@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^VideoRecorderRecordResultCallback)(NSString *_Nullable videoPath, UIImage *_Nullable image, int32_t duration);

@interface VideoRecorderController : UIViewController
@property(nullable, nonatomic, strong) NSString* recordFilePath;
@property(nullable, nonatomic) VideoRecorderRecordResultCallback resultCallback;
- (instancetype)init;
@end

NS_ASSUME_NONNULL_END

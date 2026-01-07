// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <Foundation/Foundation.h>
#import "VideoRecordCore.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoRecorderEncodeConfig : NSObject
@property(nonatomic) int fps;
@property(nonatomic) int bitrate;

- (instancetype)initWithVideoQuality:(int)videoQuality;
- (VideoRecordCompressed)getVideoEditCompressed;
- (VideoRecordResolution)getVideoRecordResolution;
@end

NS_ASSUME_NONNULL_END

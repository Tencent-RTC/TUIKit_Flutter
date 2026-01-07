// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <Foundation/Foundation.h>
#import "VideoRecorderBeautifyEffectItem.h"

@class VideoRecorderBeautyManager;

NS_ASSUME_NONNULL_BEGIN

static const float VideoRecorderBeautifyStrengthMin = 0;
static const float VideoRecorderBeautifyStrengthMax = 9;
static const float VideoRecorderFilterStrengthMin = 0;
static const float VideoRecorderFilterStrengthMax = 1;

static const int VideoRecorderEffectSliderMin = 0;
static const int VideoRecorderEffectSliderMax = 9;


@interface VideoRecorderBeautifySettings : NSObject
@property(nonatomic) NSArray<VideoRecorderBeautifyEffectItem *> *beautifyItems;
@property(nonatomic) NSArray<VideoRecorderBeautifyEffectItem *> *filterItems;
@property(nonatomic) NSInteger activeBeautifyTag;
@property(nonatomic) NSInteger activeFilterIndex;

- (instancetype)init;
@end

NS_ASSUME_NONNULL_END

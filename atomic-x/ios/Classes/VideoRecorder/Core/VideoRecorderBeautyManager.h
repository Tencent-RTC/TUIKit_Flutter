// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TXBeautyStyle) {
    TXBeautyStyleSmooth = 0,
    TXBeautyStyleNature = 1,
    TXBeautyStylePitu = 2
};

@interface VideoRecorderBeautyManager : NSObject

- (instancetype) initWithUGCBeauty:(id) ugcBeauty;

- (void)setBeautyStyle:(TXBeautyStyle)beautyStyle;

- (void)setBeautyLevel:(float)beautyLevel;

- (void)setWhitenessLevel:(float)whitenessLevel;

- (void)setRuddyLevel:(float)ruddyLevel;

- (void)setFilter:(nullable UIImage *)image;

- (void)setFilterStrength:(float)strength;

@end

NS_ASSUME_NONNULL_END

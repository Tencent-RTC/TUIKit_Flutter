// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static const int VideoRecorderEffectItemTagNone = -1;
static const int VideoRecorderEffectItemTagSmooth = 1;
static const int VideoRecorderEffectItemTagNatural = 2;
static const int VideoRecorderEffectItemTagPitu = 3;
static const int VideoRecorderEffectItemTagWhiteness = 4;
static const int VideoRecorderEffectItemTagRuddy = 5;


@interface VideoRecorderBeautifyEffectItem : NSObject
@property(nonatomic) NSString *name;
@property(nonatomic) UIImage *iconImage;
@property(nullable, nonatomic) UIImage *filterMapImage;
@property(nonatomic) int strength;
@property(nonatomic) NSInteger tag;

- (instancetype)initWithName:(NSString *)name iconImage:(UIImage *)iconImage strength:(int)strength;
+ (NSArray<VideoRecorderBeautifyEffectItem *> *)defaultBeautifyEffects;
+ (NSArray<VideoRecorderBeautifyEffectItem *> *)defaultFilterEffects;
@end

NS_ASSUME_NONNULL_END

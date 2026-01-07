// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import "VideoRecorderBeautifyEffectItem.h"
#import "VideoRecorderNSArray+Functional.h"
#import "VideoRecorderCommon.h"

#define DEFAULT_FILTER_EFFECT_STRENGTH 4

@implementation VideoRecorderBeautifyEffectItem
- (instancetype)initWithName:(NSString *)name iconImage:(UIImage *)iconImage strength:(int)strength {
    self = [super init];
    if (self != nil) {
        _name = name;
        _iconImage = iconImage;
        _strength = strength;
    }
    return self;
}

+ (VideoRecorderBeautifyEffectItem *)newWithName:(NSString *)name iconImageName:(NSString *)iconImageName tag:(NSInteger)tag {
    VideoRecorderBeautifyEffectItem *item = [[VideoRecorderBeautifyEffectItem alloc] initWithName:name iconImage:[VideoRecorderCommon bundleImageByName:iconImageName] strength:0];
    item.tag = tag;
    return item;
}

+ (VideoRecorderBeautifyEffectItem *)newWithFilterName:(NSString *)filterName {
    NSString *nameKey = [NSString stringWithFormat:@"filter_%@", filterName];
    NSString *name = [VideoRecorderCommon localizedStringForKey:nameKey];

    NSString *iconImageName = [NSString stringWithFormat:@"icon_%@", filterName];
    NSString *filterMapImageName = [NSString stringWithFormat:@"filter_%@", filterName];
    VideoRecorderBeautifyEffectItem *item = [[VideoRecorderBeautifyEffectItem alloc] initWithName:name iconImage:[VideoRecorderCommon bundleImageByName:iconImageName] strength:DEFAULT_FILTER_EFFECT_STRENGTH];
    item.filterMapImage = [VideoRecorderCommon bundleImageByName:filterMapImageName];
    return item;
}

+ (NSArray<NSString *> *)filterNameList {
    return @[
        @"none",
        @"bailan",
        @"biaozhun",
        @"chaotuo",
        @"chunzhen",
        @"fennen",
        @"huaijiu",
        @"landiao",
        @"langman",
        @"qingliang",
        @"qingxin",
        @"rixi",
        @"weimei",
        @"xiangfen",
        @"yinghong",
        @"yuanqi",
        @"yunshang",
    ];
}

+ (NSArray<VideoRecorderBeautifyEffectItem *> *)defaultBeautifyEffects {
    return @[
        [VideoRecorderBeautifyEffectItem newWithName:[VideoRecorderCommon localizedStringForKey:@"beautify_none"] iconImageName:@"none" tag:VideoRecorderEffectItemTagNone],
        [VideoRecorderBeautifyEffectItem newWithName:[VideoRecorderCommon localizedStringForKey:@"beautify_smooth"] iconImageName:@"smooth" tag:VideoRecorderEffectItemTagSmooth],
        [VideoRecorderBeautifyEffectItem newWithName:[VideoRecorderCommon localizedStringForKey:@"beautify_whitness"]
                        iconImageName:@"whitness"
                                  tag:VideoRecorderEffectItemTagWhiteness],
        [VideoRecorderBeautifyEffectItem newWithName:[VideoRecorderCommon localizedStringForKey:@"beautify_ruddy"] iconImageName:@"ruddy" tag:VideoRecorderEffectItemTagRuddy],
    ];
}

+ (NSArray<VideoRecorderBeautifyEffectItem *> *)defaultFilterEffects {
    NSArray<VideoRecorderBeautifyEffectItem *> *list = [[VideoRecorderBeautifyEffectItem filterNameList] video_recorder_map:^(NSString *name) {
      return [VideoRecorderBeautifyEffectItem newWithFilterName:name];
    }];
    list.firstObject.tag = VideoRecorderEffectItemTagNone;
    return list;
}

@end

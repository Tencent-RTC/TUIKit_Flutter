// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import "VideoRecorderBeautifySettings.h"
#include "VideoRecorderCommon.h"

@implementation VideoRecorderBeautifySettings

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _activeBeautifyTag = VideoRecorderEffectItemTagNone;
        _beautifyItems = [VideoRecorderBeautifyEffectItem defaultBeautifyEffects];
        _filterItems = [VideoRecorderBeautifyEffectItem defaultFilterEffects];
    }
    return self;
}

@end

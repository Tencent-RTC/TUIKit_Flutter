// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import "VideoRecorderNSArray+Functional.h"

@implementation NSArray (Functional)

- (NSArray *)video_recorder_map:(id (^)(id))f {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.count];
    for (id x in self) {
        [array addObject:f(x)];
    }
    return array;
}
@end

// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray <__covariant ObjectType>(Functional)

- (NSArray *)video_recorder_map:(id (^)(ObjectType))f;
@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoRecorderImageUtil : NSObject
+ (UIImage *)imageFromImage:(UIImage *)img withTintColor:(UIColor *)tintColor;
+ (UIImage *)createBlueCircleWithWhiteBorder:(CGSize)size withColor:(UIColor*) color;
@end

NS_ASSUME_NONNULL_END

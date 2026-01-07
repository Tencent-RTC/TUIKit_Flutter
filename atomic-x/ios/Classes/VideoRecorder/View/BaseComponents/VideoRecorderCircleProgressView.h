// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface VideoRecorderCircleProgressView : UIView
@property(nonatomic) CGFloat progress;
@property(nonatomic) UIColor *progressColor;
@property(nonatomic) UIColor *progressBgColor;
@property(nonatomic) CGFloat width;
@property(nonatomic) BOOL clockwise;
@property(nonatomic) CGFloat startAngle;
@property(nonatomic) CAShapeLayerLineCap lineCap;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;
@end

NS_ASSUME_NONNULL_END

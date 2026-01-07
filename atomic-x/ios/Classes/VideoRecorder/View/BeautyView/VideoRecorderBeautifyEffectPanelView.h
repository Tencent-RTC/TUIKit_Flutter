// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <UIKit/UIKit.h>
#import "VideoRecorderBeautifyEffectViewCell.h"
#import "VideoRecorderBeautifyEffectItem.h"
NS_ASSUME_NONNULL_BEGIN

@protocol VideoRecorderEffectPanelDelegate;
@interface VideoRecorderBeautifyEffectPanelView : UIView
@property(nonatomic) NSArray<VideoRecorderBeautifyEffectItem *> *items;
@property(nonatomic) NSInteger selectedIndex;
@property(nonatomic) CGSize iconSize;
@property(nonatomic) CGSize firstIconSize;
@property(weak, nullable, nonatomic) id<VideoRecorderEffectPanelDelegate> delegate;
- (id)initWithFrame:(CGRect)frame;
@end

@protocol VideoRecorderEffectPanelDelegate <NSObject>
- (void)effectPanelSelectionChanged:(VideoRecorderBeautifyEffectPanelView *)panel;
@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class VideoRecorderTabPanelTab;

@protocol VideoRecorderTabPanelDelegate;

@interface VideoRecorderTabPanelView : UIView
@property(nonatomic) NSArray<VideoRecorderTabPanelTab *> *tabs;
@property(nonatomic) NSInteger selectedIndex;
@property(weak, nullable, nonatomic) id<VideoRecorderTabPanelDelegate> delegate;
- (id)initWithFrame:(CGRect)frame;
@end

@protocol VideoRecorderTabPanelDelegate <NSObject>
- (void)tabPanel:(VideoRecorderTabPanelView *)panel selectedIndexChanged:(NSInteger)selectedIndex;
@end

@interface VideoRecorderTabPanelTab : NSObject
@property(nonatomic) UIView *view;
@property(nullable, nonatomic) NSString *name;
@property(nullable, nonatomic) UIImage *icon;
- (instancetype)initWithName:(nullable NSString *)name icon:(nullable UIImage *)icon view:(UIView *)view;
@end

@protocol VideoRecorderTabBarDelegate;

@interface VideoRecorderTabBar : UIView
@property(nonatomic) NSArray<id> *tabs;
@property(nonatomic) NSInteger selectedIndex;
@property(weak, nullable, nonatomic) id<VideoRecorderTabBarDelegate> delegate;
@end

@protocol VideoRecorderTabBarDelegate <NSObject>
- (void)tabBar:(VideoRecorderTabBar *)bar selectedIndexChanged:(NSInteger)index;
@end

@interface VideoRecorderTabBarCell : UICollectionViewCell
@property(nullable, nonatomic) NSAttributedString *attributedText;
@property(nullable, nonatomic) UIImage *icon;
@property(nonatomic) CGFloat padding;
@property(nonatomic) BOOL barCellSelected;
+ (NSString *)reuseIdentifier;
@end

NS_ASSUME_NONNULL_END

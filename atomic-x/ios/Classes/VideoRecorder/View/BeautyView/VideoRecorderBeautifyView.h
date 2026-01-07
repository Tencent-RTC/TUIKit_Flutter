// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <UIKit/UIKit.h>
#import "VideoRecorderBeautifySettings.h"

NS_ASSUME_NONNULL_BEGIN

@protocol VideoRecorderBeautifyViewDelegate;

@interface VideoRecorderBeautifyView : UIView
@property(nonatomic) VideoRecorderBeautifySettings *settings;
@property(weak, nullable, nonatomic) id<VideoRecorderBeautifyViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame;
- (instancetype)initWithFrame:(CGRect)frame settings:(nullable VideoRecorderBeautifySettings *)settings;
@end

@protocol VideoRecorderBeautifyViewDelegate <NSObject>
- (void)beautifyView:(VideoRecorderBeautifyView *)beautifyView onSettingsChange:(VideoRecorderBeautifySettings *)settings;
@end

@interface VideoRecorderMarker : UIView
@property(nonatomic) NSString *text;
- (void)showForDuration:(CGFloat)showSeconds withHideAnimeDuration:(CGFloat)hideAnimeSeconds;
- (void)hide;
@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VideoRecorderRecordButtonDelegate;

@interface VideoRecorderRecordButtonView : UIView
@property(nonatomic) float progress;
@property(nonatomic) float dotSizeNormal;
@property(nonatomic) float progressSizeNormal;
@property(nonatomic) float dotSizePressed;
@property(nonatomic) float progressSizePressed;
@property(weak, nullable, nonatomic) id<VideoRecorderRecordButtonDelegate> delegate;
@property(nonatomic) BOOL isOnlySupportTakePhoto;

- (instancetype)initWithFrame:(CGRect)frame;
@end

@protocol VideoRecorderRecordButtonDelegate <NSObject>
- (void)onRecordButtonTap:(VideoRecorderRecordButtonView *)btn;
- (void)onRecordButtonLongPressBegan:(VideoRecorderRecordButtonView *)btn;
- (void)onRecordButtonLongPressEnded:(VideoRecorderRecordButtonView *)btn;
- (void)onRecordButtonLongPressCancelled:(VideoRecorderRecordButtonView *)btn;
@end

NS_ASSUME_NONNULL_END

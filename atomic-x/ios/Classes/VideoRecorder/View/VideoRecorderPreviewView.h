// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <AVFoundation/AVFoundation.h>

@protocol VideoRecorderPreviewViewDelegate;

@interface VideoRecorderPreviewView : UIView

@property(weak, nullable, nonatomic) id<VideoRecorderPreviewViewDelegate> delegate;
- (void) previewPhoto:(UIImage*_Nullable) image;
- (void) play:(NSString*_Nullable)videoPath;
- (void) stop;
- (void) pause;
- (void) resume;
@end

@protocol VideoRecorderPreviewViewDelegate <NSObject>
- (void)previewAccept:(NSString*) videoPath image:(UIImage*) image;
- (void)previewCancel;
@end

// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#include "VideoRecorderPreviewView.h"
#include "videoRecorderConfigInternal.h"
#include "VideoRecorderCommon.h"
#import <Masonry/Masonry.h>

#define FUNCTION_BUTTON_SIZE CGSizeMake(28, 28)
#define BUTTON_SEND_SIZE CGSizeMake(72, 34)

@interface VideoRecorderPreviewView() {
    NSString* _videoPath;
    AVPlayer* _player;
    UIImageView *_imgView;
    UIScreenEdgePanGestureRecognizer *_edgePanGesture;
    UITapGestureRecognizer *_tapGesture;
    UIStackView *_stkViewButtons;
    UIButton *_btnSend;
    UIButton *_btnCancel;
    UIImage* _image;
    UIView *_bottomBackground;
}
@end


@implementation VideoRecorderPreviewView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initUI];
    }
    return self;
}

-(void)initUI {
    self.backgroundColor = [UIColor blackColor];

    _imgView = [[UIImageView alloc] init];
    [self addSubview:_imgView];
    _imgView.hidden = YES;
    
    [self initFuncitonBtnStackView];
    [self initSendAndCancelBtn];
    [self addBottomBackground];
}

-(void) play:(NSString*)videoPath {
    if (_player != nil) {
        [_player pause];
        _player = nil;;
    }
    _videoPath = videoPath;
    _image = nil;
    
    [self addPanGesture];
    _imgView.hidden = YES;
    
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    _player = [AVPlayer playerWithURL:url];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.frame = self.bounds;
    [self.layer addSublayer:playerLayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(playerItemDidReachEnd:)
                                                name:AVPlayerItemDidPlayToEndTimeNotification
                                              object:_player.currentItem];
    
    [_player play];
    [self showOperationButton];
}

- (void) pause {
    if (_player != nil) {
        [_player pause];
    }
}

- (void) resume {
    if (_player != nil) {
        [_player play];
    }
}

- (void) previewPhoto:(UIImage*) image {
    if (image == nil) {
        return;
    }
    _videoPath = nil;
    _image = image;
    
    [self addPanGesture];
    _imgView.image = image;
    float aspect = image.size.height * 1.0f / image.size.width;
    int imageViewHeight = self.frame.size.width * aspect;
    int top = (self.frame.size.height - imageViewHeight) / 2;
    _imgView.frame = CGRectMake(0, top, self.frame.size.width, imageViewHeight);
    _imgView.hidden = NO;
    
    [_imgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).inset(top);
    }];
    
    [self showOperationButton];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [_player seekToTime:kCMTimeZero];
    [_player play];
}

- (void)removePanGesture {
    if (_edgePanGesture) {
        [self removeGestureRecognizer:_edgePanGesture];
        _edgePanGesture = nil;
    }
    
    if (_tapGesture) {
        [self removeGestureRecognizer:_tapGesture];
        _tapGesture = nil;
    }
}

- (void)addPanGesture {
    if (_edgePanGesture == nil) {
        _edgePanGesture = [[UIScreenEdgePanGestureRecognizer alloc]
                                                            initWithTarget:self
                                                            action:@selector(handleEdgePanGesture:)];
        _edgePanGesture.edges = UIRectEdgeLeft;
        [self addGestureRecognizer:_edgePanGesture];
    }
    
    
    if (_tapGesture == nil) {
        _tapGesture = [[UITapGestureRecognizer alloc]
                                                initWithTarget:self
                                                action:@selector(handleTap:)];
        [self addGestureRecognizer:_tapGesture];
    }
    
}


- (void)handleEdgePanGesture:(UIScreenEdgePanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateChanged: {
            CGFloat progress = fabs(translation.x / self.bounds.size.width);
            progress = MIN(1.0, MAX(0.0, progress));
            self.transform = CGAffineTransformMakeTranslation(progress * self.bounds.size.width, 0);
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            CGFloat velocity = [gesture velocityInView:self].x;
            CGFloat progress = fabs(translation.x / self.bounds.size.width);
            
            if (progress > 0.5 || velocity > 1000) {
                [UIView animateWithDuration:0.3 animations:^{
                    self.transform = CGAffineTransformMakeTranslation(self.bounds.size.width, 0);
                } completion:^(BOOL finished) {
                    [self quit:NO];
                }];
            } else {
                [UIView animateWithDuration:0.3 animations:^{
                    self.transform = CGAffineTransformIdentity;
                }];
            }
            break;
        }
        case UIGestureRecognizerStateBegan:
        default:
            break;
    }
}

- (void) initFuncitonBtnStackView {
    _stkViewButtons = [[UIStackView alloc] init];
    _stkViewButtons.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_stkViewButtons];
    _stkViewButtons.axis = UILayoutConstraintAxisHorizontal;
    _stkViewButtons.alignment = UIStackViewAlignmentCenter;
    _stkViewButtons.distribution = UIStackViewDistributionEqualSpacing;
    
    [_stkViewButtons mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self).inset(10);
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom);
        make.height.mas_equalTo(FUNCTION_BUTTON_SIZE.height);
    }];
}

- (void)addBottomBackground {
    _bottomBackground = [[UIView alloc] init];
    _bottomBackground.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.05];
    _bottomBackground.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomBackground.layer.cornerRadius = 8;
    [self addSubview:_bottomBackground];
    [NSLayoutConstraint activateConstraints:@[
            [_bottomBackground.heightAnchor constraintEqualToConstant:100],
            [_bottomBackground.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_bottomBackground.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_bottomBackground.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
        ]];
}

- (void)handleTap:(UITapGestureRecognizer *)sender {
    _btnSend.hidden = !_btnSend.isHidden;
    _btnCancel.hidden = !_btnCancel.isHidden;
    _bottomBackground.hidden = !_bottomBackground.hidden;
}

- (void) initSendAndCancelBtn {
    _btnSend = [UIButton buttonWithType:UIButtonTypeSystem];
    
    if (_stkViewButtons.arrangedSubviews.count == 0) {
        [_stkViewButtons removeFromSuperview];
        [self addSubview:_btnSend];
        [_btnSend mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(BUTTON_SEND_SIZE);
            make.right.equalTo(self).inset(20);
            make.bottom.equalTo(self).inset(25);
        }];
    } else {
        [_stkViewButtons addArrangedSubview:_btnSend];
        [_btnSend mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(BUTTON_SEND_SIZE);
        }];
    }
    
    _btnSend.backgroundColor = [[VideoRecorderConfigInternal sharedInstance] getThemeColor];
    [_btnSend setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _btnSend.layer.cornerRadius = 5;
    NSString* titile = [VideoRecorderCommon localizedStringForKey:@"send"];
    [_btnSend setTitle:titile forState:UIControlStateNormal];
    [_btnSend addTarget:self action:@selector(onBtnSendClicked) forControlEvents:UIControlEventTouchUpInside];
    
    _btnCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:_btnCancel];
    [_btnCancel setImage:VideoRecorderBundleThemeImage(@"return_arrow") forState:UIControlStateNormal];
    [_btnCancel addTarget:self action:@selector(onBtnCancelClicked) forControlEvents:UIControlEventTouchUpInside];
    [_btnCancel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(24, 24));
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).inset(10);
        if([[VideoRecorderCommon getPreferredLanguage] hasPrefix:@"ar"]) {
            make.right.equalTo(self.mas_safeAreaLayoutGuideRight).offset(-15);
        } else {
            make.left.equalTo(self.mas_safeAreaLayoutGuideLeft).offset(15);
        }
    }];
}

- (void)onBtnSendClicked {
    [self quit:YES];
}

- (void)onBtnCancelClicked {
    [self quit:NO];
}

- (void) quit : (BOOL) accept{
    [self removePanGesture];
    self.transform = CGAffineTransformIdentity;
    [self cleanupPlayer];
    if (_delegate) {
        accept ? [_delegate previewAccept:_videoPath image:_image] : [_delegate previewCancel];
    }
}

-(void)showOperationButton {
    [self bringSubviewToFront:_bottomBackground];
    [self bringSubviewToFront:_btnSend];
    [self bringSubviewToFront:_btnCancel];
    _btnSend.hidden = FALSE;
    _btnCancel.hidden = FALSE;
    _bottomBackground.hidden = FALSE;
}

- (void)cleanupPlayer {
    if (_player == nil) {
        return;
    }
    [_player pause];
    for (NSInteger i = self.layer.sublayers.count - 1; i >= 0; i--) {
        CALayer *layer = self.layer.sublayers[i];
        if ([layer isKindOfClass:[AVPlayerLayer class]]) {
            [layer removeFromSuperlayer];
        }
    }
    _player = nil;
}

@end

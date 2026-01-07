// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import "VideoRecorderController.h"

#import <Masonry/Masonry.h>
#import <Foundation/Foundation.h>

#import "VideoRecorderBeautifyView.h"
#import "VideoRecorderCommon.h"
#import "VideoRecorderControlView.h"
#include "videoRecorderConfigInternal.h"
#import "VideoRecorderEncodeConfig.h"
#import "VideoRecorderAuthorizationPrompterController.h"
#import "UGCReflectVideoRecordCore.h"
#import "SystemVideoRecordCore.h"
#import "VideoRecorderBeautyManager.h"
#import "VideoRecorderPreviewView.h"
#import "VideoRecordSignatureChecker.h"

#define MIXED_RECORD_MODE 0

@interface VideoRecorderController () <VideoRecorderBeautifyViewDelegate, VideoRecorderCoreListener, VideoRecorderControlViewDelegate, VideoRecorderPreviewViewDelegate> {
    VideoRecordCore* _recordCore;
    VideoRecorderBeautifyView *_beautifyView;
    VideoRecorderBeautifySettings *_settings;
    VideoRecorderControlView *_ctrlView;
    VideoRecorderPreviewView *_videoPlayerView;
    UIScreenEdgePanGestureRecognizer *_edgePanGesture;
    VideoRecordResult* _recorderResult;
    VideoRecorderEncodeConfig* _encodeConfig;
    CGFloat _zoom;
    BOOL _originNavgationBarHidden;
    BOOL _recordForEdit;
    BOOL _isUsingFrontCamera;
    float _recordDuration;
    float _minDurationSeconds;
    float _maxDurationSeconds;
}

@end

@implementation VideoRecorderController

- (instancetype)init {
    self = [super init];
    _isUsingFrontCamera = [[VideoRecorderConfigInternal sharedInstance] isDefaultFrontCamera];
    _minDurationSeconds = [[VideoRecorderConfigInternal sharedInstance] getMinRecordDurationMs] / 1000.0f;
    _maxDurationSeconds = [[VideoRecorderConfigInternal sharedInstance] getMaxRecordDurationMs] / 1000.0f;
    _encodeConfig = [[VideoRecorderEncodeConfig alloc] initWithVideoQuality:[[VideoRecorderConfigInternal sharedInstance] getVideoQuality]];
    _settings = [[VideoRecorderBeautifySettings alloc] init];
    _zoom = 1.0;
    _recordForEdit = YES;
    _recordCore = [[UGCReflectVideoRecordCore alloc] init];
    if (_recordCore == nil) {
        NSLog(@"Because it does not rely on the LiteAV module, the UGC video recorder cannot be used. Instead, the system video recorder can be used. For more details, please refer to the relevant documentation");
        _recordCore = [[SystemVideoRecordCore alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [self initUI];
}

#pragma mark - UI Init

- (void)initUI {
    self.view.backgroundColor = UIColor.blackColor;

    _ctrlView = [[VideoRecorderControlView alloc] initWithFrame:self.view.bounds];
    _ctrlView.delegate = self;
    [self.view addSubview:_ctrlView];
    
    _videoPlayerView = [[VideoRecorderPreviewView alloc] init];
    [self.view addSubview:_videoPlayerView];
    _videoPlayerView.hidden = YES;
    _videoPlayerView.delegate = self;
    
    CGRect frame = CGRectMake(0, self.view.frame.size.height - 250, self.view.frame.size.width, 250);
    _beautifyView = [[VideoRecorderBeautifyView alloc] initWithFrame:frame settings:_settings];
    _beautifyView.delegate = self;
    _beautifyView.hidden = YES;
    [self.view addSubview:_beautifyView];
    
    [self startPreview];
    [self addGestureRecognizer];
    [self addEdgePanGesture];

    UIPinchGestureRecognizer *pinchRec = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinch:)];
    [_ctrlView addGestureRecognizer:pinchRec];
}

- (void)startPreview {
    NSDictionary *config = @{
        @"videoResolution": @([_encodeConfig getVideoRecordResolution]),
        @"videoFPS": @(_encodeConfig.fps),
        @"videoBitratePIN": @(_encodeConfig.bitrate),
        @"minDuration": @(_minDurationSeconds),
        @"maxDuration": @(_maxDurationSeconds),
        @"frontCamera":@(_isUsingFrontCamera)
    };
    
    [self setAspectRatio];
    [_recordCore startCameraCustom:config preview:_ctrlView.previewView];
    
    [self beautifyController:_settings];
}

- (void)viewWillAppear:(BOOL)animated {
    [self startPreview];
    if (self.navigationController != nil) {
        _originNavgationBarHidden = self.navigationController.navigationBarHidden;
        self.navigationController.navigationBarHidden = YES;
    }
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [_recordCore stopCameraPreview];
    _ctrlView.flashState = NO;
    if (self.navigationController != nil) {
        self.navigationController.navigationBarHidden = _originNavgationBarHidden;
    }
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)appDidBecomeActive {
    [_videoPlayerView resume];
    [self startPreview];
}

- (void)appWillResignActive {
    [_recordCore stopCameraPreview];
    [_videoPlayerView pause];
    _ctrlView.flashState = NO;
}

- (void)presentSimpleAlertWithTitle:(NSString *)title message:(NSString *)message onOk:(void (^)(void))onOk {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *_Nonnull action) {
                                                            if (onOk != nil) {
                                                                onOk();
                                                            }
                                                          }];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)takePhoto {
    int res = [_recordCore snapshot:^(UIImage *image) {
        NSLog(@"take photo complete");
        [self privewPhoto:image];
        self->_ctrlView.flashState = NO;
    }];
    if (res == -5) {
        [VideoRecorderAuthorizationPrompterController showPrompterDialogInViewController:self prompType:NoSignature];
    }
}

- (void) privewPhoto:(UIImage *)image {
    _videoPlayerView.hidden = NO;
    _videoPlayerView.frame = self.view.frame;
    [_videoPlayerView previewPhoto:image];
}

- (void) setAspectRatio {
    switch (_ctrlView.aspectRatio) {
        case VideoRecorderRecordAspectRatio3_4: {
            [_recordCore setAspectRatio:VIDEO_ASPECT_RATIO_3_4];
            break;
        }
        case VideoRecorderRecordAspectRatio9_16: {
            [_recordCore setAspectRatio:VIDEO_ASPECT_RATIO_9_16];
            break;
        }
        default:;
    }
}

#pragma mark - UIPinchGestureRecognizer
- (void)onPinch:(UIPinchGestureRecognizer *)rec {
    _zoom = MIN(MAX(_zoom * rec.scale, 1.0), 5.0);
    rec.scale = 1;
    [_recordCore setZoom:_zoom];
}

#pragma mark - VideoRecorderRecordControlViewDelegate protocol
- (void)recordControlViewOnAspectChange {
    if ([_recordCore isKindOfClass:SystemVideoRecordCore.class]) {
        [VideoRecorderAuthorizationPrompterController showPrompterDialogInViewController:self prompType:NoLiteavProSdk];
        return;
    }
    [self setAspectRatio];
}

- (void)recordControlViewOnCameraSwicth:(BOOL)isUsingFrontCamera {
    [_recordCore switchCamera:isUsingFrontCamera];
    _isUsingFrontCamera = isUsingFrontCamera;
}

- (void)recordControlViewOnExit {
    [_recordCore stopCameraPreview];
    _ctrlView.flashState = NO;
    if (_resultCallback != nil) {
        _resultCallback(nil, nil, 0);
    }
}

- (void)recordControlViewOnFlashStateChange:(BOOL)flashState {
    [_recordCore toggleTorch:flashState];
}

- (void)recordControlViewOnRecordStart {
    _recordCore.recordDelegate = self;
    int res = [_recordCore startRecord:_recordFilePath];
    NSLog(@"record start. res = %d", res);
    if (res == -5) {
        [VideoRecorderAuthorizationPrompterController showPrompterDialogInViewController:self prompType:NoSignature];
    }
    _recordDuration = 0;
    return;
}

- (void)recordControlViewOnRecordFinish {
    [_recordCore stopRecord];
    _ctrlView.flashState = NO;
}

- (void)recordControlViewPhoto {
    [self takePhoto];
}

- (void)recordControlViewOnBeautify {
    if (_beautifyView.hidden) {
        _ctrlView.recordTipHidden = YES;
        _beautifyView.hidden = NO;
    } else {
        _beautifyView.hidden = YES;
        _ctrlView.recordTipHidden = NO;
    }
    
    if ([_recordCore isKindOfClass:SystemVideoRecordCore.class]) {
        [VideoRecorderAuthorizationPrompterController showPrompterDialogInViewController:self prompType:NoLiteavProSdk];
        return;
    }
    
    if ([[VideoRecordSignatureChecker shareInstance] getSetSignatureResult] != VIDEO_RECORD_SIGNATURE_SUCCESS) {
        [VideoRecorderAuthorizationPrompterController showPrompterDialogInViewController:self prompType:NoSignature];
        return;
    }
}

#pragma mark - TXUGCRecordListener protocol
- (void)onRecordProgress:(NSInteger)milliSecond {
    if (milliSecond == 0) {
        return;
    }
    
    _recordDuration = milliSecond / 1000.0;
    [_ctrlView setProgress:_recordDuration / _maxDurationSeconds duration:_recordDuration];
    if (milliSecond / 1000.0 >= _maxDurationSeconds) {
        [_recordCore stopRecord];
        _ctrlView.flashState = NO;
    }
}

- (void)onRecordComplete:(VideoRecordResult *)result {
    [_recordCore deleteTempFile];
    if (result.retCode == VIDEO_RECORD_RESULT_FAILED) {
        NSString *title = [VideoRecorderCommon localizedStringForKey:@"record_failed"];
        [self presentSimpleAlertWithTitle:title
                                  message:@""
                                     onOk:^{
                                       [self startPreview];
                                     }];
        return;
    }

    NSLog(@"on record complete record duration: %f", _recordDuration);
    if (_recordDuration < _minDurationSeconds) {
        if ([[VideoRecorderConfigInternal sharedInstance] getRecordeMode] == MIXED_RECORD_MODE) {
            [self takePhoto];
        }
        return;
    }

    _recorderResult = result;
    _videoPlayerView.hidden = NO;
    _videoPlayerView.frame = self.view.frame;
    _ctrlView.hidden = YES;
    [_videoPlayerView play:result.videoPath];
}

#pragma mark - VideoPreviewViewDelegate
- (void)previewAccept:(NSString*) videoPath image:(UIImage*) image {
    if (_resultCallback != nil) {
        _resultCallback(videoPath, image, self->_recordDuration * 1000);
    }
}

- (void)previewCancel {
    NSLog(@"VideoPreviewViewDelegate cancle");
    _videoPlayerView.hidden = YES;
    _ctrlView.hidden = NO;
}


#pragma mark - VideoRecorderBeautifyViewDelegate protocol
- (void)beautifyView:(VideoRecorderBeautifyView *)beautifyView onSettingsChange:(VideoRecorderBeautifySettings *)settings {
    [self beautifyController:settings];
}

- (void)beautifyController:(VideoRecorderBeautifySettings *)settings {
    VideoRecorderBeautyManager *manager = [_recordCore getBeautyManager];
    [manager setBeautyStyle:TXBeautyStyleSmooth];
    __auto_type convertStrength = ^(int strength, float min, float max) {
      float ratio = ((float)strength - VideoRecorderEffectSliderMin) / (VideoRecorderEffectSliderMax - VideoRecorderEffectSliderMin);
      return ratio * (max - min) + min;
    };
    __auto_type convertBeautifyStrength = ^(int strength) {
      return convertStrength(strength, VideoRecorderBeautifyStrengthMin, VideoRecorderBeautifyStrengthMax);
    };
    __auto_type convertFilterStrength = ^(int strength) {
      return convertStrength(strength, VideoRecorderFilterStrengthMin, VideoRecorderFilterStrengthMax);
    };
    if (settings.activeBeautifyTag == VideoRecorderEffectItemTagNone) {
        [manager setBeautyLevel:0];
    }
    for (VideoRecorderBeautifyEffectItem *item in settings.beautifyItems) {
        float strength = convertBeautifyStrength(item.strength);
        if (settings.activeBeautifyTag == item.tag) {
            switch (item.tag) {
                case VideoRecorderEffectItemTagSmooth:
                    [manager setBeautyStyle:TXBeautyStyleSmooth];
                    break;
                case VideoRecorderEffectItemTagNatural:
                    [manager setBeautyStyle:TXBeautyStyleNature];
                    break;
                case VideoRecorderEffectItemTagPitu:
                    [manager setBeautyStyle:TXBeautyStylePitu];
                    break;
            }
            [manager setBeautyLevel:strength];
        }
        switch (item.tag) {
            case VideoRecorderEffectItemTagWhiteness:
                [manager setWhitenessLevel:strength];
                break;
            case VideoRecorderEffectItemTagRuddy:
                [manager setRuddyLevel:strength];
                break;
        }
    }
    NSInteger idx = settings.activeFilterIndex;
    if (idx >= 0 && idx < settings.filterItems.count) {
        float strength = convertFilterStrength(settings.filterItems[idx].strength);
        [manager setFilter:settings.filterItems[idx].filterMapImage];
        [manager setFilterStrength:strength];
    } else {
        [manager setFilter:nil];
    }
}

- (void) addGestureRecognizer {
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]
                                        initWithTarget:self
                                        action:@selector(handleSingleTap:)];
    [_ctrlView.previewView addGestureRecognizer:singleTap];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    if (!_beautifyView.hidden) {
        _beautifyView.hidden = YES;
        _ctrlView.recordTipHidden = NO;
    }
}

- (void)removeEdgePanGesture {
    if (_edgePanGesture) {
        [self.view removeGestureRecognizer:_edgePanGesture];
        _edgePanGesture = nil;
    }
}
- (void)addEdgePanGesture {
    _edgePanGesture = [[UIScreenEdgePanGestureRecognizer alloc]
                                                        initWithTarget:self
                                                        action:@selector(handleEdgePanGesture:)];
    _edgePanGesture.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:_edgePanGesture];
}

- (void)handleEdgePanGesture:(UIScreenEdgePanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.view];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            break;
        case UIGestureRecognizerStateChanged: {
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            CGFloat xVelocity = [gesture velocityInView:self.view].x;
            CGFloat xProgress = fabs(translation.x / self.view.bounds.size.width);
            
            CGFloat yVelocity = [gesture velocityInView:self.view].y;
            CGFloat yProgress = fabs(translation.y / self.view.bounds.size.height);
            
            if (xProgress > 0.5 || xVelocity > 1000 || yVelocity > 0.5 || yProgress > 1000) {
                if (_resultCallback) {
                    _resultCallback(nil, nil, 0);
                }
            }
            break;
        }
        default:
            break;
    }
}


@end

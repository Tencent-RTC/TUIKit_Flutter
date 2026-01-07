// Copyright (c) 2021 Tencent. All rights reserved.
// Author: eddardliu

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "SystemVideoRecordCore.h"

@interface SystemVideoRecordCore() <AVCaptureFileOutputRecordingDelegate> {
    AVCaptureSession *_captureSession;
    AVCaptureDeviceInput *_videoInput;
    AVCaptureDeviceInput *_audioInput;
    AVCaptureStillImageOutput *_stillImageOutput;
    AVCaptureMovieFileOutput *_movieFileOutput;
    AVCaptureVideoPreviewLayer *_previewLayer;
    AVCaptureDevice *_currentCamera;
    NSInteger _recordTime;
    NSTimer *_recordTimer;
    NSURL *_outputFileURL;
    
    NSDictionary* _configDict;
    
    int _minDuration;
    int _maxDuration;
    int _videoBitrate;
    int _videoFPS;
    BOOL _isFrontCamera;
    CGSize _videoResolution;
}
@end

@implementation SystemVideoRecordCore

- (instancetype)init {
    return  [super init];
}

- (int)startCameraCustom:(NSDictionary *)configDict preview:(UIView *)preview {
    NSLog(@"start camera custom");
    if (_captureSession) {
        NSLog(@"start camera already");
        return 0;
    }

    _isFrontCamera = [configDict[@"frontCamera"] boolValue];
    _minDuration = [configDict[@"minDuration"] intValue] * 1000;
    _maxDuration = [configDict[@"maxDuration"] intValue] * 1000;
    _videoFPS = [configDict[@"videoFPS"] intValue];
    _videoBitrate = [configDict[@"videoBitratePIN"] intValue] * 1024;
    int compress = [configDict[@"videoResolution"] intValue];
    _videoResolution = [self getResolutionFromCompress:(VideoRecordResolution)compress];
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    
    [_captureSession beginConfiguration];
    if(![self setupVideoInput] || ![self setupAudioInput] || ![self setupVideoOutput] || ![self setupImageOutput]) {
        [_captureSession commitConfiguration];
        NSLog(@"start camera setup fail");
        return -1;
    }
    [self setVideoResolution:_videoResolution];
    [self setVideoFrameRate:_videoFPS];
    [_captureSession commitConfiguration];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf setupPreview:preview];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [strongSelf->_captureSession startRunning];
        });
    });
    return 0;
}

- (BOOL)switchCamera:(BOOL)isFront {
    NSLog(@"switch camera isFront:%b",isFront);
    
    if (isFront == _isFrontCamera) {
        return TRUE;
    }
    _isFrontCamera = isFront;
    
    if (!_captureSession.isRunning) {
        return FALSE;
    }
    
    [_captureSession beginConfiguration];
    [_captureSession removeInput:_videoInput];
    _currentCamera = nil;
    if (![self setupVideoInput]) {
        NSLog(@"Failed to switch to %s camera, restore to %s camera",(isFront ? "front" : "back"), (!isFront ? "front" : "back"));
        _isFrontCamera = !isFront;
        [self setupVideoInput];
    }
    [_captureSession commitConfiguration];
    //_currentCamera.videoZoomFactor = 1.0;
    return YES;
}

- (BOOL)toggleTorch:(BOOL)enable {
    if ([_currentCamera hasTorch]) {
        NSError *error;
        if ([_currentCamera lockForConfiguration:&error]) {
            _currentCamera.torchMode = enable ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
            [_currentCamera unlockForConfiguration];
            return YES;
        }
    }
    return NO;
}

- (void)setZoom:(CGFloat)distance {
    CGFloat maxZoom = _currentCamera.activeFormat.videoMaxZoomFactor;
    CGFloat zoomFactor = MIN(MAX(distance, 1.0), maxZoom);
    
    NSError *error;
    if ([_currentCamera lockForConfiguration:&error]) {
        _currentCamera.videoZoomFactor = zoomFactor;
        [_currentCamera unlockForConfiguration];
    }
}

- (void)stopCameraPreview {
    NSLog(@"stopCameraPreview");
    if ([_captureSession isRunning]) {
        [_captureSession stopRunning];
    }
    _captureSession = nil;
    _currentCamera = nil;
    _movieFileOutput = nil;
    _stillImageOutput = nil;
}

- (int)startRecord:(NSString*) path {
    if (_movieFileOutput.isRecording) {
        return -1;
    }
    
    _outputFileURL = [NSURL fileURLWithPath:path];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    [self setVideoBitrate:_videoBitrate];
    [_movieFileOutput startRecordingToOutputFileURL:_outputFileURL recordingDelegate:self];
    
    _recordTime = 0;
    _recordTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                    target:self
                                                  selector:@selector(updateRecordTime)
                                                  userInfo:nil
                                                   repeats:YES];
    return 0;
}

- (int)stopRecord {
    if (!_movieFileOutput.isRecording) {
        return -1;
    }
    
    [_movieFileOutput stopRecording];
    [_recordTimer invalidate];
    _recordTimer = nil;
    
    return 0;
}

- (int)snapshot:(void (^)(UIImage *))snapshotCompletionBlock {
    if (!_captureSession.isRunning) {
        if (snapshotCompletionBlock) snapshotCompletionBlock(nil);
        return -1;
    }
    
    if (!_stillImageOutput) {
        if (snapshotCompletionBlock) snapshotCompletionBlock(nil);
        return -2;
    }
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _stillImageOutput.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            if ([port.mediaType isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) break;
    }
    
    if (!videoConnection) {
        if (snapshotCompletionBlock) snapshotCompletionBlock(nil);
        return -3;
    }
    
    videoConnection.videoMirrored = _isFrontCamera;
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                   completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        UIImage *image = nil;
        
        if (!error && imageDataSampleBuffer) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            image = [UIImage imageWithData:imageData];
        }
        
        if (snapshotCompletionBlock) {
            snapshotCompletionBlock(image);
        }
    }];
    
    return 0;
}

#pragma mark - Private Methods

- (void)updateRecordTime {
    _recordTime += 100;
    if (self.recordDelegate != nil) {
        [self.recordDelegate onRecordProgress:_recordTime];
    }
    
    if (_recordTime > _maxDuration) {
        NSLog(@"Reaching maximum recording time");
        [self stopRecord];
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)output
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray<AVCaptureConnection *> *)connections
                error:(NSError *)error {
    [_recordTimer invalidate];
    _recordTimer = nil;
    
    VideoRecordResult* videoRecordResult = [[VideoRecordResult alloc] init];
    videoRecordResult.retCode =  _recordTime > _maxDuration ? VIDEO_RECORD_RESULT_OK_BEYOND_MAXDURATION : VIDEO_RECORD_RESULT_OK;
    videoRecordResult.videoPath = [outputFileURL path];
    
    if (error) {
        videoRecordResult.retCode =  VIDEO_RECORD_RESULT_FAILED;
        videoRecordResult.videoPath = nil;
    }

    
    if (self.recordDelegate != nil) {
        [self.recordDelegate onRecordComplete:videoRecordResult];
    }
}

- (BOOL) setupVideoInput {
    if (!_captureSession) {
        return FALSE;
    }
    
    if (_currentCamera) {
        return TRUE;
    }
    
    _currentCamera = [self getCaptureDevice:_isFrontCamera];
    if (!_currentCamera) {
        return FALSE;
    }
    
    NSError *error;
    _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:_currentCamera error:&error];
    if (error || !_videoInput) {
        return FALSE;
    }
    
    if ([_captureSession canAddInput:_videoInput]) {
        [_captureSession addInput:_videoInput];
        return TRUE;
    }
    
    return FALSE;
}

- (AVCaptureDevice *)getCaptureDevice:(BOOL) isFront {
    AVCaptureDevicePosition position = isFront ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    
    NSArray *deviceTypes = @[];
    if (@available(iOS 10.2, *)) {
        deviceTypes = @[
            AVCaptureDeviceTypeBuiltInDualCamera,
            AVCaptureDeviceTypeBuiltInWideAngleCamera,
            AVCaptureDeviceTypeBuiltInTelephotoCamera
        ];
    } else {
        deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera];
    }
    
    AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession
                                                discoverySessionWithDeviceTypes:deviceTypes
                                                mediaType:AVMediaTypeVideo
                                                position:position];
    return session.devices.firstObject;
}

- (BOOL) setupAudioInput {
    if (!_captureSession) {
        return FALSE;
    }
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    if (!audioDevice) {
        [_captureSession commitConfiguration];
        return FALSE;
    }
    
    NSError *error;
    _audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (error || !_audioInput) {
        return FALSE;
    }
    
    if ([_captureSession canAddInput:_audioInput]) {
        [_captureSession addInput:_audioInput];
        return TRUE;
    }
    
    return FALSE;
}

- (BOOL) setupVideoOutput {
    if (_movieFileOutput) {
        return TRUE;
    }
    
    _movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([_captureSession canAddOutput:_movieFileOutput]) {
        [_captureSession addOutput:_movieFileOutput];
        return TRUE;
    }
    
    return FALSE;
}

- (BOOL) setupImageOutput {
    if (_stillImageOutput) {
        return TRUE;
    }
    
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = @{
        AVVideoCodecKey: AVVideoCodecJPEG,
        AVVideoQualityKey: @(0.9)
    };
    [_stillImageOutput setOutputSettings:outputSettings];
    
    if ([_captureSession canAddOutput:_stillImageOutput]) {
        [_captureSession addOutput:_stillImageOutput];
        return TRUE;
    }
    
    return FALSE;
}

- (void)setupPreview:(UIView *)preview {
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame = preview.bounds;
    [preview.layer addSublayer:_previewLayer];
    [preview.layer setMasksToBounds:YES];
}

- (void)setVideoResolution:(CGSize)resolution {
    if (CGSizeEqualToSize(resolution, CGSizeMake(1920, 1080))) {
        [_captureSession setSessionPreset:AVCaptureSessionPreset1920x1080];
    } else if (CGSizeEqualToSize(resolution, CGSizeMake(1280, 720))) {
        [_captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    } else {
        [_captureSession setSessionPreset:AVCaptureSessionPresetInputPriority];
        
        AVCaptureDevice *camera = _currentCamera;
        if ([camera lockForConfiguration:nil]) {
            for (AVCaptureDeviceFormat *format in camera.formats) {
                CMVideoDimensions dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
                if (dims.width == resolution.width && dims.height == resolution.height) {
                    camera.activeFormat = format;
                    break;
                }
            }
            [camera unlockForConfiguration];
        }
    }
}

- (void)setVideoBitrate:(NSInteger)bitrate {
    AVCaptureConnection *videoConnection = [_movieFileOutput connectionWithMediaType:AVMediaTypeVideo];

    NSDictionary *videoSettings = @{
        AVVideoCodecKey: AVVideoCodecH264,
        AVVideoCompressionPropertiesKey: @{
            AVVideoAverageBitRateKey: @(bitrate),
            //AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel,
            //AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCAVLC
        }
    };
    
    if ([_movieFileOutput respondsToSelector:@selector(setOutputSettings:forConnection:)]) {
        [_movieFileOutput setOutputSettings:videoSettings forConnection:videoConnection];
    }
}

- (void)setVideoFrameRate:(NSInteger)frameRate {
    NSError *error;
    if (![_currentCamera lockForConfiguration:&error]) {
        NSLog(@"lock for configuration fail.error: %@", error);
        [_currentCamera unlockForConfiguration];
        return;
    }
    
    AVFrameRateRange *desiredRange = nil;
    for (AVFrameRateRange *range in _currentCamera.activeFormat.videoSupportedFrameRateRanges) {
        if (range.minFrameRate <= frameRate && frameRate <= range.maxFrameRate) {
            desiredRange = range;
            break;
        }
    }
    
    if (desiredRange) {
        _currentCamera.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)frameRate);
        _currentCamera.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)frameRate);
    } else {
        NSLog(@"do not surpport %ld fps", (long)frameRate);
    }
    [_currentCamera unlockForConfiguration];
}


-(CGSize) getResolutionFromCompress:(VideoRecordResolution)compress {
    switch (compress) {
        case VIDEO_RESOLUTION_360_640:
            return CGSizeMake(640, 360);
        case VIDEO_RESOLUTION_540_960:
            return CGSizeMake(960, 540);
        case VIDEO_RESOLUTION_720_1280:
            return CGSizeMake(1280, 720);
        case VIDEO_RESOLUTION_1080_1920:
        default:
            return CGSizeMake(1920, 1080);
    }
}
@end

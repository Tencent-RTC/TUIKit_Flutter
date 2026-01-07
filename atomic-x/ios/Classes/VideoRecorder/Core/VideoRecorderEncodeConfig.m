// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import "VideoRecorderEncodeConfig.h"

#define VideoRecorder_VideoQuality_Low 1
#define VideoRecorder_VideoQuality_Medium 2
#define VideoRecorder_VideoQuality_High 3

@interface VideoRecorderEncodeConfig () {
    int _videoQuality;
}
@end

@implementation VideoRecorderEncodeConfig
- (instancetype)init {
    return [self initWithVideoQuality:VideoRecorder_VideoQuality_Medium];
}

- (instancetype)initWithVideoQuality:(int)videoQuality {
    switch (videoQuality) {
        case VideoRecorder_VideoQuality_Low:
            _bitrate = 1000;
            _fps = 25;
            break;
        case VideoRecorder_VideoQuality_High:
            _bitrate = 5000;
            _fps = 30;
            break;
        case VideoRecorder_VideoQuality_Medium:
        default:
            _bitrate = 3000;
            _fps = 25;
            break;
    }
    _videoQuality = videoQuality;
    return self;
}

- (VideoRecordCompressed)getVideoEditCompressed {
    switch (_videoQuality) {
        case VideoRecorder_VideoQuality_High:
            return VIDEO_COMPRESSED_1080P;
        case VideoRecorder_VideoQuality_Low:
        case VideoRecorder_VideoQuality_Medium:
        default:
            return VIDEO_COMPRESSED_720P;
    }
}

- (VideoRecordResolution)getVideoRecordResolution {
    switch (_videoQuality) {
        case VideoRecorder_VideoQuality_High:
            return VIDEO_RESOLUTION_1080_1920;
        case VideoRecorder_VideoQuality_Low:
        case VideoRecorder_VideoQuality_Medium:
        default:
            return VIDEO_RESOLUTION_720_1280;
    }
}
@end

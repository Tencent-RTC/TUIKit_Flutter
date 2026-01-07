// Copyright (c) 2024 Tencent. All rights reserved.
// Created by eddardliu on 2024/10/21.


#import "VideoRecorderConfigInternal.h"
#import "VideoRecorderCommon.h"

#define DEFAULT_CONFIG_FILE @"video_recorder_config"

@interface VideoRecorderConfigInternal() {
    NSDictionary * _jsonDicFromConfigFile;
    NSDictionary * _jsonDicFromSetting;
}
@end

@implementation VideoRecorderConfigInternal

+ (instancetype)sharedInstance {
    static VideoRecorderConfigInternal *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init{
    self = [super init];
    NSBundle* modleNSBundle = VideoRecorderCommon.modleNSBundle;
    if (modleNSBundle == nil) {
        return self;
    }
    
    NSData *jsonData = [NSData dataWithContentsOfFile:[modleNSBundle pathForResource:DEFAULT_CONFIG_FILE ofType:@"json"]];
    if (jsonData == nil) {
        return self;
    }
    NSLog(@"jsonData : %@" , jsonData);
    
    NSError *err = nil;
    _jsonDicFromConfigFile = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if (err || ![_jsonDicFromConfigFile isKindOfClass:[NSDictionary class]]) {
        NSLog(@"[VideoRecorder] Json parse failed: %@", err);
        _jsonDicFromConfigFile = nil;
    }
    return self;
}

- (void)setCustomConfig:(NSString*)jsonString {
    if (jsonString == nil) {
        return;
    }
    
    NSError *err = nil;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData) {
        _jsonDicFromSetting = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
        if (err || ![_jsonDicFromSetting isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[VideoRecorderConfig setConfig]  Json parse failed: %@", err);
            _jsonDicFromSetting = nil;
        }
    } else {
        NSLog(@"Error converting string to data");
    }
}

- (BOOL)isSupportRecordBeauty {
    return [self getBoolFromDic:@"support_record_beauty" defaultValue:YES];
}

- (BOOL)isSupportRecordAspect {
    return [self getBoolFromDic:@"support_record_aspect" defaultValue:YES];
}

- (BOOL)isSupportRecordTorch {
    return [self getBoolFromDic:@"support_record_torch" defaultValue:YES];
}

- (BOOL)isSupportRecordScrollFilter {
    return [self getBoolFromDic:@"support_record_scroll_filter" defaultValue:YES];
}

- (UIColor *)getThemeColor {
    NSString* colorName = [self getStringFromDic:@"primary_theme_color" defaultValue:@"#147AFF"];
    return [VideoRecorderCommon tui_colorWithHex:colorName];
}

- (int)getVideoQuality {
    return [self getIntFromDic:@"video_quality" defaultValue:2];
}

- (BOOL)isDefaultFrontCamera {
    return [self getBoolFromDic:@"is_default_front_camera" defaultValue:false];
}

- (int)getMaxRecordDurationMs {
    return [self getIntFromDic:@"max_record_duration_ms" defaultValue:15000];
}

- (int)getMinRecordDurationMs {
    return [self getIntFromDic:@"min_record_duration_ms" defaultValue:2000];
}

// record mode. 0:mixed, 1:onlyPhoto 2:onlyVideo
- (int) getRecordeMode {
    return [self getIntFromDic:@"record_mode" defaultValue:0];
}

-(BOOL) getBoolFromDic:(NSString*) dicKey defaultValue:(BOOL) defaultValue{
    if (_jsonDicFromSetting != nil && [_jsonDicFromSetting valueForKey:dicKey]) {
        return [_jsonDicFromSetting[dicKey] caseInsensitiveCompare:@"true"] == NSOrderedSame;
    }
    
    if (_jsonDicFromConfigFile != nil && [_jsonDicFromConfigFile valueForKey:dicKey]) {
        return [_jsonDicFromConfigFile[dicKey] caseInsensitiveCompare:@"true"] == NSOrderedSame;
    }
    return defaultValue;
}

-(int) getIntFromDic:(NSString*) dicKey defaultValue:(int) defaultValue{
    if (_jsonDicFromSetting != nil && [_jsonDicFromSetting valueForKey:dicKey] != nil) {
        return [(NSNumber *)_jsonDicFromSetting[dicKey] intValue];
    }
    
    if (_jsonDicFromConfigFile != nil && [_jsonDicFromConfigFile valueForKey:dicKey] != nil) {
        return [(NSNumber *)_jsonDicFromConfigFile[dicKey] intValue];
    }
    return defaultValue;
}

-(NSString*) getStringFromDic:(NSString*) dicKey defaultValue:(NSString*) defaultValue{
    if (_jsonDicFromSetting != nil && [_jsonDicFromSetting valueForKey:dicKey] != nil) {
        return _jsonDicFromSetting[dicKey];
    }
    
    if (_jsonDicFromConfigFile != nil && [_jsonDicFromConfigFile valueForKey:dicKey] != nil) {
        return _jsonDicFromConfigFile[dicKey];
    }
    return defaultValue;
}

@end

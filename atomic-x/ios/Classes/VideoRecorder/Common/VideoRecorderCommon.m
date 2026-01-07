// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import "VideoRecorderCommon.h"
#import "VideoRecorderNSArray+Functional.h"

#define ChatEngineLanguageKey @"AtomicXLanguageKey"
#define BundleResourceUrlPrefix  @"file:///asset/"

@interface NSString (TUIHexColorPrivate)
- (NSUInteger)_hexValue;
@end

@implementation NSString (TUIHexColorPrivate)
- (NSUInteger)_hexValue {
    NSUInteger result = 0;
    sscanf([self UTF8String], "%lx", &result);
    return result;
}
@end

@implementation VideoRecorderCommon

@dynamic assetsBundle;

+ (NSBundle *)assetsBundle {
    // 在 Flutter 插件中，直接返回当前 bundle
    NSBundle *currentBundle = [NSBundle bundleForClass:[self class]];
    if (!currentBundle) {
        NSLog(@"error: can not find current bundle");
        return nil;
    }
    return currentBundle;
}

+ (NSBundle *)stringBundle {
    // 在 Flutter 插件中，直接返回当前 bundle
    NSBundle *currentBundle = [NSBundle bundleForClass:[self class]];
    if (!currentBundle) {
        NSLog(@"error: can not find current bundle");
        return nil;
    }
    return currentBundle;
}

+ (NSBundle *)modleNSBundle {
    // 在 Flutter 插件中，直接返回当前 bundle
    NSBundle *currentBundle = [NSBundle bundleForClass:[self class]];
    return currentBundle;
}

+ (UIImage *)bundleImageByName:(NSString *)name {
    NSBundle *bundle = [self modleNSBundle];
    if (bundle == nil) {
        return nil;
    }
    // 在 Flutter 插件中，从 Assets/videorecorder.xcassets 加载图片
    return [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
}

+ (UIImage *)bundleRawImageByName:(NSString *)name {
    NSBundle *bundle = [self assetsBundle];
    if (bundle == nil) {
        return nil;
    }
    // 尝试从 Assets/videorecorder.xcassets 目录加载
    NSString *path = [NSString stringWithFormat:@"%@/Assets/videorecorder.xcassets/%@", bundle.resourcePath, name];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    if (image) {
        return image;
    }
    // 如果找不到，尝试直接从 bundle 加载
    return [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
}

+ (NSString *)localizedStringForKey:(NSString *)key {
    NSString *lang = [self getPreferredLanguage];
    NSBundle *bundle = [self stringBundle];
    if (bundle == nil) {
        NSLog(@"[VideoRecorderCommon] Error: stringBundle is nil");
        return key;
    }
    
    // 在 Flutter 插件中，bundle 资源会被打包到 framework 的根目录
    // 先尝试从根目录加载（编译后的 framework 路径）
    NSString *bundlePath = [bundle.resourcePath stringByAppendingPathComponent:@"VideoRecorderLocalizable.bundle"];
    NSBundle *localizableBundle = [NSBundle bundleWithPath:bundlePath];
    
    // 如果根目录找不到，尝试从 Assets 子目录加载（开发模式路径）
    if (localizableBundle == nil) {
        bundlePath = [bundle.resourcePath stringByAppendingPathComponent:@"Assets/VideoRecorderLocalizable.bundle"];
        localizableBundle = [NSBundle bundleWithPath:bundlePath];
    }
    
    NSLog(@"[VideoRecorderCommon] Looking for bundle at: %@", bundlePath);
    
    if (localizableBundle) {
        NSLog(@"[VideoRecorderCommon] Found localizable bundle, looking for language: %@", lang);
        NSString *lprojPath = [localizableBundle pathForResource:lang ofType:@"lproj"];
        if (lprojPath == nil) {
            NSLog(@"[VideoRecorderCommon] Language %@ not found, falling back to 'en'", lang);
            lprojPath = [localizableBundle pathForResource:@"en" ofType:@"lproj"];
        }
        if (lprojPath) {
            NSLog(@"[VideoRecorderCommon] Found lproj at: %@", lprojPath);
            NSBundle *langBundle = [NSBundle bundleWithPath:lprojPath];
            NSString *localizedString = [langBundle localizedStringForKey:key value:nil table:nil];
            if (localizedString && ![localizedString isEqualToString:key]) {
                NSLog(@"[VideoRecorderCommon] Found translation for key '%@': %@", key, localizedString);
                return localizedString;
            } else {
                NSLog(@"[VideoRecorderCommon] No translation found for key: %@", key);
            }
        } else {
            NSLog(@"[VideoRecorderCommon] Error: lproj path not found for language: %@", lang);
        }
    } else {
        NSLog(@"[VideoRecorderCommon] Error: localizableBundle not found at path: %@", bundlePath);
    }
    
    // 如果找不到，返回 key 本身
    return key;
}

+ (UIColor *)colorFromHex:(NSString *)hex {
    return [VideoRecorderCommon tui_colorWithHex:hex];
}

+ (NSArray<NSString *> *)sortedBundleResourcesIn:(NSString *)directory withExtension:(NSString *)ext {
    if (VideoRecorderCommon.assetsBundle == nil) {
        return nil;
    }
    
    NSArray<NSString *> *res = [VideoRecorderCommon.assetsBundle pathsForResourcesOfType:ext inDirectory:directory];
    NSString *basePath = VideoRecorderCommon.assetsBundle.resourcePath;
    res = [res video_recorder_map:^NSString *(NSString *path) {
      return [path substringFromIndex:basePath.length + 1];
    }];
    return [res sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
      return [a compare:b];
    }];
}

+ (NSURL *)getURLByResourcePath:(NSString *)path {
    if (path == nil || VideoRecorderCommon.assetsBundle == nil) {
        return nil;
    }
    
    if (![path hasPrefix:BundleResourceUrlPrefix]) {
        NSURL *url = [NSURL URLWithString:path];
        if (url.scheme == nil) {
            return [NSURL fileURLWithPath:path];
        }
        return url;
    }
    NSURL *bundleUrl = [VideoRecorderCommon.assetsBundle resourceURL];
    NSURL *url = [[NSURL alloc] initWithString:[path substringFromIndex:BundleResourceUrlPrefix.length] relativeToURL:bundleUrl];
    return url;
}

+ (UIImage *__nullable)dynamicImage:(NSString *)imageKey defaultImageName:(NSString *)image {
    if (VideoRecorderCommon.modleNSBundle == nil) {
        return nil;
    }
    
    
    return [UIImage imageNamed:image inBundle:VideoRecorderCommon.modleNSBundle compatibleWithTraitCollection:nil];
}

+ (UIColor *)dynamicColor:(NSString *)colorKey  defaultColor:(NSString *)hex {
    return [VideoRecorderCommon tui_colorWithHex:hex];
}

+ (UIColor *)tui_colorWithHex:(NSString *)hex {
    if ([hex isEqualToString:@""]) {
        return [UIColor clearColor];
    }

    // Remove `#` and `0x`
    if ([hex hasPrefix:@"#"]) {
        hex = [hex substringFromIndex:1];
    } else if ([hex hasPrefix:@"0x"]) {
        hex = [hex substringFromIndex:2];
    }

    // Invalid if not 3, 6, or 8 characters
    NSUInteger length = [hex length];
    if (length != 3 && length != 6 && length != 8) {
        return [[UIColor alloc] init];
    }

    // Make the string 8 characters long for easier parsing
    if (length == 3) {
        NSString *r = [hex substringWithRange:NSMakeRange(0, 1)];
        NSString *g = [hex substringWithRange:NSMakeRange(1, 1)];
        NSString *b = [hex substringWithRange:NSMakeRange(2, 1)];
        hex = [NSString stringWithFormat:@"%@%@%@%@%@%@ff", r, r, g, g, b, b];
    } else if (length == 6) {
        hex = [hex stringByAppendingString:@"ff"];
    }

    CGFloat red = [[hex substringWithRange:NSMakeRange(0, 2)] _hexValue] / 255.0f;
    CGFloat green = [[hex substringWithRange:NSMakeRange(2, 2)] _hexValue] / 255.0f;
    CGFloat blue = [[hex substringWithRange:NSMakeRange(4, 2)] _hexValue] / 255.0f;
    CGFloat alpha = [[hex substringWithRange:NSMakeRange(6, 2)] _hexValue] / 255.0f;

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (NSString *)getPreferredLanguage {
    NSString* gCustomLanguage = [NSUserDefaults.standardUserDefaults objectForKey:ChatEngineLanguageKey];
    if (gCustomLanguage != nil && gCustomLanguage.length > 0) {
        // 规范化语言代码，移除国家代码部分（如 zh-Hans_CN -> zh-Hans）
        NSArray *components = [gCustomLanguage componentsSeparatedByString:@"_"];
        NSString *normalizedLanguage = [components firstObject];
        NSLog(@"[VideoRecorderCommon] Using custom language: %@ (normalized: %@)", gCustomLanguage, normalizedLanguage);
        return normalizedLanguage;
    }

    // Follow system changes by default
    NSString *language = [NSLocale preferredLanguages].firstObject;
    if ([language hasPrefix:@"en"]) {
        language = @"en";
    } else if ([language hasPrefix:@"zh"]) {
        if ([language rangeOfString:@"Hans"].location != NSNotFound) {
            // Simplified Chinese
            language = @"zh-Hans";
        } else {
            // Traditional Chinese
            language = @"zh-Hant";
        }
    } else if ([language hasPrefix:@"ar"]) {
        language = @"ar";
    }
    else {
        language = @"en";
    }
    
    NSLog(@"[VideoRecorderCommon] Using system language: %@", language);
    return language;
}

@end

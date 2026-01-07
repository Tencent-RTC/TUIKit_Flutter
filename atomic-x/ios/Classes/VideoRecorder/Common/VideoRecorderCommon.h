// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define VideoRecorderConstCGSize(w, h) ((CGSize){(CGFloat)(w), (CGFloat)(h)})
#define VideoRecorderDynamicColor(colorKey, defaultHex) [VideoRecorderCommon dynamicColor:colorKey defaultColor:defaultHex]
#define VideoRecorderBundleThemeImage(imageName) [VideoRecorderCommon bundleImageByName:imageName]

@interface VideoRecorderCommon : NSObject
@property(class, readonly) NSBundle *assetsBundle;
@property(class, readonly) NSBundle *stringBundle;
+ (NSBundle *)modleNSBundle;
+ (nullable UIImage *)bundleImageByName:(NSString *)name;
+ (nullable UIImage *)bundleRawImageByName:(NSString *)name;
+ (NSString *)localizedStringForKey:(NSString *)key;
+ (NSString *)getPreferredLanguage;
+ (UIColor *)colorFromHex:(NSString *)hex;
+ (NSArray<NSString *> *)sortedBundleResourcesIn:(NSString *)directory withExtension:(NSString *)ext;
+ (NSURL *)getURLByResourcePath:(NSString *)path;
+ (UIColor *__nullable)dynamicColor:(NSString *)colorKey defaultColor:(NSString *)hex;
+ (UIImage *__nullable)dynamicImage:(NSString *)imageKey defaultImageName:(NSString *)image;
+ (UIColor *)tui_colorWithHex:(NSString *)hex;
@end

NS_ASSUME_NONNULL_END

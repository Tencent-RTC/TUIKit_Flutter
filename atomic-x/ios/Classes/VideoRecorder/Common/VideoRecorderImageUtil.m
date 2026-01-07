// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import "VideoRecorderImageUtil.h"

@implementation VideoRecorderImageUtil

+ (UIImage *)simpleImageFromImage:(UIImage *)img withTintColor:(UIColor *)tintColor {
    UIGraphicsBeginImageContextWithOptions(img.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, img.size.width, img.size.height);
    UIRectFill(bounds);

    [img drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return tintedImage;
}

+ (UIImage *)imageFromImage:(UIImage *)img withTintColor:(UIColor *)tintColor {
    UIImage *imgWithTintColor = [self simpleImageFromImage:img withTintColor:tintColor];
    if (img.imageAsset == nil) {
        return imgWithTintColor;
    }
    UITraitCollection *const scaleTraitCollection = [UITraitCollection currentTraitCollection];
    UITraitCollection *const darkUnscaledTraitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
    UITraitCollection *const darkScaledTraitCollection =
        [UITraitCollection traitCollectionWithTraitsFromCollections:@[ scaleTraitCollection, darkUnscaledTraitCollection ]];

    UIImage *imageDark = [img.imageAsset imageWithTraitCollection:darkScaledTraitCollection];
    if (img != imageDark) {
        [imgWithTintColor.imageAsset registerImage:[self simpleImageFromImage:imageDark withTintColor:tintColor] withTraitCollection:darkScaledTraitCollection];
    }

    return imgWithTintColor;
}

+ (UIImage *)createBlueCircleWithWhiteBorder : (CGSize)size withColor:(UIColor*) color{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return nil;
    

    CGContextSetFillColorWithColor(context, [UIColor yellowColor].CGColor);
    
    
    CGFloat centerX = size.width / 2;
    CGFloat centerY = size.width / 2;
    CGFloat radius = size.width / 2;

    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 0);
    CGContextAddArc(context, centerX, centerY, radius, 0, 2 * M_PI, 0);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 0);
    CGContextAddArc(context, centerX, centerY, 5, 0, 2 * M_PI, 0);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
@end

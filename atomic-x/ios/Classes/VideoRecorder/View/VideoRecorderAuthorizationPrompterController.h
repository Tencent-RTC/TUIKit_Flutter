// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AuthorizationPrompterType) {
    NoSignature,
    NoLiteavProSdk
};

@interface VideoRecorderAuthorizationPrompterController : UIViewController
+ (Boolean) isHasSignature;
+ (Boolean) isHasLiteavProSdk;
+ (void) showPrompterDialogInViewController:(UIViewController *)presentingVC prompType:(AuthorizationPrompterType) prompType;
@property (nonatomic) AuthorizationPrompterType prompType;
@end

NS_ASSUME_NONNULL_END

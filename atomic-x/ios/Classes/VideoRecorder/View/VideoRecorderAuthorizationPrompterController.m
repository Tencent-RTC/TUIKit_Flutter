// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import "VideoRecorderAuthorizationPrompterController.h"
#import <SafariServices/SafariServices.h>
#import "VideoRecorderCommon.h"
#import "VideoRecordSignatureChecker.h"
#import "UGCReflectVideoRecordCore.h"

#define IM_MULTIMEDIA_PLUGIN_DOCUMENT_URL @"https://cloud.tencent.com/document/product/269/113290"

@interface VideoRecorderAuthorizationPrompterController () {
    UIButton *_confirmButton;
}

@property (nonatomic, copy) void (^dismissHandler)(void);

@end

@implementation VideoRecorderAuthorizationPrompterController

+ (Boolean) isHasSignature {
    return [[VideoRecordSignatureChecker shareInstance] getSetSignatureResult] == VIDEO_RECORD_SIGNATURE_SUCCESS;
}

+ (Boolean) isHasLiteavProSdk {
    return  [[UGCReflectVideoRecordCore alloc] init] != nil;
}

+ (void)showPrompterDialogInViewController:(UIViewController *)presentingVC prompType:(AuthorizationPrompterType) prompType{
#ifndef DEBUG
    return;
#endif
    
    VideoRecorderAuthorizationPrompterController *dialog = [[VideoRecorderAuthorizationPrompterController alloc] init];
    dialog.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    dialog.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    dialog.prompType = prompType;
    [presentingVC presentViewController:dialog animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    UIView *container = [[UIView alloc] init];
    container.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    container.layer.cornerRadius = 16;
    container.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:container];
    
    UIStackView *titleStack = [[UIStackView alloc] init];
    titleStack.axis = UILayoutConstraintAxisHorizontal;
    titleStack.spacing = 12;
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = [VideoRecorderCommon localizedStringForKey:@"prompter"];
    titleLabel.font = [UIFont systemFontOfSize:20];
    titleLabel.textColor = [UIColor labelColor];
    [titleStack addArrangedSubview:titleLabel];
    
    UILabel *prompter = [[UILabel alloc] init];
    prompter.numberOfLines = 0;
    NSString* prompterKey = @"authorization_prompter_no_signature";
    if (_prompType == NoLiteavProSdk) {
        prompterKey = @"authorization_prompter_no_liteav_sdk";
    }
    prompter.text = [VideoRecorderCommon localizedStringForKey:prompterKey];
    prompter.font = [UIFont systemFontOfSize:14];
    prompter.textColor = [UIColor secondaryLabelColor];
    
    _confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_confirmButton setTitle:[VideoRecorderCommon localizedStringForKey:@"ok"] forState:UIControlStateNormal];
    [_confirmButton addTarget:self
                       action:@selector(confirmAction)
             forControlEvents:UIControlEventTouchUpInside];
    _confirmButton.titleLabel.font = [UIFont systemFontOfSize:16];
    
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        titleStack, prompter, _confirmButton
    ]];
    
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 6;
    stack.alignment = UIStackViewAlignmentLeading;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:stack];
    
    [NSLayoutConstraint activateConstraints:@[
        [container.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [container.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [container.widthAnchor constraintEqualToAnchor:self.view.widthAnchor
                                            multiplier:0.8],
        
        [stack.topAnchor constraintEqualToAnchor:container.topAnchor constant:20],
        [stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-20],
        [stack.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-20],
        
        [_confirmButton.leadingAnchor constraintEqualToAnchor:stack.leadingAnchor]
    ]];
}

- (void)confirmAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView
shouldInteractWithURL:(NSURL *)URL
         inRange:(NSRange)characterRange
     interaction:(UITextItemInteraction)interaction {
    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:URL];
    [self presentViewController:safari animated:YES completion:nil];
    return NO;
}

@end

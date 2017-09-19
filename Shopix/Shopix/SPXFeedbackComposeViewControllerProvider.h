// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@class MFMailComposeViewController;

/// Provider of mail compose view controllers with different contents.
@protocol SPXFeedbackComposeViewControllerProvider <NSObject>

/// Returns a mail compose view controller for sending a feedback mail. \c nil is returned if the
/// mail compose cannot be presented or if the user mail account is not configured.
@property (readonly, nonatomic, nullable) MFMailComposeViewController
    *feedbackComposeViewController;

@end

NS_ASSUME_NONNULL_END

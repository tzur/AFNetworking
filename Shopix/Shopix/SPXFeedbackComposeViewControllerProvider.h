// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark SPXMailComposeViewController
#pragma mark -

/// Protocol for a view controller that provides an interface for editing and sending email.
///
/// @see MFMailComposeViewController+Dismissal for an implementation for
/// \c MFMailComposeViewController.
@protocol SPXMailComposeViewController

/// Signal that sends a \c RACUnit value when the view controller should be dismissed.
@property (readonly, nonatomic) RACSignal<RACUnit *> *dismissRequested;

@end

#pragma mark -
#pragma mark SPXFeedbackComposeViewControllerProvider
#pragma mark -

/// Provider of mail compose view controllers with different contents.
@protocol SPXFeedbackComposeViewControllerProvider <NSObject>

/// Returns a mail compose view controller for sending a feedback mail. \c nil is returned if the
/// mail compose cannot be presented or if the user mail account is not configured.
- (nullable UIViewController<SPXMailComposeViewController> *)createFeedbackComposeViewController;

@end

NS_ASSUME_NONNULL_END

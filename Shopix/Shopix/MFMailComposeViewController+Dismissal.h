// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import <MessageUI/MessageUI.h>

#import "SPXFeedbackComposeViewControllerProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Category that implements \c dismissRequested property in \c MFMailComposeViewController.
@interface MFMailComposeViewController (Dismissal) <SPXMailComposeViewController>
@end

NS_ASSUME_NONNULL_END

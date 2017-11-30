// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import <MessageUI/MessageUI.h>

NS_ASSUME_NONNULL_BEGIN

/// Category that adds a \c dismissBlock property to \c MFMailComposeViewController.
@interface MFMailComposeViewController (Dismissal)

/// Block invoked after the mail composer is dismissed.
@property (nonatomic, nullable) LTVoidBlock spx_dismissBlock;

@end

NS_ASSUME_NONNULL_END

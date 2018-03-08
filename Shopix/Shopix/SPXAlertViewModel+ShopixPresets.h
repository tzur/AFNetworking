// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SPXAlertViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXAlertViewModel (ShopixPresets)

/// Creates a new alert view-model for an alert that should be shown after successful purchase
/// restoration. The alert will have a title, message and a single "OK" button. The alert message
/// indicates whether an active subscription was restored or not based on \c subscriptionRestored.
/// The \c action block is invoked when the "OK" button of the alert is pressed.
+ (instancetype)successfulRestorationAlertWithAction:(LTVoidBlock)action
                                subscriptionRestored:(BOOL)subscriptionRestored;

/// Creates a new alert view-model for an alert that should be shown after failing product
/// information fetching. The alert will have a title, message and 3 buttons, "Try Again" for
/// retrying the operation, "Contact Us" button for reporting the issue and a "Not Now" button for
/// cancelling the operation. The \c tryAgainAction, \c contactUsAction or \c cancelAction block is
/// invoked if the user pressed on the "Try Again", "Contact Us" or "Not Now" button respectively.
+ (instancetype)fetchProductsInfoFailedAlertWithTryAgainAction:(LTVoidBlock)tryAgainAction
                                               contactUsAction:(LTVoidBlock)contactUsAction
                                                  cancelAction:(LTVoidBlock)cancelAction;

/// Creates a new alert view-model for an alert that should be shown after failing purchase
/// restoration. The alert will have a title, message and 3 buttons, "Try Again" for retrying the
/// operation, "Contact Us" button for reporting the issue and a "Not Now" button for cancelling the
/// operation. The \c tryAgainAction, \c contactUsAction or \c cancelAction block is invoked if the
/// user pressed on the "Try Again", "Contact Us" or "Not Now" button respectively.
+ (instancetype)restorationFailedAlertWithTryAgainAction:(LTVoidBlock)tryAgainAction
                                         contactUsAction:(LTVoidBlock)contactUsAction
                                            cancelAction:(LTVoidBlock)cancelAction;

/// Creates a new alert view-model for an alert that should be shown after failing purchase. The
/// alert will have a title, message and 3 buttons, "Try Again" for retrying the operation,
/// "Contact Us" button for reporting the issue and a "Not Now" button for cancelling the operation.
/// The \c tryAgainAction, \c contactUsAction or \c cancelAction block is invoked if the user
/// pressed on the "Try Again", "Contact Us" or "Not Now" button respectively.
+ (instancetype)purchaseFailedAlertWithTryAgainAction:(LTVoidBlock)tryAgainAction
                                      contactUsAction:(LTVoidBlock)contactUsAction
                                         cancelAction:(LTVoidBlock)cancelAction;

/// Creates a new alert view-model for an alert that should be shown if the user's iCloud account
/// is not available. The alert will have a title, message and 2 buttons, "Settings" for redirecting
/// the user to the iOS settings to enable iCloud account, and a "Not Now" button for cancelling the
/// operation. The \c settingsAction or \c cancelAction block is invoked if the user pressed on the
/// "Settings" or "Not Now" button respectively.
+ (instancetype)noICloudAccountAlertWithSettingsAction:(LTVoidBlock)settingsAction
                                          cancelAction:(LTVoidBlock)cancelAction;

@end

NS_ASSUME_NONNULL_END

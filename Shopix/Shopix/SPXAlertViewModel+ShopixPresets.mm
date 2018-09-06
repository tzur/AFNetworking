// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SPXAlertViewModel+ShopixPresets.h"

#import "SPXAlertViewModel.h"
#import "SPXAlertViewModelBuilder.h"

NS_ASSUME_NONNULL_BEGIN

using namespace spx;

@implementation SPXAlertViewModel (ShopixPresets)

+ (instancetype)fetchProductsInfoFailedAlertWithTryAgainAction:(LTVoidBlock)tryAgainAction
                                               contactUsAction:(LTVoidBlock)contactUsAction
                                                  cancelAction:(LTVoidBlock)cancelAction {
  auto title = _LDefault(@"Network Error",
                         @"Title of an alert shown after failing attempt to fetch products "
                         "information");
  return [self failureAlertWithTitle:title tryAgainAction:tryAgainAction
                     contactUsAction:contactUsAction cancelAction:cancelAction];
}

+ (instancetype)successfulRestorationAlertWithAction:(LTVoidBlock)action
                                subscriptionRestored:(BOOL)subscriptionRestored {
  auto title = subscriptionRestored ?
      _LDefault(@"Restoration Completed",
                @"Title of an alert shown after successful restoration of user purchases") :
      _LDefault(@"No Active Subscription",
                @"Title of an alert shown after successful purchase restoration attempt that "
                "revealed that the user has no active subscription");
  auto message = subscriptionRestored ?
      _LDefault(@"Your subscription was restored successfully",
                @"Message shown after successful subscription restoration") :
      _LDefault(@"Your purchases were restored successfully, no active subscription found",
                @"Message shown after a successful products restoration, but no active "
                "subscription was found");
  auto OKButtonTitle = _LDefault(@"OK", @"Title of a button shown in an information alert");

  return [SPXAlertViewModelBuilder builder]
      .setTitle(title)
      .setMessage(message)
      .addDefaultButton(OKButtonTitle, action)
      .build();
}

+ (instancetype)noICloudAccountAlertWithSettingsAction:(LTVoidBlock)settingsAction
                                          cancelAction:(LTVoidBlock)cancelAction {
  auto title = _LDefault(@"iCloud account is not available",
                         @"Title of an alert shown after successful restoration of user purchases");
  auto message = _LDefault(@"To get the best experience of your subscription, please make sure "
                           "iCloud is enabled.", @"Message shown after successful subscription "
                           "restoration");
  auto settingsButtonTitle =
      _LDefault(@"Settings", @"Title of a button shown in an information alert");
  auto cancelButtonTitle = _LDefault(@"Not Now",
                                     @"Text on a button shown to the user on failed action, "
                                     "dismissing the alert and canceling the operation");
  auto concatedSettingsAction = ^{
    settingsAction();

    auto settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL:settingsURL];
  };

  return [SPXAlertViewModelBuilder builder]
      .setTitle(title)
      .setMessage(message)
      .addButton(cancelButtonTitle, cancelAction)
      .addDefaultButton(settingsButtonTitle, concatedSettingsAction)
      .build();
}

+ (instancetype)restorationFailedAlertWithTryAgainAction:(LTVoidBlock)tryAgainAction
                                         contactUsAction:(LTVoidBlock)contactUsAction
                                            cancelAction:(LTVoidBlock)cancelAction {
  auto title = _LDefault(@"Restoration Failed",
                         @"Title of an alert shown after failing attempt to restore purchases");
  return [self failureAlertWithTitle:title tryAgainAction:tryAgainAction
                     contactUsAction:contactUsAction cancelAction:cancelAction];
}

+ (instancetype)purchaseFailedAlertWithTryAgainAction:(LTVoidBlock)tryAgainAction
                                      contactUsAction:(LTVoidBlock)contactUsAction
                                         cancelAction:(LTVoidBlock)cancelAction {
  auto title = _LDefault(@"Purchase Failed", @"Title of an alert shown after failed purchase");
  return [self failureAlertWithTitle:title tryAgainAction:tryAgainAction
                     contactUsAction:contactUsAction cancelAction:cancelAction];
}

+ (instancetype)failureAlertWithTitle:(NSString *)title tryAgainAction:(LTVoidBlock)tryAgainAction
                      contactUsAction:(LTVoidBlock)contactUsAction
                         cancelAction:(LTVoidBlock)cancelAction {
  auto message = _LDefault(@"Please try again. If the problem persists, let us know and we'll get "
                           "right on it.",
                           @"Message shown after a failing operation, giving the user 3 options: "
                           "retry the failing operation, send a feedback email or cancel the "
                           "operation");
  auto tryAgainButtonTitle = _LDefault(@"Try Again",
                                       @"Text on a button shown to the user on failed action, "
                                       "trying the failed operation again");
  auto contactUsButtonTitle = _LDefault(@"Contact Us",
                                        @"Text on a button shown to the user on failed action, "
                                        "suggesting the user to contact our support team");
  auto cancelButtonTitle = _LDefault(@"Not Now",
                                     @"Text on a button shown to the user on failed action, "
                                     "dismissing the alert and canceling the operation");

  return [SPXAlertViewModelBuilder builder]
     .setTitle(title)
     .setMessage(message)
     .addDefaultButton(tryAgainButtonTitle, tryAgainAction)
     .addButton(contactUsButtonTitle, contactUsAction)
     .addButton(cancelButtonTitle, cancelAction)
     .build();
}

@end

NS_ASSUME_NONNULL_END

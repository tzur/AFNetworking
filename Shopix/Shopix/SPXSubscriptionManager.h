// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

@protocol BZRProductsManager, BZRProductsInfoProvider, SPXAlertViewControllerProvider,
    SPXFeedbackComposeViewControllerProvider;

NS_ASSUME_NONNULL_BEGIN

/// Manager used to handle subscription purchasing and restoration, with an appropriate localized
/// messages to the user on success or failure.
@interface SPXSubscriptionManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with shared \c productsInfoProvider, \c productsManager, \c mailComposeProvider and
/// \c alertProvider pulled from \c JSObjection. \c viewController is used to present other
/// view-controllers during the purchase / restoration process (e.g alerts, feedback composer).
- (instancetype)initWithViewController:(UIViewController *)viewController;

/// Initializes with \c productsInfoProvider used to get the current subscription status;
/// \c productsManager used to purchase subscriptions and restore purchases; \c mailComposeProvider
/// provides mail compose view controller for sending user feedback; \c alertProvider provides
/// alert view controllers presented during the purchase / restoration process; and
/// \c viewController is used to present other view-controllers (e.g alerts and feedback composer).
- (instancetype)initWithProductsInfoProvider:(id<BZRProductsInfoProvider>)productsInfoProvider
    productsManager:(id<BZRProductsManager>)productsManager
    mailComposeProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposeProvider
    alertProvider:(id<SPXAlertViewControllerProvider>)alertProvider
    viewController:(UIViewController *)viewController NS_DESIGNATED_INITIALIZER;

/// Makes a purchase of the subscription specified by \c productIdentifier. \c completionHandler
/// is invoked when the purchase process has completed with \c success set to \c YES if the purchase
/// was successful and \c NO otherwise. If there is an error during the purchasing process, an alert
/// with 3 buttons is presented - a "Not Now" button that cancels the purchase, "Try Again" button
/// that will try to continue the purchase process from the point that the previous attempt has
/// failed and a "Contact Us" button that will present the feedback mail composer.
/// \c completionHandler is invoked on the main thread.
- (void)purchaseSubscription:(NSString *)productIdentifier
           completionHandler:(LTBoolCompletionBlock)completionHandler;

/// Restore and updates the subscription information. \c completionHandler is invoked when the
/// restoration process was completed with \c success set to \c YES if the purchase was successful
/// and \c NO otherwise. If there is an error during the restoration process, an alert with 3
/// buttons is presented - a "Not Now" button that cancels the restoration, "Try Again" button
/// that will restart the restoration process, and a "Contact Us" button that will present the
/// feedback mail composer. \c completionHandler is invoked on the main thread.
- (void)restorePurchasesWithCompletionHandler:(LTBoolCompletionBlock)completionHandler;

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionManager.h"

#import <Bazaar/BZRProductsInfoProvider.h>
#import <Bazaar/BZRProductsManager.h>
#import <Bazaar/BZRReceiptModel.h>
#import <Bazaar/NSErrorCodes+Bazaar.h>
#import <MessageUI/MessageUI.h>

#import "SPXAlertViewControllerProvider.h"
#import "SPXAlertViewModel+ShopixPresets.h"
#import "SPXFeedbackComposeViewControllerProvider.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark MFMailComposeViewController+Dismissal
#pragma mark -

/// Category that adds a \c dismissBlock property to \c MFMailComposeViewController.
@interface MFMailComposeViewController (Dismiss)

/// Block invoked after the mail composer is dismissed.
@property (nonatomic, nullable) LTBoolCompletionBlock spx_dismissBlock;

@end

@implementation MFMailComposeViewController (Dismiss)

- (nullable LTBoolCompletionBlock)spx_dismissBlock {
  return objc_getAssociatedObject(self, @selector(spx_dismissBlock));
}

- (void)setSpx_dismissBlock:(nullable LTBoolCompletionBlock)dismissBlock {
    objc_setAssociatedObject(self, @selector(spx_dismissBlock), dismissBlock,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark -
#pragma mark SPXSubscriptionManager
#pragma mark -

@interface SPXSubscriptionManager () <MFMailComposeViewControllerDelegate>

/// Provider used to get the currnet subcription status.
@property (readonly, nonatomic) id<BZRProductsInfoProvider> productsInfoProvider;

/// Manager used to purchase subscriptions.
@property (readonly, nonatomic) id<BZRProductsManager> productsManager;

/// Provides a mail compose view controller for user feedback.
@property (readonly, nonatomic) id<SPXFeedbackComposeViewControllerProvider> mailComposeProvider;

/// Provides alert view controllers for alerts shown on failure / success.
@property (readonly, nonatomic) id<SPXAlertViewControllerProvider> alertProvider;

/// Used to present upon all the alert messages for the user.
@property (readonly, nonatomic, weak) UIViewController *viewController;

@end

@implementation SPXSubscriptionManager

- (instancetype)initWithViewController:(UIViewController *)viewController {
  id<BZRProductsInfoProvider> _Nullable productsInfoProvider =
      [JSObjection defaultInjector][@protocol(BZRProductsInfoProvider)];
  id<BZRProductsManager> _Nullable productsManager =
      [JSObjection defaultInjector][@protocol(BZRProductsManager)];
  id<SPXFeedbackComposeViewControllerProvider> _Nullable mailComposeProvider =
      [JSObjection defaultInjector][@protocol(SPXFeedbackComposeViewControllerProvider)];
  id<SPXAlertViewControllerProvider> alertProvider =
      [JSObjection defaultInjector][@protocol(SPXFeedbackComposeViewControllerProvider)] ?:
      [[SPXAlertViewControllerProvider alloc] init];

  LTAssert(productsInfoProvider && productsManager && mailComposeProvider,
           @"One or more required dependencies were not injected properly, make sure Objection's "
           "default injector has binding for: BZRProductsInfoProvider, BZRProductsManager and "
           "SPXFeedbackComposeViewControllerProvider protocols");

  return [self initWithProductsInfoProvider:productsInfoProvider productsManager:productsManager
                        mailComposeProvider:mailComposeProvider alertProvider:alertProvider
                             viewController:viewController];
}

- (instancetype)initWithProductsInfoProvider:(id<BZRProductsInfoProvider>)productsInfoProvider
    productsManager:(id<BZRProductsManager>)productsManager
    mailComposeProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposeProvider
    alertProvider:(id<SPXAlertViewControllerProvider>)alertProvider
    viewController:(UIViewController *)viewController {
  if (self = [super init]) {
    _productsInfoProvider = productsInfoProvider;
    _productsManager = productsManager;
    _mailComposeProvider = mailComposeProvider;
    _alertProvider = alertProvider;
    _viewController = viewController;
  }

  return self;
}

- (void)purchaseSubscription:(NSString *)productIdentifier
           completionHandler:(LTBoolCompletionBlock)completionHandler {
  LTParameterAssert(self.productsInfoProvider.productsJSONDictionary[productIdentifier],
                    @"Cannot purchase product, got invalid product identifier: %@",
                    productIdentifier);

  @weakify(self);
  [[[self.productsManager purchaseProduct:productIdentifier]
      deliverOnMainThread]
      subscribeError:^(NSError *error) {
        @strongify(self);
        if (!self || error.code == BZRErrorCodeOperationCancelled) {
           completionHandler(NO);
           return;
        }

        auto alertViewModel = [SPXAlertViewModel purchaseFailedAlertWithTryAgainAction:^{
          if (error.code == BZRErrorCodeReceiptValidationFailed) {
            [self validateReceiptWithCompletionHandler:completionHandler];
          } else {
            [self purchaseSubscription:productIdentifier completionHandler:completionHandler];
          }
        } contactUsAction:^{
          [self presentMailComposerWithCompletionHandler:completionHandler];
        } cancelAction:^{
          completionHandler(NO);
        }];
        [self presentAlertWithViewModel:alertViewModel];
      } completed:^{
        completionHandler(YES);
      }];
}

- (void)validateReceiptWithCompletionHandler:(LTBoolCompletionBlock)completionHandler {
  @weakify(self);
  [[[self.productsManager validateReceipt]
      deliverOnMainThread]
      subscribeError:^(NSError *) {
        @strongify(self);
        if (!self) {
           completionHandler(NO);
           return;
        }

        auto alertViewModel = [SPXAlertViewModel purchaseFailedAlertWithTryAgainAction:^{
          [self validateReceiptWithCompletionHandler:completionHandler];
        } contactUsAction:^{
          [self presentMailComposerWithCompletionHandler:completionHandler];
        } cancelAction:^{
          completionHandler(NO);
        }];
        [self presentAlertWithViewModel:alertViewModel];
      } completed:^{
        completionHandler(YES);
      }];
}

- (void)restorePurchasesWithCompletionHandler:(LTBoolCompletionBlock)completionHandler {
  @weakify(self);
  [[[self.productsManager refreshReceipt]
      deliverOnMainThread]
      subscribeError:^(NSError *error) {
        @strongify(self);
        if (!self || error.code == BZRErrorCodeOperationCancelled) {
          completionHandler(NO);
          return;
        }

        auto alertViewModel = [SPXAlertViewModel restorationFailedAlertWithTryAgainAction:^{
          [self restorePurchasesWithCompletionHandler:completionHandler];
        } contactUsAction:^{
          [self presentMailComposerWithCompletionHandler:completionHandler];
        } cancelAction:^{
          completionHandler(NO);
        }];
        [self presentAlertWithViewModel:alertViewModel];
      }
      completed:^{
        @strongify(self);
        if (!self) {
          completionHandler(YES);
          return;
        }

        BOOL subscriptionRestored = self.productsInfoProvider.subscriptionInfo &&
            !self.productsInfoProvider.subscriptionInfo.isExpired;
        [self presentAlertWithViewModel:[SPXAlertViewModel successfulRestorationAlertWithAction:^{
          completionHandler(YES);
        } subscriptionRestored:subscriptionRestored]];
      }];
}

- (void)presentAlertWithViewModel:(id<SPXAlertViewModel>)alertViewModel {
  auto alertViewController = [self.alertProvider alertViewControllerWithModel:alertViewModel];
  [self.viewController presentViewController:alertViewController animated:YES completion:nil];
}

- (void)presentMailComposerWithCompletionHandler:(LTBoolCompletionBlock)completionHandler {
  auto mailComposeViewController = [self.mailComposeProvider feedbackComposeViewController];
  if (!mailComposeViewController) {
    completionHandler(NO);
    return;
  }

  mailComposeViewController.mailComposeDelegate = self;
  mailComposeViewController.spx_dismissBlock = completionHandler;
  [self.viewController presentViewController:mailComposeViewController animated:YES completion:nil];
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate
#pragma mark -

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult __unused)result
                        error:(NSError * _Nullable __unused)error {
  [controller dismissViewControllerAnimated:YES completion:^{
    controller.spx_dismissBlock(NO);
  }];
}

@end

NS_ASSUME_NONNULL_END

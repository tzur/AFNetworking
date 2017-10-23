// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionManager.h"

#import <Bazaar/BZRProductsInfoProvider.h>
#import <Bazaar/BZRProductsManager.h>
#import <Bazaar/BZRReceiptModel.h>
#import <Bazaar/NSErrorCodes+Bazaar.h>
#import <MessageUI/MessageUI.h>

#import "SPXFeedbackComposeViewControllerProvider.h"

NS_ASSUME_NONNULL_BEGIN

using namespace spx;

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

@interface SPXSubscriptionManager () <MFMailComposeViewControllerDelegate>

/// Provider used to get the currnet subcription status.
@property (readonly, nonatomic) id<BZRProductsInfoProvider> productsInfoProvider;

/// Manager used to purchase subscriptions.
@property (readonly, nonatomic) id<BZRProductsManager> productsManager;

/// Provides a mail compose view controller for user feedback.
@property (readonly, nonatomic) id<SPXFeedbackComposeViewControllerProvider> mailComposeProvider;

/// Used to present upon all the alert messages for the user.
@property (readonly, nonatomic, weak) UIViewController *viewController;

@end

@implementation SPXSubscriptionManager

#pragma mark -
#pragma mark SPXSubscriptionManager
#pragma mark -

- (instancetype)initWithViewController:(UIViewController *)viewController {
  return [self
      initWithProductsInfoProvider:[JSObjection defaultInjector][@protocol(BZRProductsInfoProvider)]
      productsManager:[JSObjection defaultInjector][@protocol(BZRProductsManager)]
      mailComposeProvider:
          [JSObjection defaultInjector][@protocol(SPXFeedbackComposeViewControllerProvider)]
      viewController:viewController];
}

- (instancetype)initWithProductsInfoProvider:(id<BZRProductsInfoProvider>)productsInfoProvider
    productsManager:(id<BZRProductsManager>)productsManager
    mailComposeProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposeProvider
    viewController:(UIViewController *)viewController {
  if (self = [super init]) {
    _productsInfoProvider = productsInfoProvider;
    _productsManager = productsManager;
    _mailComposeProvider = mailComposeProvider;
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
        if (!self || ([error.lt_underlyingError.domain isEqualToString:SKErrorDomain] &&
                      error.lt_underlyingError.code == SKErrorPaymentCancelled)) {
           completionHandler(NO);
           return;
        }

        auto purchaseFailedMessage =
            _LDefault(@"Purchase failed", @"Shown after a failed purchase");
        [self presentFailureAlertWithMessage:purchaseFailedMessage
                             tryAgainHandler:^{
                               if (error.code == BZRErrorCodeReceiptValidationFailed) {
                                 [self validateReceiptWithCompletionHandler:completionHandler];
                               } else {
                                 [self purchaseSubscription:productIdentifier
                                          completionHandler:completionHandler];
                               }
                             } completionHandler:completionHandler];
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

        auto purchaseFailedMessage =
            _LDefault(@"Purchase failed", @"Shown after a failed purchase");
        [self presentFailureAlertWithMessage:purchaseFailedMessage
                             tryAgainHandler:^{
                               [self validateReceiptWithCompletionHandler:completionHandler];
                             } completionHandler:completionHandler];
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

        auto restorePurchasesFailedMessage =
            _LDefault(@"Your purchases cannot be restored at this time",
                      @"Title of an alert box shown after purchases restoration has failed");
        [self presentFailureAlertWithMessage:restorePurchasesFailedMessage
                             tryAgainHandler:^{
                               [self restorePurchasesWithCompletionHandler:completionHandler];
                             } completionHandler:completionHandler];
      }
      completed:^{
        @strongify(self);
        if (!self) {
          completionHandler(YES);
          return;
        }

        auto restorePurchasesMessage = (self.productsInfoProvider.subscriptionInfo &&
            !self.productsInfoProvider.subscriptionInfo.isExpired) ?
            _LDefault(@"Your subscription was restored successfully",
                      @"Message shown after successful subscription restoration") :
            _LDefault(@"Your purchases were restored successfully, no active subscription found",
                      @"Message shown after a successful products restoration, when no active"
                       "subscription was found");
        [self presentSuccessAlertWithMessage:restorePurchasesMessage
                           completionHandler:completionHandler];
      }];
}

- (void)presentSuccessAlertWithMessage:(NSString *)message
                     completionHandler:(LTBoolCompletionBlock)completionHandler {
  auto OKButton = [self alertButtonWithTitle:@"OK" handler:^{
    completionHandler(YES);
  }];
  auto alert = [self alertWithMessage:message buttons:@[OKButton]];

  [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentFailureAlertWithMessage:(NSString *)message
                       tryAgainHandler:(LTVoidBlock)tryAgainHandler
                     completionHandler:(LTBoolCompletionBlock)completionHandler {
  auto tryAgainTitle = _LDefault(@"Try Again", @"Body of an error message that asks the user to "
                                   "try again");
  auto contactUsTitle = _LDefault(@"Contact Us", @"Text on a button shown to the user on failed "
                                   "action, navigating the user to sending feedback");
  auto notNowTitle = _LDefault(@"Not Now", @"Text on a button shown to the user on failed action, "
                                "dismissing the alert");

  auto tryAgainButton = [self alertButtonWithTitle:tryAgainTitle handler:^{
    tryAgainHandler();
  }];
  auto contactUsButton = [self alertButtonWithTitle:contactUsTitle handler:^{
    [self displayMailComposerWithCompletionHandler:completionHandler];
  }];
  auto notNowButton = [self alertButtonWithTitle:notNowTitle handler:^{
    completionHandler(NO);
  }];

  auto alert = [self alertWithMessage:message buttons:@[
    tryAgainButton,
    contactUsButton,
    notNowButton
  ]];
  [self.viewController presentViewController:alert animated:YES completion:nil];
}

- (UIAlertController *)alertWithMessage:(NSString *)message
                                buttons:(NSArray<UIAlertAction *> *)buttons {
  auto alert = [UIAlertController alertControllerWithTitle:nil
                                                   message:message
                                            preferredStyle:UIAlertControllerStyleAlert];
  for (UIAlertAction *button in buttons) {
    [alert addAction:button];
  }

  return alert;
}

- (UIAlertAction *)alertButtonWithTitle:(NSString *)title
                                handler:(LTVoidBlock)handler {
  return [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *){
                                  handler();
                                }];
}

- (void)displayMailComposerWithCompletionHandler:(LTBoolCompletionBlock)completionHandler {
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

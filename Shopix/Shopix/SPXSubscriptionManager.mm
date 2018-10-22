// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionManager.h"

#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRProductsInfoProvider.h>
#import <Bazaar/BZRProductsManager.h>
#import <Bazaar/BZRReceiptModel.h>
#import <Bazaar/BZRReceiptValidationStatus.h>
#import <Bazaar/BZRiCloudUserIDProvider.h>
#import <Bazaar/NSError+Bazaar.h>
#import <Bazaar/NSErrorCodes+Bazaar.h>
#import <LTKit/NSArray+Functional.h>

#import "SPXAlertViewModel+ShopixPresets.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSString (SubscriptionGroup)

- (NSString *)spx_subscriptionGroup {
  if ([self spx_isNewFormat]) {
    return [self spx_subscriptionGroupFromNewFormat];
  } else if([self spx_isOldFormat]) {
    return [self spx_subscriptionGroupFromOldFormat];
  }
  return kBZRGenericGroup;
}

- (BOOL)spx_isOldFormat {
  return [self containsString:@"."];
}

- (NSString *)spx_subscriptionGroupFromOldFormat {
  // Old format is <groupId>.<bar> where <groupId> is a variable length string composed of
  // letters, numbers and dots. or as a regexp - find the first match group in the pattern
  // ([A-z0-9\.]+)\.[A-z0-9]+
  auto productIDSeparatedComponents = [self componentsSeparatedByString:@"."];
  auto rangeOfGroupID = NSMakeRange(0, productIDSeparatedComponents.count - 1);
  auto groupIDSeparatedComponents = [productIDSeparatedComponents subarrayWithRange:rangeOfGroupID];
  return [groupIDSeparatedComponents componentsJoinedByString:@"."];
}

- (BOOL)spx_isNewFormat {
  return [self componentsSeparatedByString:@"_"].count == 3;
}

- (NSString *)spx_subscriptionGroupFromNewFormat {
  // New format is <foo>_<groupId>_<bar>.
  return [self componentsSeparatedByString:@"_"][1];
}

@end

@interface SPXSubscriptionManager ()

/// Provider used to get the current subscription status.
@property (readonly, nonatomic) id<BZRProductsInfoProvider> productsInfoProvider;

/// Manager used to purchase subscriptions.
@property (readonly, nonatomic) id<BZRProductsManager> productsManager;

/// Provider used to receive the unique identifier of the user.
@property (readonly, nonatomic) id<BZRUserIDProvider> userIDProvider;

@end

@implementation SPXSubscriptionManager

- (instancetype)init {
  id<BZRProductsInfoProvider> _Nullable productsInfoProvider =
      [JSObjection defaultInjector][@protocol(BZRProductsInfoProvider)];
  id<BZRProductsManager> _Nullable productsManager =
      [JSObjection defaultInjector][@protocol(BZRProductsManager)];

  LTAssert(productsInfoProvider && productsManager,
           @"One or more required dependencies (BZRProductsInfoProvider and BZRProductsManager) "
           "were not injected properly, make sure Objection's default injector has binding for "
           "these protocols");

  return [self initWithProductsInfoProvider:productsInfoProvider productsManager:productsManager];
}

- (instancetype)initWithProductsInfoProvider:(id<BZRProductsInfoProvider>)productsInfoProvider
    productsManager:(id<BZRProductsManager>)productsManager {
  if (self = [super init]) {
    _productsInfoProvider = productsInfoProvider;
    _productsManager = productsManager;
    _userIDProvider = [[BZRiCloudUserIDProvider alloc] init];
  }

  return self;
}

- (void)fetchProductsInfo:(NSSet<NSString *> *)productIdentifiers
        completionHandler:(SPXFetchProductsCompletionBlock)completionHandler {
  @weakify(self);
  [[[self.productsManager fetchProductsInfo:productIdentifiers]
   deliverOnMainThread]
   subscribeNext:^(NSDictionary<NSString *, BZRProduct *> *products) {
     completionHandler(products, nil);
   }
   error:^(NSError *error) {
     @strongify(self);
     if (!self.delegate) {
       completionHandler(nil, error);
       return;
     }

     [self presentProductsInfoFetchingFailedAlertWithError:error
                                        productIdentifiers:productIdentifiers
                                         completionHandler:completionHandler];
   }];
}

- (void)purchaseSubscription:(NSString *)productIdentifier
           completionHandler:(SPXPurchaseSubscriptionCompletionBlock)completionHandler {
  LTParameterAssert(self.productsInfoProvider.productsJSONDictionary[productIdentifier],
                    @"Cannot purchase product, got invalid product identifier: %@",
                    productIdentifier);

  @weakify(self);
  [[[self.productsManager purchaseProduct:productIdentifier]
      deliverOnMainThread]
      subscribeError:^(NSError *error) {
        @strongify(self);
        if (!self.delegate || error.code == BZRErrorCodeOperationCancelled) {
          completionHandler(nil, error);
          return;
        }

        [self presentPurchaseFailedAlertWithError:error productIdentifier:productIdentifier
                                completionHandler:completionHandler];
      } completed:^{
        @strongify(self);
        completionHandler(self.productsInfoProvider.subscriptionInfo, nil);
      }];
}

- (void)validateReceiptWithCompletionHandler:
    (SPXPurchaseSubscriptionCompletionBlock)completionHandler {
  @weakify(self);
  [[[self.productsManager validateReceipt]
      deliverOnMainThread]
      subscribeError:^(NSError *error) {
        @strongify(self);
        if (!self.delegate || error.code == BZRErrorCodeOperationCancelled) {
           completionHandler(nil, error);
           return;
        }

        [self presentReceiptValidationFailedAlertWithError:error
                                         completionHandler:completionHandler];
      } completed:^{
        @strongify(self);
        completionHandler(self.productsInfoProvider.subscriptionInfo, nil);
      }];
}

- (void)restorePurchasesWithCompletionHandler:(SPXRestorationCompletionBlock)completionHandler {
  @weakify(self);
  [[[self.productsManager refreshReceipt]
      deliverOnMainThread]
      subscribeError:^(NSError *error) {
        @strongify(self);
        if (!self.delegate || error.code == BZRErrorCodeOperationCancelled) {
          completionHandler(nil, error);
          return;
        }

        [self presentRestorationFailedAlertWithError:error completionHandler:completionHandler];
      }
      completed:^{
        @strongify(self);
        BZRReceiptInfo *receipt = self.productsInfoProvider.receiptValidationStatus.receipt;
        if (!self.delegate) {
          completionHandler(receipt, nil);
          return;
        }

        BOOL subscriptionRestored = self.productsInfoProvider.subscriptionInfo &&
            !self.productsInfoProvider.subscriptionInfo.isExpired;
        auto alertViewModel = [SPXAlertViewModel successfulRestorationAlertWithAction:^{
          completionHandler(receipt, nil);
        } subscriptionRestored:subscriptionRestored];
        [self.delegate presentAlertWithViewModel:alertViewModel];
      }];
}

- (BOOL)eligibleForIntroductoryDiscountOnSubscription:(BZRProduct *)subscriptionProduct {
  auto subscriptionsubscriptionGroup = subscriptionProduct.identifier.spx_subscriptionGroup;
  auto transactionsWithDiscount =
      [self.productsInfoProvider.receiptValidationStatus.receipt.transactions
       lt_filter:^BOOL(BZRReceiptTransactionInfo *transactionInfo) {
           return transactionInfo.isIntroOfferPeriod || transactionInfo.isTrialPeriod;
       }];
  auto transactionsWithDiscountInSameGroup = [transactionsWithDiscount
      lt_filter:^BOOL(BZRReceiptTransactionInfo *transactionInfo) {
        return [transactionInfo.productId.spx_subscriptionGroup
                isEqualToString:subscriptionsubscriptionGroup];
      }];
  return (transactionsWithDiscountInSameGroup.count == 0);
}

#pragma mark -
#pragma mark Presenting Alerts
#pragma mark -

- (void)presentProductsInfoFetchingFailedAlertWithError:(NSError *)error
    productIdentifiers:(NSSet<NSString *> *)productIdentifiers
    completionHandler:(SPXFetchProductsCompletionBlock)completionHandler {
  @weakify(self);
  auto alertViewModel = [SPXAlertViewModel fetchProductsInfoFailedAlertWithTryAgainAction:^{
    @strongify(self);
    if (!self) {
      completionHandler(nil, error);
      return;
    }

    [self fetchProductsInfo:productIdentifiers completionHandler:completionHandler];
  } contactUsAction:^{
    @strongify(self);
    if (!self || !self.delegate) {
      completionHandler(nil, error);
      return;
    }

    [self.delegate presentFeedbackMailComposerWithCompletionHandler:^{
      completionHandler(nil, error);
    }];
  } cancelAction:^{
    completionHandler(nil, error);
  }];
  [self.delegate presentAlertWithViewModel:alertViewModel];
}

- (void)presentPurchaseFailedAlertWithError:(NSError *)error
    productIdentifier:(NSString *)productIdentifier
    completionHandler:(SPXPurchaseSubscriptionCompletionBlock)completionHandler {
  @weakify(self);
  auto alertViewModel = [SPXAlertViewModel purchaseFailedAlertWithTryAgainAction:^{
    @strongify(self);
    if (!self) {
      completionHandler(nil, error);
      return;
    }

    // If the purchase succeeded and only the receipt validation failed retry only the receipt
    // validation and not the entire purchase process.
    if (error.lt_underlyingError.code == BZRErrorCodeReceiptValidationFailed) {
      [self validateReceiptWithCompletionHandler:completionHandler];
    } else if (error.code == BZRErrorCodeTransactionNotFoundInReceipt) {
      [self validateTransactionOnError:error productIdentifier:productIdentifier
                     completionHandler:completionHandler];
    } else if (error.lt_underlyingError.code == BZRErrorCodeTransactionNotFoundInReceipt) {
      [self validateTransactionOnError:error.lt_underlyingError productIdentifier:productIdentifier
                     completionHandler:completionHandler];
    } else {
      [self purchaseSubscription:productIdentifier completionHandler:completionHandler];
    }
  } contactUsAction:^{
    @strongify(self);
    if (!self.delegate) {
      completionHandler(nil, error);
      return;
    }

    [self.delegate presentFeedbackMailComposerWithCompletionHandler:^{
      completionHandler(nil, error);
    }];
  } cancelAction:^{
    completionHandler(nil, error);
  }];
  [self.delegate presentAlertWithViewModel:alertViewModel];
}

- (void)validateTransactionOnError:(NSError *)error productIdentifier:(NSString *)productIdentifier
                 completionHandler:(SPXPurchaseSubscriptionCompletionBlock)completionHandler {
  @weakify(self);
  [[self.productsManager validateTransaction:error.bzr_transactionIdentifier]
      subscribeError:^(NSError *error) {
        @strongify(self);
        if (!self.delegate || error.code == BZRErrorCodeOperationCancelled) {
          completionHandler(nil, error);
          return;
        }
        [self presentPurchaseFailedAlertWithError:error productIdentifier:productIdentifier
                                completionHandler:completionHandler];
      } completed:^{
        @strongify(self);
        completionHandler(self.productsInfoProvider.subscriptionInfo, nil);
      }];
}

- (void)presentReceiptValidationFailedAlertWithError:(NSError *)error
    completionHandler:(SPXPurchaseSubscriptionCompletionBlock)completionHandler {
  @weakify(self);
  auto alertViewModel = [SPXAlertViewModel purchaseFailedAlertWithTryAgainAction:^{
    @strongify(self);
    if (!self) {
      completionHandler(nil, error);
      return;
    }

    [self validateReceiptWithCompletionHandler:completionHandler];
  } contactUsAction:^{
    @strongify(self);
    if (!self.delegate) {
      completionHandler(nil, error);
      return;
    }

    [self.delegate presentFeedbackMailComposerWithCompletionHandler:^{
      completionHandler(nil, error);
    }];
  } cancelAction:^{
    completionHandler(nil, error);
  }];
  [self.delegate presentAlertWithViewModel:alertViewModel];
}

- (void)presentRestorationFailedAlertWithError:(NSError *)error
                             completionHandler:(SPXRestorationCompletionBlock)completionHandler {
  @weakify(self);
  auto alertViewModel = [SPXAlertViewModel restorationFailedAlertWithTryAgainAction:^{
    @strongify(self);
    if (!self) {
      completionHandler(nil, error);
      return;
    }

    [self restorePurchasesWithCompletionHandler:completionHandler];
  } contactUsAction:^{
    @strongify(self);
    if (!self.delegate) {
      completionHandler(nil, error);
      return;
    }

    [self.delegate presentFeedbackMailComposerWithCompletionHandler:^{
      completionHandler(nil, error);
    }];
  } cancelAction:^{
    completionHandler(nil, error);
  }];
  [self.delegate presentAlertWithViewModel:alertViewModel];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (nullable NSString *)userID {
  return self.userIDProvider.userID;
}

@end

NS_ASSUME_NONNULL_END

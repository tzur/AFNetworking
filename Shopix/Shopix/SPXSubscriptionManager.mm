// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionManager.h"

#import <Bazaar/BZRProductsInfoProvider.h>
#import <Bazaar/BZRProductsManager.h>
#import <Bazaar/BZRReceiptModel.h>
#import <Bazaar/NSErrorCodes+Bazaar.h>

#import "SPXAlertViewModel+ShopixPresets.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionManager ()

/// Provider used to get the currnet subcription status.
@property (readonly, nonatomic) id<BZRProductsInfoProvider> productsInfoProvider;

/// Manager used to purchase subscriptions.
@property (readonly, nonatomic) id<BZRProductsManager> productsManager;

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
     if (!self || !self.delegate) {
       completionHandler(nil, error);
       return;
     }

     auto alertViewModel = [SPXAlertViewModel fetchProductsInfoFailedAlertWithTryAgainAction:^{
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
   }];
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
        if (!self || !self.delegate || error.code == BZRErrorCodeOperationCancelled) {
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
          @strongify(self);
          if (!self || !self.delegate) {
            completionHandler(NO);
          }

          [self.delegate presentFeedbackMailComposerWithCompletionHandler:^{
            completionHandler(NO);
          }];
        } cancelAction:^{
          completionHandler(NO);
        }];
        [self.delegate presentAlertWithViewModel:alertViewModel];
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
        if (!self || !self.delegate) {
           completionHandler(NO);
           return;
        }

        auto alertViewModel = [SPXAlertViewModel purchaseFailedAlertWithTryAgainAction:^{
          [self validateReceiptWithCompletionHandler:completionHandler];
        } contactUsAction:^{
          @strongify(self);
          if (!self || !self.delegate) {
            completionHandler(NO);
          }

          [self.delegate presentFeedbackMailComposerWithCompletionHandler:^{
            completionHandler(NO);
          }];
        } cancelAction:^{
          completionHandler(NO);
        }];
        [self.delegate presentAlertWithViewModel:alertViewModel];
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
        if (!self || !self.delegate || error.code == BZRErrorCodeOperationCancelled) {
          completionHandler(NO);
          return;
        }

        auto alertViewModel = [SPXAlertViewModel restorationFailedAlertWithTryAgainAction:^{
          [self restorePurchasesWithCompletionHandler:completionHandler];
        } contactUsAction:^{
          if (!self || !self.delegate) {
            completionHandler(NO);
          }
          [self.delegate presentFeedbackMailComposerWithCompletionHandler:^{
            completionHandler(NO);
          }];
        } cancelAction:^{
          completionHandler(NO);
        }];
        [self.delegate presentAlertWithViewModel:alertViewModel];
      }
      completed:^{
        @strongify(self);
        if (!self || !self.delegate) {
          completionHandler(YES);
          return;
        }

        BOOL subscriptionRestored = self.productsInfoProvider.subscriptionInfo &&
            !self.productsInfoProvider.subscriptionInfo.isExpired;
        auto alertViewModel = [SPXAlertViewModel successfulRestorationAlertWithAction:^{
          completionHandler(YES);
        } subscriptionRestored:subscriptionRestored];
        [self.delegate presentAlertWithViewModel:alertViewModel];
      }];
}

@end

NS_ASSUME_NONNULL_END

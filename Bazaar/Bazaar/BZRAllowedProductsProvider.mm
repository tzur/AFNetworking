// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRAllowedProductsProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRProduct+EnablesProduct.h"
#import "BZRProductTypedefs.h"
#import "BZRProductsProvider.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRAllowedProductsProvider ()

/// Provider used to provide the product list.
@property (readonly, nonatomic) id<BZRProductsProvider> productsProvider;

/// Provider used to provide the latest \c BZRReceiptValidationStatus.
@property (readonly, nonatomic) BZRCachedReceiptValidationStatusProvider *validationStatusProvider;

/// Provider used to provide list of products that were acquired via subscription.
@property (readonly, nonatomic) BZRAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;

/// Set of product identifiers that the user is allowed to use. KVO-compliant. Changes may be
/// delivered on an arbitrary thread.
@property (readwrite, nonatomic) NSSet<NSString *> *allowedProducts;

@end

@implementation BZRAllowedProductsProvider

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithProductsProvider:(id<BZRProductsProvider>)productsProvider
    validationStatusProvider:(BZRCachedReceiptValidationStatusProvider *)validationStatusProvider
    acquiredViaSubscriptionProvider:(BZRAcquiredViaSubscriptionProvider *)
    acquiredViaSubscriptionProvider {
  if (self = [super init]) {
    _productsProvider = productsProvider;
    _validationStatusProvider = validationStatusProvider;
    _acquiredViaSubscriptionProvider = acquiredViaSubscriptionProvider;
    _allowedProducts = [NSSet set];

    [self setupAllowedProductsUpdates];
  }

  return self;
}

- (void)setupAllowedProductsUpdates {
  @weakify(self);
  RAC(self, allowedProducts) = [RACSignal combineLatest:@[
    RACObserve(self.validationStatusProvider, receiptValidationStatus),
    RACObserve(self.acquiredViaSubscriptionProvider, productsAcquiredViaSubscription),
    [[self.productsProvider fetchProductList] startWith:nil]
  ] reduce:(id)^NSSet<NSString *> *(BZRReceiptValidationStatus * _Nullable receiptValidationStatus,
                                    NSSet<NSString *> *productsAcquiredViaSubscription,
                                    BZRProductList * _Nullable productList) {
    @strongify(self);
    BZRReceiptInfo * _Nullable receipt = receiptValidationStatus.receipt;
    NSMutableSet<NSString *> *enabledProducts =
        [self enabledProducts:receipt productList:productList];
    NSArray<NSString *> *purchasedProducts = receipt.inAppPurchases ?
        [receipt.inAppPurchases
         valueForKey:@instanceKeypath(BZRReceiptInAppPurchaseInfo, productId)] : @[];

    [enabledProducts intersectSet:productsAcquiredViaSubscription];
    [enabledProducts unionSet:[NSSet setWithArray:purchasedProducts]];
    return [enabledProducts copy];
  }];
}

- (NSMutableSet<NSString *> *)enabledProducts:(nullable BZRReceiptInfo *)receipt
                                  productList:(nullable BZRProductList *)productList {
  if (!receipt.subscription || receipt.subscription.isExpired || !productList) {
    return [NSMutableSet set];
  }

  NSString *subscriptionIdentifier = receipt.subscription.productId;
  BZRProduct *subscriptionProduct = [productList lt_find:^BOOL(BZRProduct *product) {
    return [product.identifier isEqualToString:subscriptionIdentifier];
  }];

  if (!subscriptionProduct) {
    LogError(@"The subscription from the receipt does not exist in product "
             "list. Subscription identifier is: %@", subscriptionIdentifier);

    NSArray<NSString *> *allNonSubscriptionProducts =
        [[productList lt_filter:^BOOL(BZRProduct *product) {
          return ![self isSubscriptionProduct:product];
        }] valueForKey:@instanceKeypath(BZRProduct, identifier)];
    return [NSMutableSet setWithArray:allNonSubscriptionProducts];
  }

  return [NSMutableSet setWithArray:
          [self productsEnabledBySubscription:subscriptionProduct productList:productList]];
}

- (NSArray<NSString *> *)productsEnabledBySubscription:(BZRProduct *)subscriptionProduct
                                           productList:(BZRProductList *)productList {
  return [[productList
      lt_filter:^BOOL(BZRProduct *product) {
        return ![self isSubscriptionProduct:product] &&
            [subscriptionProduct doesProductEnablesProductWithIdentifier:product.identifier];
      }]
      valueForKey:@instanceKeypath(BZRProduct, identifier)];
}

- (BOOL)isSubscriptionProduct:(BZRProduct *)product {
  return [product.productType isEqual:$(BZRProductTypeRenewableSubscription)] ||
      [product.productType isEqual:$(BZRProductTypeNonRenewingSubscription)];
}

@end

NS_ASSUME_NONNULL_END

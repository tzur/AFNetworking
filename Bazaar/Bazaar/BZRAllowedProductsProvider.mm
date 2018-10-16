// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRAllowedProductsProvider.h"

#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSSet+Operations.h>

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRMultiAppReceiptValidationStatusProvider.h"
#import "BZRProduct+EnablesProduct.h"
#import "BZRProductsProvider.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRAllowedProductsProvider ()

/// Provider used to provide the product list.
@property (readonly, nonatomic) id<BZRProductsProvider> productsProvider;

/// Provider used to provide the latest aggregated \c BZRReceiptValidationStatus.
@property (readonly, nonatomic) BZRMultiAppReceiptValidationStatusProvider
    *multiAppValidationStatusProvider;

/// Provider used to provide list of products that were acquired via subscription.
@property (readonly, nonatomic) BZRAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;

/// Most recent list of products provided by the \c productsProvider.
@property (readwrite, nonatomic, nullable) NSArray<BZRProduct *> *productList;

/// Set of product identifiers that the user is allowed to use. KVO-compliant. Changes may be
/// delivered on an arbitrary thread.
@property (readwrite, nonatomic) NSSet<NSString *> *allowedProducts;

@end

@implementation BZRAllowedProductsProvider

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithProductsProvider:(id<BZRProductsProvider>)productsProvider
    multiAppValidationStatusProvider:(BZRMultiAppReceiptValidationStatusProvider *)
    multiAppValidationStatusProvider
    acquiredViaSubscriptionProvider:(BZRAcquiredViaSubscriptionProvider *)
    acquiredViaSubscriptionProvider {
  if (self = [super init]) {
    _productsProvider = productsProvider;
    _multiAppValidationStatusProvider = multiAppValidationStatusProvider;
    _acquiredViaSubscriptionProvider = acquiredViaSubscriptionProvider;
    _productList = @[];
    _allowedProducts = [NSSet set];

    [self setupProductListFetching];
    [self setupAllowedProductsUpdates];
  }

  return self;
}

- (void)setupProductListFetching {
  RAC(self, productList) = [[self.productsProvider fetchProductList]
      catchTo:[RACSignal return:nil]];
}

- (void)setupAllowedProductsUpdates {
  @weakify(self);
  RAC(self, allowedProducts) = [RACSignal combineLatest:@[
    RACObserve(self.multiAppValidationStatusProvider, aggregatedReceiptValidationStatus),
    RACObserve(self.acquiredViaSubscriptionProvider, productsAcquiredViaSubscription),
    RACObserve(self, productList)
  ] reduce:(id)^NSSet<NSString *> *(BZRReceiptValidationStatus * _Nullable receiptValidationStatus,
                                    NSSet<NSString *> *productsAcquiredViaSubscription,
                                    BZRProductList * _Nullable productList) {
    @strongify(self);
    BZRReceiptInfo * _Nullable receipt = receiptValidationStatus.receipt;
    NSArray<BZRReceiptInAppPurchaseInfo *> *purchasedProducts = receipt.inAppPurchases ?: @[];
    NSSet<NSString *> *purchasedProductsIdentifiers =
        [NSSet setWithArray:
         [purchasedProducts valueForKey:@instanceKeypath(BZRReceiptInAppPurchaseInfo, productId)]];

    // If failed to fetch product list allow the user to use all the products he purchased and all
    // the products he already acquired via subscription if he has an active subscription. With this
    // approach the user may use products that the currently active subscription does not grant him
    // access to and they are in \c productsAcquriedViaSubscription, but at least he will not be
    // prevented from using products he is eligible to and already acquired.
    if (!productList) {
      if ([self hasActiveSubscription:receipt]) {
        return [productsAcquiredViaSubscription
                setByAddingObjectsFromSet:purchasedProductsIdentifiers];
      } else {
        return purchasedProductsIdentifiers;
      }
    }

    // If product list is empty - probably product list fetching was not completed yet.
    if (!productList.count) {
      return purchasedProductsIdentifiers;
    }

    return [[[self enabledProducts:receipt productList:productList]
        lt_intersect:productsAcquiredViaSubscription]
        lt_union:purchasedProductsIdentifiers];
  }];
}

- (NSSet<NSString *> *)enabledProducts:(nullable BZRReceiptInfo *)receipt
                           productList:(BZRProductList *)productList {
  if (![self hasActiveSubscription:receipt]) {
    return [NSSet set];
  }

  NSString *subscriptionIdentifier = receipt.subscription.productId;
  BZRProduct *subscriptionProduct = [productList lt_find:^BOOL(BZRProduct *product) {
    return [product.identifier isEqualToString:subscriptionIdentifier];
  }];

  if (!subscriptionProduct) {
    NSArray<NSString *> *allNonSubscriptionProducts =
        [[productList lt_filter:^BOOL(BZRProduct *product) {
          return ![self isSubscriptionProduct:product];
        }] valueForKey:@instanceKeypath(BZRProduct, identifier)];
    return [allNonSubscriptionProducts lt_set];
  }

  return [[self productsEnabledBySubscription:subscriptionProduct productList:productList] lt_set];
}

- (NSArray<NSString *> *)productsEnabledBySubscription:(BZRProduct *)subscriptionProduct
                                           productList:(BZRProductList *)productList {
  return [[productList
      lt_filter:^BOOL(BZRProduct *product) {
        return ![self isSubscriptionProduct:product] &&
            [subscriptionProduct enablesProductWithIdentifier:product.identifier];
      }]
      valueForKey:@instanceKeypath(BZRProduct, identifier)];
}

- (BOOL)hasActiveSubscription:(nullable BZRReceiptInfo *)receipt {
  return receipt.subscription && !receipt.subscription.isExpired;
}

- (BOOL)isSubscriptionProduct:(BZRProduct *)product {
  return [product.productType isEqual:$(BZRProductTypeRenewableSubscription)] ||
      [product.productType isEqual:$(BZRProductTypeNonRenewingSubscription)];
}

@end

NS_ASSUME_NONNULL_END

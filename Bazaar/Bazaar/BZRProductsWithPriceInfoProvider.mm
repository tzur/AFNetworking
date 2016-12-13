// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsWithPriceInfoProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRProduct+SKProduct.h"
#import "BZRProductPriceInfo+SKProduct.h"
#import "BZRProductTypedefs.h"
#import "BZRStoreKitFacade.h"
#import "NSError+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRProductsWithPriceInfoProvider ()

/// Provider used to provide the list of products.
@property (readonly, nonatomic) id<BZRProductsProvider> underlyingProvider;

/// Facade used to interact with Apple StoreKit.
@property (readonly, nonatomic) BZRStoreKitFacade *storeKitFacade;

/// Subject used to send errors with.
@property (readonly, nonatomic) RACSubject *nonCriticalErrorsSubject;

@end

@implementation BZRProductsWithPriceInfoProvider

@synthesize nonCriticalErrorsSignal = _nonCriticalErrorsSignal;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithUnderlyingProvider:(id<BZRProductsProvider>)underlyingProvider
                            storeKitFacade:(BZRStoreKitFacade *)storeKitFacade {
  if (self = [super init]) {
    _underlyingProvider = underlyingProvider;
    _storeKitFacade = storeKitFacade;
    _nonCriticalErrorsSubject = [RACSubject subject];
    _nonCriticalErrorsSignal = [[RACSignal merge:@[
        self.nonCriticalErrorsSubject,
        self.underlyingProvider.nonCriticalErrorsSignal
    ]]
    takeUntil:[self rac_willDeallocSignal]];
  }
  return self;
}

#pragma mark -
#pragma mark BZRProductsProvider
#pragma mark -

/// Collection of classified \c BZRProduct.
typedef NSDictionary<id, BZRProductList *> BZRClassifiedProducts;

/// Label used to mark AppStore products in a \c BZRClassifiedProducts.
static NSNumber * const kAppStoreProductsLabel = @1;

/// Label used to mark non AppStore products in a \c BZRClassifiedProducts.
static NSNumber * const kNonAppStoreProductsLabel = @0;

- (RACSignal *)fetchProductList {
  @weakify(self);
  return [[[self.underlyingProvider fetchProductList]
      map:^BZRClassifiedProducts *(BZRProductList *productList) {
        return [productList lt_classify:^NSNumber *(BZRProduct * product) {
          return product.isSubscribersOnly ? kNonAppStoreProductsLabel : kAppStoreProductsLabel;
        }];
      }]
      flattenMap:^RACStream *(BZRClassifiedProducts *classifiedProducts) {
        @strongify(self);
        if (!self) {
          return [RACSignal empty];
        }

        RACSignal *appStoreProductsMapper =
            [self appStoreProductsList:classifiedProducts[kAppStoreProductsLabel]];
        return [appStoreProductsMapper
            map:^BZRProductList *(BZRProductList *appStoreProducts) {
              return [appStoreProducts arrayByAddingObjectsFromArray:
                      classifiedProducts[kNonAppStoreProductsLabel]];
            }];
      }];
}

- (RACSignal *)appStoreProductsList:(BZRProductList *)products {
  // If the given product list is empty avoid StoreKit overhead and return a signal that delivers an
  // empty list. Returning an empty signal is not good since the returned list is merged with
  // another list and we don't want to lose the values from the other list.
  if (!products.count) {
    return [RACSignal return:@[]];
  }
  
  NSArray<NSString *> *identifiers =
      [products valueForKey:@instanceKeypath(BZRProduct, identifier)];
  @weakify(self);
  return [[[self.storeKitFacade
      fetchMetadataForProductsWithIdentifiers:[NSSet setWithArray:identifiers]]
      doNext:^(SKProductsResponse *response) {
        @strongify(self);
        if (response.invalidProductIdentifiers.count) {
          NSSet<NSString *> *productIdentifiers =
              [NSSet setWithArray:response.invalidProductIdentifiers];
          NSError *error = [NSError bzr_invalidProductsErrorWithIdentifers:productIdentifiers];
          [self.nonCriticalErrorsSubject sendNext:error];
        }
      }]
      tryMap:^BZRProductList * _Nullable
          (SKProductsResponse *response, NSError * __autoreleasing *error) {
        @strongify(self);
        if (![response.products count]) {
          if (error) {
            NSSet<NSString *> *productIdentifiers =
                [NSSet setWithArray:response.invalidProductIdentifiers];
            *error = [NSError bzr_invalidProductsErrorWithIdentifers:productIdentifiers];
          }
          return nil;
        }
        return [self productList:products withMetadataFromProductsResponse:response];
      }];
}

- (BZRProductList *)productList:(BZRProductList *)productList
    withMetadataFromProductsResponse:(SKProductsResponse *)productsResponse {
  NSArray<NSString *> *identifiers =
      [productList valueForKey:@instanceKeypath(BZRProduct, identifier)];
  NSDictionary<NSString *, BZRProduct *> *productDictionary =
      [NSDictionary dictionaryWithObjects:productList forKeys:identifiers];
  return [productsResponse.products lt_reduce:^NSMutableArray<BZRProduct *> *
          (NSMutableArray<BZRProduct *> *value, SKProduct *product) {
    BZRProduct *bazaarProduct = productDictionary[product.productIdentifier];
    if (!bazaarProduct) {
      return value;
    }

    BZRProductPriceInfo *priceInfo = [BZRProductPriceInfo productPriceInfoWithSKProduct:product];
    [value addObject:[[bazaarProduct
        modelByOverridingProperty:@keypath(bazaarProduct, priceInfo) withValue:priceInfo]
        modelByOverridingProperty:@keypath(bazaarProduct, bzr_underlyingProduct)
                      withValue:product]];
    return value;
  } initial:[@[] mutableCopy]];
}

@end

NS_ASSUME_NONNULL_END

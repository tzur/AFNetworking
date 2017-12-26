// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsPriceInfoFetcher.h"

#import <LTKit/NSArray+Functional.h>

#import "BZREvent.h"
#import "BZRProduct+SKProduct.h"
#import "BZRProductPriceInfo+SKProduct.h"
#import "BZRStoreKitFacade.h"
#import "NSError+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRProductsPriceInfoFetcher ()

/// Facade used to fetch products metadata with.
@property (readonly, nonatomic) BZRStoreKitFacade *storeKitFacade;

/// Subject used to send errors with.
@property (readonly, nonatomic) RACSubject<BZREvent *> *nonCriticalErrorEventsSubject;

@end

@implementation BZRProductsPriceInfoFetcher

@synthesize eventsSignal = _eventsSignal;

- (instancetype)initWithStoreKitFacade:(BZRStoreKitFacade *)storeKitFacade {
  if (self = [super init]) {
    _storeKitFacade = storeKitFacade;
    _nonCriticalErrorEventsSubject = [RACSubject subject];
    _eventsSignal = [self.nonCriticalErrorEventsSubject takeUntil:[self rac_willDeallocSignal]];
  }

  return self;
}

- (RACSignal<BZRProductList *> *)fetchProductsPriceInfo:(BZRProductList *)products {
  // If the given product list is empty avoid StoreKit overhead and return a signal that delivers an
  // empty list. Returning an empty signal is not good since the returned list might be merged with
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
          NSSet<NSString *> *invalidProductIdentifiers = response.invalidProductIdentifiers.lt_set;
          NSError *error =
              [NSError bzr_invalidProductsErrorWithIdentifiers:invalidProductIdentifiers];
          [self.nonCriticalErrorEventsSubject sendNext:
           [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error]];
        }
      }]
      map:^BZRProductList *(SKProductsResponse *response) {
        @strongify(self);
        if (!self) {
          return @[];
        }

        auto productsWithMetadata =
            [self productList:products withMetadataFromProductsResponse:response];
        return [self productListWithFullPriceInfoForDiscountProducts:productsWithMetadata];
      }];
}

- (BZRProductList *)productList:(BZRProductList *)productList
    withMetadataFromProductsResponse:(SKProductsResponse *)productsResponse {
  NSDictionary<NSString *, BZRProduct *> *productDictionary =
      [self productDictionaryForProductList:productList];

  return [productsResponse.products lt_reduce:^NSMutableArray<BZRProduct *> *
          (NSMutableArray<BZRProduct *> *productListSoFar, SKProduct *product) {
    BZRProduct *bazaarProduct = productDictionary[product.productIdentifier];
    if (!bazaarProduct) {
      return productListSoFar;
    }

    BZRProductPriceInfo *priceInfo = [BZRProductPriceInfo productPriceInfoWithSKProduct:product];
    [productListSoFar addObject:[[bazaarProduct
        modelByOverridingProperty:@keypath(bazaarProduct, priceInfo) withValue:priceInfo]
        modelByOverridingProperty:@keypath(bazaarProduct, bzr_underlyingProduct)
                        withValue:product]];
    return productListSoFar;
  } initial:[NSMutableArray array]];
}

- (BZRProductList *)productListWithFullPriceInfoForDiscountProducts:(BZRProductList *)products {
  BZRProductDictionary *productDictionary = [self productDictionaryForProductList:products];
  BZRProductList *discountedProductsWithFullPriceInfo =
      [[products lt_filter:^BOOL(BZRProduct *product) {
        return product.fullPriceProductIdentifier != nil;
      }]
      lt_map:^BZRProduct *(BZRProduct *discountedProduct) {
        BZRProduct *fullPriceProduct =
            productDictionary[discountedProduct.fullPriceProductIdentifier];
        return [self discountProductWithFullPriceInfo:discountedProduct
                                     fullPriceProduct:fullPriceProduct];
      }];
  BZRProductDictionary *discountedProductDictionary =
      [self productDictionaryForProductList:discountedProductsWithFullPriceInfo];
  return [productDictionary
          mtl_dictionaryByAddingEntriesFromDictionary:discountedProductDictionary].allValues;
}

- (BZRProductDictionary *)productDictionaryForProductList:(BZRProductList *)productList {
  NSArray<NSString *> *identifiers =
      [productList valueForKey:@instanceKeypath(BZRProduct, identifier)];
  return [NSDictionary dictionaryWithObjects:productList forKeys:identifiers];
}

- (BZRProduct *)discountProductWithFullPriceInfo:(BZRProduct *)discountedProduct
                                fullPriceProduct:(BZRProduct *)fullPriceProduct {
  NSDecimalNumber *fullPrice = fullPriceProduct.priceInfo.price;
  BZRProductPriceInfo *priceInfoWithFullPrice =
      [discountedProduct.priceInfo
       modelByOverridingProperty:@keypath(discountedProduct.priceInfo, fullPrice)
       withValue:fullPrice];
  return [[discountedProduct
      modelByOverridingProperty:@keypath(discountedProduct, priceInfo)
      withValue:priceInfoWithFullPrice]
      modelByOverridingProperty:@keypath(discountedProduct, bzr_underlyingProduct)
      withValue:discountedProduct.bzr_underlyingProduct];
}

@end

NS_ASSUME_NONNULL_END

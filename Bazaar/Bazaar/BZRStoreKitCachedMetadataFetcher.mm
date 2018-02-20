// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRStoreKitCachedMetadataFetcher.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRProduct+StoreKit.h"
#import "BZRProductPriceInfo.h"
#import "BZRStoreKitMetadataFetcher.h"

NS_ASSUME_NONNULL_BEGIN

/// Maps product identifiers to StoreKit products.
typedef NSDictionary<NSString *, SKProduct *> BZRSKProductDictionary;

@interface BZRStoreKitCachedMetadataFetcher ()

/// Fetcher used to fetch products' metadata from StoreKit.
@property (readonly, nonatomic) BZRStoreKitMetadataFetcher *underlyingFetcher;

/// Dictionary mapping between product identifiers to products for which the metadata was already
/// fetched.
@property (strong, atomic) BZRSKProductDictionary *cachedProducts;

/// Used to enforce thread safety over the cached products.
@property (readonly, nonatomic) NSObject *cachedProductsLock;

@end

@implementation BZRStoreKitCachedMetadataFetcher

- (instancetype)initWithUnderlyingFetcher:(BZRStoreKitMetadataFetcher *)underlyingFetcher {
  if (self = [super init]) {
    _underlyingFetcher = underlyingFetcher;
    _cachedProducts = @{};
    _cachedProductsLock = [[NSObject alloc] init];
  }
  return self;
}

- (RACSignal<BZRProductList *> *)fetchProductsMetadata:(BZRProductList *)products {
  BZRProductList *nonCachedProducts;
  BZRProductList *cachedProducts;
  @synchronized(self.cachedProductsLock) {
    nonCachedProducts = [products lt_filter:^BOOL(BZRProduct *product) {
      return !self.cachedProducts[product.identifier];
    }];
    cachedProducts = [self cachedProductsFromRequestedProducts:products];
  }

  @weakify(self);
  return [[[self.underlyingFetcher fetchProductsMetadata:nonCachedProducts]
      doNext:^(BZRProductList *fetchedProductList) {
        @strongify(self);
        [self updateCacheFromProductList:fetchedProductList];
      }]
      map:^BZRProductList *(BZRProductList *fetchedProductList) {
        @strongify(self);
        if (!self) {
          return @[];
        }

        auto fetchedAndCachedProducts =
            [fetchedProductList arrayByAddingObjectsFromArray:cachedProducts];
        return [self productListWithFullPriceInfoForDiscountProducts:fetchedAndCachedProducts];
      }];
}

- (void)clearProductsMetadataCache {
  @synchronized(self.cachedProductsLock) {
    self.cachedProducts = @{};
  }
}

- (void)updateCacheFromProductList:(BZRProductList *)productList {
  NSArray<SKProduct *> *storeKitProducts =
      [productList valueForKey:@instanceKeypath(BZRProduct, underlyingProduct)];
  auto storeKitProductDictionary = [self productDictionaryFromSKProductList:storeKitProducts];
  @synchronized(self.cachedProductsLock) {
    self.cachedProducts = [self.cachedProducts
                           mtl_dictionaryByAddingEntriesFromDictionary:storeKitProductDictionary];
  }
}

- (BZRSKProductDictionary *)productDictionaryFromSKProductList:(NSArray<SKProduct *> *)productList {
  NSArray<NSString *> *identifiers = [productList lt_map:^NSString *(SKProduct *product) {
    return product.productIdentifier;
  }];
  return [NSDictionary dictionaryWithObjects:productList forKeys:identifiers];
}

- (BZRProductList *)cachedProductsFromRequestedProducts:(BZRProductList *)requestedProducts {
  return [[requestedProducts
      lt_filter:^BOOL(BZRProduct *product) {
        return self.cachedProducts[product.identifier] != nil;
      }]
      lt_map:^BZRProduct *(BZRProduct *product) {
        auto cachedStoreKitProduct = self.cachedProducts[product.identifier];
        return [product productByAssociatingStoreKitProduct:cachedStoreKitProduct];
      }];
}

- (BZRProductList *)productListWithFullPriceInfoForDiscountProducts:(BZRProductList *)products {
  BZRProductDictionary *productDictionary = [self productDictionaryFromProductList:products];
  BZRProductList *discountedProductsWithFullPriceInfo = [[products
      lt_filter:^BOOL(BZRProduct *product) {
        return product.fullPriceProductIdentifier != nil &&
            productDictionary[product.fullPriceProductIdentifier];
      }]
      lt_map:^BZRProduct *(BZRProduct *discountedProduct) {
        BZRProduct *fullPriceProduct =
            productDictionary[discountedProduct.fullPriceProductIdentifier];
        return [self discountProductWithFullPriceInfo:discountedProduct
                                     fullPriceProduct:fullPriceProduct];
      }];
  BZRProductDictionary *discountedProductDictionary =
      [self productDictionaryFromProductList:discountedProductsWithFullPriceInfo];
  return [productDictionary
          mtl_dictionaryByAddingEntriesFromDictionary:discountedProductDictionary].allValues;
}

- (BZRProductDictionary *)productDictionaryFromProductList:(BZRProductList *)productList {
  NSArray<NSString *> *identifiers =
      [productList valueForKey:@instanceKeypath(BZRProduct, identifier)];
  return [NSDictionary dictionaryWithObjects:productList forKeys:identifiers];
}

- (BZRProduct *)discountProductWithFullPriceInfo:(BZRProduct *)discountedProduct
                                fullPriceProduct:(BZRProduct *)fullPriceProduct {
 return [discountedProduct
     modelByOverridingPropertyAtKeypath:@keypath(discountedProduct, priceInfo.fullPrice)
     withValue:fullPriceProduct.priceInfo.price];
}

#pragma mark -
#pragma mark BZREventEmitter
#pragma mark -

- (RACSignal<BZREvent *> *)eventsSignal {
  return self.underlyingFetcher.eventsSignal;
}

@end

NS_ASSUME_NONNULL_END

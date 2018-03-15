// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRAppStoreLocaleProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRProduct+StoreKit.h"
#import "BZRProductsProvider.h"
#import "BZRStoreKitMetadataFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRAppStoreLocaleProvider ()

/// Provider used to provide the list of products.
@property (readonly, nonatomic) id<BZRProductsProvider> productsProvider;

/// Fetcher used to fetch the App Store locale from a list of products.
@property (readonly, nonatomic) BZRStoreKitMetadataFetcher *metadataFetcher;

/// App Store locale. KVO-compliant.
@property (strong, readwrite, atomic, nullable) NSLocale *appStoreLocale;

@end

@implementation BZRAppStoreLocaleProvider

- (instancetype)initWithProductsProvider:(id<BZRProductsProvider>)productsProvider
                         metadataFetcher:(BZRStoreKitMetadataFetcher *)metadataFetcher {
  if (self = [super init]) {
    _productsProvider = productsProvider;
    _metadataFetcher = metadataFetcher;

    [self refreshAppStoreLocale];
  }
  return self;
}

- (void)refreshAppStoreLocale {
  @weakify(self);
  [[[[self.productsProvider fetchProductList]
      map:^BZRProductList *(BZRProductList *productList) {
        return [productList lt_filter:^BOOL(BZRProduct *product) {
          return product.isSubscriptionProduct;
        }];
      }]
      flattenMap:^RACSignal<NSLocale *> *(BZRProductList *productList) {
        @strongify(self);
        if (!self) {
          return [RACSignal empty];
        }

        return [self fetchLocaleFromProductList:productList];
      }]
      subscribeNext:^(NSLocale *appStoreLocale) {
        @strongify(self);
        if (appStoreLocale != self.appStoreLocale &&
            ![appStoreLocale isEqual:self.appStoreLocale]) {
          self.appStoreLocale = appStoreLocale;
        }
      }];
}

- (RACSignal<NSLocale *> *)fetchLocaleFromProductList:(BZRProductList *)productList {
  if (productList.count == 1) {
    return [[self.metadataFetcher fetchProductsMetadata:productList]
        map:^NSLocale *(BZRProductList *fetchedProductList) {
          return fetchedProductList.firstObject.underlyingProduct.priceLocale;
        }];
  }

  // Maximum fetching retries.
  static const NSUInteger kMaxNumberOfRetries = 10;
  NSUInteger numberOfRetries = std::min(productList.count - 1, kMaxNumberOfRetries);
  __block NSUInteger productIndex = 0;

  @weakify(self);
  return [[RACSignal
      defer:^{
        @strongify(self);
        if (!self) {
          return [RACSignal empty];
        }

        return [[[self.metadataFetcher fetchProductsMetadata:@[productList[productIndex]]]
            map:^NSLocale *(BZRProductList *productListWithMetadata) {
              return productListWithMetadata.firstObject.underlyingProduct.priceLocale;
            }]
            doError:^(NSError *) {
              productIndex++;
            }];
      }]
      retry:numberOfRetries];
}

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRAppStoreLocaleProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRAppStoreLocaleCache.h"
#import "BZRProduct+StoreKit.h"
#import "BZRProductsProvider.h"
#import "BZRStoreKitMetadataFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRAppStoreLocaleProvider ()

/// Cache used to store and retrieve App Store locale of multiple applications.
@property (readonly, nonatomic) BZRAppStoreLocaleCache *appStoreLocaleCache;

/// Provider used to provide the list of products.
@property (readonly, nonatomic) id<BZRProductsProvider> productsProvider;

/// Fetcher used to fetch the App Store locale from a list of products.
@property (readonly, nonatomic) BZRStoreKitMetadataFetcher *metadataFetcher;

/// App Store locale of the currently running application. KVO-compliant.
@property (strong, readwrite, atomic, nullable) NSLocale *appStoreLocale;

/// Bundle ID of the current application.
@property (readonly, nonatomic) NSString *currentApplicationBundleID;

/// Redeclare as readwrite.
@property (readwrite, atomic) BOOL localeFetchedFromProductList;

@end

@implementation BZRAppStoreLocaleProvider

- (instancetype)initWithCache:(BZRAppStoreLocaleCache *)appStoreLocaleCache
             productsProvider:(id<BZRProductsProvider>)productsProvider
              metadataFetcher:(BZRStoreKitMetadataFetcher *)metadataFetcher
   currentApplicationBundleID:(NSString *)currentApplicationBundleID {
  if (self = [super init]) {
    _appStoreLocaleCache = appStoreLocaleCache;
    _productsProvider = productsProvider;
    _metadataFetcher = metadataFetcher;
    _currentApplicationBundleID = [currentApplicationBundleID copy];
    _localeFetchedFromProductList = NO;
    _appStoreLocale = [self.appStoreLocaleCache
                       appStoreLocaleForBundleID:self.currentApplicationBundleID error:nil];
    [self refreshAppStoreLocale];
  }
  return self;
}

- (void)refreshAppStoreLocale {
  @weakify(self);
  [[[[[self.productsProvider fetchProductList]
      map:^BZRProductList *(BZRProductList *productList) {
        return [productList lt_filter:^BOOL(BZRProduct *product) {
          return product.isSubscriptionProduct;
        }];
      }]
      filter:^BOOL(BZRProductList *productList) {
        return productList.count;
      }]
      flattenMap:^RACSignal<NSLocale *> *(BZRProductList *productList) {
        @strongify(self);
        return [self fetchLocaleFromProductList:productList];
      }]
      subscribeNext:^(NSLocale *appStoreLocale) {
        @strongify(self);
        self.appStoreLocale = appStoreLocale;
        self.localeFetchedFromProductList = YES;
        [self.appStoreLocaleCache storeAppStoreLocale:appStoreLocale
                                             bundleID:self.currentApplicationBundleID
                                                error:nil];
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

- (BOOL)storeAppStoreLocale:(nullable NSLocale *)appStoreLocale bundleID:(NSString *)bundleID
                      error:(NSError * __autoreleasing *)error {
  return [self.appStoreLocaleCache storeAppStoreLocale:appStoreLocale bundleID:bundleID
                                                 error:error];
}

- (nullable NSLocale *)appStoreLocaleForBundleID:(NSString *)bundleID
                                           error:(NSError * __autoreleasing *)error {
  return [self.appStoreLocaleCache appStoreLocaleForBundleID:bundleID error:error];
}

@end

NS_ASSUME_NONNULL_END

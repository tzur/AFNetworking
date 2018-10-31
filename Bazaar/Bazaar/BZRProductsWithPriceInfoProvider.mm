// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsWithPriceInfoProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZREvent.h"
#import "BZRProduct.h"
#import "BZRStoreKitMetadataFetcher.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSString+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRProductsWithPriceInfoProvider ()

/// Provider used to provide the list of products.
@property (readonly, nonatomic) id<BZRProductsProvider> underlyingProvider;

/// Fetcher used to fetch price info for products.
@property (readonly, nonatomic) BZRStoreKitMetadataFetcher *storeKitMetadataFetcher;

@end

@implementation BZRProductsWithPriceInfoProvider

@synthesize eventsSignal = _eventsSignal;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithUnderlyingProvider:(id<BZRProductsProvider>)underlyingProvider
                   storeKitMetadataFetcher:(BZRStoreKitMetadataFetcher *)storeKitMetadataFetcher {
  if (self = [super init]) {
    _underlyingProvider = underlyingProvider;
    _storeKitMetadataFetcher = storeKitMetadataFetcher;
    _eventsSignal = [underlyingProvider.eventsSignal takeUntil:[self rac_willDeallocSignal]];
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

- (RACSignal<BZRProductList *> *)fetchProductList {
  @weakify(self);
  return [[[self.underlyingProvider fetchProductList]
      map:^BZRClassifiedProducts *(BZRProductList *productList) {
        return [productList lt_classify:^NSNumber *(BZRProduct * product) {
          return product.isSubscribersOnly ? kNonAppStoreProductsLabel : kAppStoreProductsLabel;
        }];
      }]
      flattenMap:^(BZRClassifiedProducts *classifiedProducts) {
        @strongify(self);
        if (!self) {
          return [RACSignal empty];
        }

        RACSignal<BZRProductList *> *appStoreProductsMapper =
            [self appStoreProductsList:classifiedProducts[kAppStoreProductsLabel] ?: @[]];
        return [appStoreProductsMapper
            map:^BZRProductList *(BZRProductList *appStoreProducts) {
              return [appStoreProducts arrayByAddingObjectsFromArray:
                      classifiedProducts[kNonAppStoreProductsLabel] ?: @[]];
            }];
      }];
}

- (RACSignal<BZRProductList *> *)appStoreProductsList:(BZRProductList *)products {
  return [[[self.storeKitMetadataFetcher fetchProductsMetadata:products]
      try:^BOOL(BZRProductList *productsWithPriceInfo, NSError * __autoreleasing *error) {
        if (![productsWithPriceInfo count]) {
          if (error) {
            *error = [NSError lt_errorWithCode:BZRErrorCodeProductsMetadataFetchingFailed];
          }

          return NO;
        }

        return YES;
      }]
      map:^BZRProductList *(BZRProductList *productsWithPriceInfo) {
        NSArray<NSString *> *productIdentifiers = [productsWithPriceInfo valueForKey:@"identifier"];
        return [productsWithPriceInfo lt_filter:^BOOL(BZRProduct *product) {
          return [product.identifier.bzr_baseProductIdentifier
                  isEqualToString:product.identifier] ||
              [productIdentifiers containsObject:product.identifier.bzr_baseProductIdentifier];
        }];
      }];
}

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsWithVariantsProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRProduct.h"
#import "NSString+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRProductsWithVariantsProvider ()

/// Provider used to fetch product list.
@property (readonly, nonatomic) id<BZRProductsProvider> underlyingProvider;

@end

@implementation BZRProductsWithVariantsProvider

- (instancetype)initWithUnderlyingProvider:(id<BZRProductsProvider>)underlyingProvider {
  if (self = [super init]) {
    _underlyingProvider = underlyingProvider;
  }
  return self;
}

- (RACSignal *)fetchProductList {
  return [[self.underlyingProvider fetchProductList]
      map:^NSArray<BZRProduct *> *(NSArray<BZRProduct *> *productList) {
        NSMutableArray<BZRProduct *> *productListWithVariants = [NSMutableArray array];
        for (BZRProduct *product in productList) {
          [productListWithVariants addObject:product];
          [productListWithVariants addObjectsFromArray:[self productVariantsForProduct:product]];
        }
        return productListWithVariants;
      }];
}

- (NSArray<BZRProduct *> *)productVariantsForProduct:(BZRProduct *)product {
  return [product.variants lt_map:^BZRProduct *(NSString *variantSuffix) {
    NSString *variantIdentifier = [product.identifier bzr_variantWithSuffix:variantSuffix];
    return [[product
        modelByOverridingProperty:@keypath(product, identifier) withValue:variantIdentifier]
        modelByOverridingProperty:@keypath(product, variants) withValue:nil];
  }];
}

@end

NS_ASSUME_NONNULL_END

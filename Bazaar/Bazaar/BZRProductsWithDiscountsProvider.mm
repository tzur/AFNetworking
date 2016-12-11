// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsWithDiscountsProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRProduct.h"
#import "BZRProductTypedefs.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRProductsWithDiscountsProvider ()

/// Provider used to fetch product list.
@property (readonly, nonatomic) id<BZRProductsProvider> underlyingProvider;

@end

@implementation BZRProductsWithDiscountsProvider

- (instancetype)initWithUnderlyingProvider:(id<BZRProductsProvider>)underlyingProvider {
  if (self = [super init]) {
    _underlyingProvider = underlyingProvider;
  }
  return self;
}

- (RACSignal *)fetchProductList {
  return [[self.underlyingProvider fetchProductList]
      map:^BZRProductList *(BZRProductList *productList) {
        NSMutableArray<BZRProduct *> *productListWithVariants = [NSMutableArray array];
        for (BZRProduct *product in productList) {
          [productListWithVariants addObject:product];
          [productListWithVariants addObjectsFromArray:[self discountedProductsForProduct:product]];
        }
        return productListWithVariants;
      }];
}

- (BZRProductList *)discountedProductsForProduct:(BZRProduct *)product {
  return [product.discountedProducts lt_map:^BZRProduct *(NSString *discountIdentifier) {
    return [[product
        modelByOverridingProperty:@keypath(product, identifier) withValue:discountIdentifier]
        modelByOverridingProperty:@keypath(product, discountedProducts) withValue:nil];
  }] ?: @[];
}

- (RACSignal *)nonCriticalErrorsSignal {
  return [[RACSignal never] takeUntil:[self rac_willDeallocSignal]];
}

@end

NS_ASSUME_NONNULL_END

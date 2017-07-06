// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsVariantSelectorFactory.h"

#import "BZRProduct.h"
#import "BZRProductsVariantSelector.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProductsVariantSelectorFactory

- (nullable id<BZRProductsVariantSelector>)productsVariantSelectorWithProductDictionary:
    (NSDictionary<NSString *,BZRProduct *> __unused *)productDictionary
    error:(NSError * __unused __autoreleasing *)error {
  return [[BZRProductsVariantSelector alloc] init];
}

@end

NS_ASSUME_NONNULL_END

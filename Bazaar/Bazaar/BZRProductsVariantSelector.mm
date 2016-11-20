// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsVariantSelector.h"

#import "NSString+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProductsVariantSelector

- (NSString *)selectedVariantForProductWithIdentifier:(NSString *)productIdentifier {
  return productIdentifier;
}

@end

NS_ASSUME_NONNULL_END

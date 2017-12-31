// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct+EnablesProduct.h"

#import <LTKit/NSArray+Functional.h>

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProduct (EnablesProduct)

- (BOOL)enablesProductWithIdentifier:(NSString *)productIdentifier {
  if (self.isSubscriptionProduct && !self.enablesProducts) {
    return YES;
  }

  return [self.enablesProducts lt_find:^BOOL(NSString *productsPrefix) {
    return productsPrefix.length == 0 || [productIdentifier hasPrefix:productsPrefix];
  }] != nil;
}

@end

NS_ASSUME_NONNULL_END

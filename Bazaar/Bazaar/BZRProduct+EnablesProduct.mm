// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct+EnablesProduct.h"

#import <LTKit/NSArray+Functional.h>

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProduct (EnablesProduct)

- (BOOL)doesProductEnablesProductWithIdentifier:(NSString *)productIdentifier {
  return !self.enablesProducts || [self.enablesProducts lt_find:^BOOL(NSString *productsPrefix) {
    return [productIdentifier hasPrefix:productsPrefix];
  }] != nil;
}

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct+StoreKit.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProduct (StoreKit)

- (nullable SKPayment *)underlyingProduct {
  return objc_getAssociatedObject(self, @selector(underlyingProduct));
}

- (void)setUnderlyingProduct:(nullable SKProduct *)product {
  objc_setAssociatedObject(self, @selector(underlyingProduct), product,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

NS_ASSUME_NONNULL_END

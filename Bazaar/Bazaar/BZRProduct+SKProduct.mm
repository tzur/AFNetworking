// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct+SKProduct.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProduct (SKProduct)

- (nullable SKPayment *)bzr_underlyingProduct {
  return objc_getAssociatedObject(self, @selector(bzr_underlyingProduct));
}

- (void)setBzr_underlyingProduct:(nullable SKProduct *)product {
  objc_setAssociatedObject(self, @selector(bzr_underlyingProduct), product,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct.h"

NS_ASSUME_NONNULL_BEGIN

/// Category that adds convenient method for checking whether a product enables another product.
@interface BZRProduct (EnablesProduct)

/// Returns \c YES if the receiver enables the product with \c productIdentifier, and \c NO
/// otherwise.
- (BOOL)enablesProductWithIdentifier:(NSString *)productIdentifier;

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductPriceInfo.h"

NS_ASSUME_NONNULL_BEGIN

/// Adds creation method with a \c SKProduct.
@interface BZRProductPriceInfo (StoreKit)

/// Creates a new \c BZRProductPriceInfo with the given \c product.
+ (instancetype)productPriceInfoWithSKProduct:(SKProduct *)product;

@end

NS_ASSUME_NONNULL_END

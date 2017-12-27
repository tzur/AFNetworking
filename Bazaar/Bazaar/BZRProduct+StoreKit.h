// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct.h"

NS_ASSUME_NONNULL_BEGIN

/// Associates a \c BZRProduct with an \c SKProduct.
@interface BZRProduct (StoreKit)

/// \c SKProduct product associated with the BZRProduct.
@property (readonly, nonatomic, nullable) SKProduct *underlyingProduct;

@end

NS_ASSUME_NONNULL_END

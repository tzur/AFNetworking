// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Provider that wraps another provider and adds additional \c BZRProduct instances for discounted
/// products specified by the product list provided by the underlying provider.
@interface BZRProductsWithDiscountsProvider : NSObject <BZRProductsProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c underlyingProvider, used to fetch product list.
- (instancetype)initWithUnderlyingProvider:(id<BZRProductsProvider>)underlyingProvider
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Provider that returns products variants as \c BZRProduct along with the base products.
@interface BZRProductsWithVariantsProvider : NSObject <BZRProductsProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c underlyingProvider, used to fetch product list.
- (instancetype)initWithUnderlyingProvider:(id<BZRProductsProvider>)underlyingProvider;

@end

NS_ASSUME_NONNULL_END

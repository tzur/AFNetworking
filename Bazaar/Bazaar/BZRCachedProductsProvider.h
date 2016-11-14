// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRProduct;

/// Provider that provides product list using an underlying provider and caches that list locally.
@interface BZRCachedProductsProvider : NSObject <BZRProductsProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c underlyingProvider, used to fetch product list.
- (instancetype)initWithUnderlyingProvider:(id<BZRProductsProvider>)underlyingProvider
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

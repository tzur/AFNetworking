// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRProductsPriceInfoFetcher;

/// Provider that provides product list using an underlying provider and adds price information for
/// products as provided by StoreKit. Products that are subscribersOnly products are not augmented
/// with price information
@interface BZRProductsWithPriceInfoProvider : NSObject <BZRProductsProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c underlyingProvider, used to fetch product list, and with
/// \c priceInfoFetcher, used to fetch price info for each product.
- (instancetype)initWithUnderlyingProvider:(id<BZRProductsProvider>)underlyingProvider
                          priceInfoFetcher:(BZRProductsPriceInfoFetcher *)priceInfoFetcher
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

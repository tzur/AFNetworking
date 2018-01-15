// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRStoreKitMetadataFetcher;

/// Provider that provides product list using an underlying provider and adds price information for
/// products as provided by StoreKit. Products that are subscribersOnly products are not augmented
/// with price information
@interface BZRProductsWithPriceInfoProvider : NSObject <BZRProductsProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c underlyingProvider, used to fetch product list, and with
/// \c storeKitMetadataFetcher, used to fetch additional metadata from StoreKit for each product.
- (instancetype)initWithUnderlyingProvider:(id<BZRProductsProvider>)underlyingProvider
                   storeKitMetadataFetcher:(BZRStoreKitMetadataFetcher *)storeKitMetadataFetcher
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

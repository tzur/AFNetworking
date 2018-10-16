// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZREventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRStoreKitMetadataFetcher;

/// Object used to fetch metadata from StoreKit with caching capabilities.
@interface BZRStoreKitCachedMetadataFetcher : NSObject <BZREventEmitter>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c underlyingFetcher, used to fetch products' metadata.
- (instancetype)initWithUnderlyingFetcher:(BZRStoreKitMetadataFetcher *)underlyingFetcher
    NS_DESIGNATED_INITIALIZER;

/// Fetches metadata for the \c products from StoreKit. Events may be delivered on an arbitrary
/// thread.
///
/// Returns a signal that fetches metadata for all \c products and sends them as a new list of
/// \c BZRProduct augmented with the fetched metadata. If a product's metadata couldn't be fetched,
/// it will not appear in the products list delivered by the signal. The receiver will take the
/// metadata that was already fetched from cache if it exists, otherwise it will be fetched using
/// the \c underlyingFetcher. The signal errs if the underlying fetcher errs.
- (RACSignal<BZRProductList *> *)fetchProductsMetadata:(BZRProductList *)products;

/// Clears the products metadata cache.
- (void)clearProductsMetadataCache;

@end

NS_ASSUME_NONNULL_END

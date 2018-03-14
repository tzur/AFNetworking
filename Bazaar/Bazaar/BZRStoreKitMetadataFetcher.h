// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"
#import "BZRProductTypedefs.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRStoreKitFacade;

/// Object used to fetch metadata from StoreKit for a given list of products and provide a new list
/// of products augmented with the fetched metadata.
@interface BZRStoreKitMetadataFetcher : NSObject <BZREventEmitter>

/// Initializes with \c storeKitFacade, used to fetch products' metadata.
- (instancetype)initWithStoreKitFacade:(BZRStoreKitFacade *)storeKitFacade
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Fetches metadata for the \c products. Events may be delivered on an arbitrary thread.
///
/// Returns a signal that fetches metadata for all \c products and sends them as a new list of
/// \c BZRProduct augmented with the fetched metadata. If a product's metadata couldn't be fetched,
/// it will not appear in the products list delivered by the signal. The signal completes after
/// sending the list of products. The signal errs if fetching the products' metadata encountered an
/// error, or no products metadata was fetched. The error code will be
/// \c BZRErrorCodeProductsMetadataFetchingFailed.
- (RACSignal<BZRProductList *> *)fetchProductsMetadata:(BZRProductList *)products;

@end

NS_ASSUME_NONNULL_END

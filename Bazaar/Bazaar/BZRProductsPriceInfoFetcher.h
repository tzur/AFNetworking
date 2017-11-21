// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"
#import "BZRProductTypedefs.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRStoreKitFacade;

/// Object used to fetch price info for a given list of products.
@interface BZRProductsPriceInfoFetcher : NSObject <BZREventEmitter>

/// Initializes with \c storeKitFacade, used to fetch products' price info.
- (instancetype)initWithStoreKitFacade:(BZRStoreKitFacade *)storeKitFacade
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Fetches price info for the \c products. Events may be delivered on an arbitrary thread.
///
/// Returns a signal that fetches the price info of all \c products and sends them as a list of
/// \c BZRProduct that contain the prices. If a product's price info couldn't be fetched, it
/// will not appear in the products list delivered by the signal. The signal completes after sending
/// the list of products. The signal errs if fetching the products' price info encountred an error,
/// the error code will be \c BZRErrorCodeProductsMetadataFetchingFailed.
- (RACSignal<BZRProductList *> *)fetchProductsPriceInfo:(BZRProductList *)products;

@end

NS_ASSUME_NONNULL_END

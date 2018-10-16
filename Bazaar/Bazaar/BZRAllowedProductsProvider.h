// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRAcquiredViaSubscriptionProvider, BZRMultiAppReceiptValidationStatusProvider;

@protocol BZRProductsProvider;

/// Provider used to provide the set of products the user is allowed to use.
@protocol BZRAllowedProductsProvider

/// Set of product identifiers that the user is allowed to use. KVO-compliant. Changes may be
/// delivered on an arbitrary thread.
@property (readonly, nonatomic) NSSet<NSString *> *allowedProducts;

@end

/// Default implementation of \c BZRAllowedProductsProvider.
@interface BZRAllowedProductsProvider : NSObject <BZRAllowedProductsProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c productsProvider, used to provide the product list.
/// \c multiAppValidationStatusProvider is used to provide the latest receipt validation statuses.
/// \c acquiredViaSubscriptionProvider is used to provide acquired via subscription products.
- (instancetype)initWithProductsProvider:(id<BZRProductsProvider>)productsProvider
    multiAppValidationStatusProvider:(BZRMultiAppReceiptValidationStatusProvider *)
    multiAppValidationStatusProvider
    acquiredViaSubscriptionProvider:(BZRAcquiredViaSubscriptionProvider *)
    acquiredViaSubscriptionProvider
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRAcquiredViaSubscriptionProvider, BZRCachedReceiptValidationStatusProvider;

@protocol BZRProductsProvider;

/// Provider used to provide the set of products the user is allowed to use.
@interface BZRAllowedProductsProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c productsProvider, used to provide the product list.
/// \c validationStatusProvider is used to provide the latest receipt validation status.
/// \c acquiredViaSubscriptionProvider is used to provide acquired via subscription products.
- (instancetype)initWithProductsProvider:(id<BZRProductsProvider>)productsProvider
    validationStatusProvider:(BZRCachedReceiptValidationStatusProvider *)validationStatusProvider
    acquiredViaSubscriptionProvider:(BZRAcquiredViaSubscriptionProvider *)
    acquiredViaSubscriptionProvider
    NS_DESIGNATED_INITIALIZER;

/// Set of product identifiers that the user is allowed to use. KVO-compliant. Changes may be
/// delivered on an arbitrary thread.
@property (readonly, nonatomic) NSSet<NSString *> *allowedProducts;

@end

NS_ASSUME_NONNULL_END

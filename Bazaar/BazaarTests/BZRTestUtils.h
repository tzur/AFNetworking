// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRContentFetcherParameters, BZRProduct, BZRReceiptInAppPurchaseInfo,
    BZRReceiptSubscriptionInfo, BZRReceiptValidationStatus;

/// Returns a \c BZRProduct with identifier set to \c identifier with content.
BZRProduct *BZRProductWithIdentifierAndContent(NSString *identifier);

/// Returns a \c BZRProduct with identifier set to \c identifier without content.
BZRProduct *BZRProductWithIdentifier(NSString *identifier);

/// Returns a \c BZRProduct with identifier set to \c identifier and with
/// \c contentProviderParameters set to \c parameters.
BZRProduct *BZRProductWithIdentifierAndParameters(NSString *identifier,
    BZRContentFetcherParameters * _Nullable parameters);

/// Returns a \c BZRReceiptValidationStatus with \c subscription expiry set to \c expiry. If
/// \c cancelled is \c YES then \c receip.subscription.cancellation date will be set to somewhen
/// between now and the expiration date.
BZRReceiptValidationStatus *BZRReceiptValidationStatusWithExpiry(BOOL expiry, BOOL cancelled = NO);

/// Returns a \c BZRReceiptValidationStatus with an in-app purchase with identifier set to
/// \c identifier and \c subscription expiry set to \c expiry.
BZRReceiptValidationStatus *BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(
    NSString *identifier, BOOL expiry);

/// Returns a \c BZRReceiptValidationStatus with a not expired subscription with an identifier set
/// to \c subscriptionIdentifier.
BZRReceiptValidationStatus *BZRReceiptValidationStatusWithSubscriptionIdentifier
    (NSString *subscriptionIdentifier);

/// Returns a \c SKProductsResponse with products set to \c products.
SKProductsResponse *BZRProductsResponseWithSKProducts(NSArray<SKProduct *> *products);

/// Returns a \c SKProductsResponse with a single \c SKProduct with identifier \c productIdentifier.
SKProductsResponse *BZRProductsResponseWithProduct(NSString *productIdentifier);

/// Returns a \c SKProductsResponse with \c SKProducts with identifiers \c productIdentifiers.
SKProductsResponse *BZRProductsResponseWithProducts(NSArray<NSString *> *productsIdentifiers);

NS_ASSUME_NONNULL_END

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRContentFetcherParameters, BZRProduct, BZRReceiptInAppPurchaseInfo,
    BZRReceiptSubscriptionInfo, BZRReceiptTransactionInfo, BZRReceiptValidationStatus;

/// Returns a \c BZRProduct with identifier set to \c identifier with content.
BZRProduct *BZRProductWithIdentifierAndContent(NSString *identifier);

/// Returns a \c BZRProduct with identifier set to \c identifier without content.
BZRProduct *BZRProductWithIdentifier(NSString *identifier);

/// Returns a \c BZRProduct with identifier set to \c identifier and with
/// \c contentFetcherParameters set to \c parameters.
BZRProduct *BZRProductWithIdentifierAndParameters(NSString *identifier,
    BZRContentFetcherParameters * _Nullable parameters);

/// Returns a \c BZRReceiptValidationStatus with \c subscription expiry set to \c expiry. If
/// \c cancelled is \c YES then \c receipt.subscription.cancellation date will be set to somewhen
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

/// Returns an \c SKProduct with the given properties.
SKProduct *BZRSKProductWithProperties(NSString *identifier,
    NSDecimalNumber *price = [NSDecimalNumber one],
    NSString *localeIdentifier = [NSLocale currentLocale].localeIdentifier);

/// Returns an \c SKProductsResponse with products set to \c products.
SKProductsResponse *BZRProductsResponseWithSKProducts(NSArray<SKProduct *> *products);

/// Returns an \c SKProductsResponse containing a single \c SKProduct with the given
/// \c productIdentifier.
SKProductsResponse *BZRProductsResponseWithProduct(NSString *productIdentifier);

/// Returns an \c SKProductsResponse with \c SKProducts with identifiers \c productIdentifiers.
SKProductsResponse *BZRProductsResponseWithProducts(NSArray<NSString *> *productIdentifiers);

/// Returns a \c BZRReceiptTransactionInfo with transaction identifier set to \c transactionId.
BZRReceiptTransactionInfo *BZRTransactionWithTransactionIdentifier(NSString *transactionId);

NS_ASSUME_NONNULL_END

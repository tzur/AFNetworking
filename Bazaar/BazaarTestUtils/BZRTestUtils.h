// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRContentFetcherParameters, BZRProduct, BZRProductType, BZRReceiptInAppPurchaseInfo,
    BZRReceiptSubscriptionInfo, BZRReceiptTransactionInfo, BZRReceiptValidationStatus;

/// Returns a \c BZRProduct of type \c productType with identifier set to \c identifier
/// without content.
BZRProduct *BZRProductWithIdentifierAndType(NSString *identifier, BZRProductType *productType);

/// Returns a \c BZRProduct with identifier set to \c identifier with content.
BZRProduct *BZRProductWithIdentifierAndContent(NSString *identifier);

/// Returns a \c BZRProduct with identifier set to \c identifier without content.
BZRProduct *BZRProductWithIdentifier(NSString *identifier);

/// Returns a \c BZRProduct with identifier set to \c identifier and with
/// \c contentFetcherParameters set to \c parameters.
BZRProduct *BZRProductWithIdentifierAndParameters(NSString *identifier,
    BZRContentFetcherParameters * _Nullable parameters);

/// Returns a \c BZRReceiptValidationStatus without any subscription, transaction or in app
/// purchases.
BZRReceiptValidationStatus *BZREmptyReceiptValidationStatus();

/// Returns a \c BZRReceiptValidationStatus with \c subscription expiry set to \c expiry. If
/// \c cancelled is \c YES then \c receipt.subscription.cancellation date will be set to somewhen
/// between now and the expiration date.
BZRReceiptValidationStatus *BZRReceiptValidationStatusWithExpiry(BOOL expiry, BOOL cancelled = NO);

/// Returns a \c BZRReceiptValidationStatus with an in-app purchase with identifier set to
/// \c identifier and \c subscription expiry set to \c expiry.
BZRReceiptValidationStatus *BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(
    NSString *identifier, BOOL expiry);

/// Returns a \c BZRReceiptInAppPurchaseInfo with identifier set to \c productID.
BZRReceiptInAppPurchaseInfo *BZRReceiptInAppPurchaseInfoWithProductID(NSString *productID);

/// Returns a \c BZRReceiptValidationStatus with a not expired subscription with an identifier set
/// to \c subscriptionIdentifier.
BZRReceiptValidationStatus *BZRReceiptValidationStatusWithSubscriptionIdentifier
    (NSString *subscriptionIdentifier);

/// Returns a mock of \c SKProduct with the given properties.
SKProduct *BZRMockedSKProductWithProperties(NSString *identifier,
    NSDecimalNumber *price = [NSDecimalNumber one],
    NSString *localeIdentifier = [NSLocale currentLocale].localeIdentifier);

/// Returns a mock of \c SKProductsResponse with products set to \c products.
SKProductsResponse *BZRMockedProductsResponseWithSKProducts(NSArray<SKProduct *> *products);

/// Returns a mock of \c SKProductsResponse containing a single \c SKProduct with the given
/// \c productIdentifier.
SKProductsResponse *BZRMockedProductsResponseWithProduct(NSString *productIdentifier);

/// Returns a mock of \c SKProductsResponse with \c SKProducts with identifiers
/// \c productIdentifiers.
SKProductsResponse *BZRMockedProductsResponseWithProducts(NSArray<NSString *> *productIdentifiers);

/// Returns a \c BZRReceiptTransactionInfo with transaction identifier set to \c transactionId.
BZRReceiptTransactionInfo *BZRTransactionWithTransactionIdentifier(NSString *transactionId);

/// Returns a mock of \c SKPaymentTransaction with an underlying mocked \c SKPayment with productID
/// set to \c productID, transaction identifier set to \c transactionID, transaction state set to
/// \c state and transaction Date set to \c transactionDate, the two latter arguments have default
/// values.
SKPaymentTransaction *BZRMockedSKPaymentTransaction(NSString *productID, NSString *transactionID,
     SKPaymentTransactionState state = SKPaymentTransactionStatePurchased,
     NSDate *transactionDate = [NSDate date]);

/// Returns a \c BZRReceiptSubscriptionInfo with identifier set to \c subscriptionIdentifier.
 BZRReceiptSubscriptionInfo *BZRSubscriptionWithIdentifier(NSString *subscriptionIdentifier,
     BOOL expired = NO, BOOL cancelled = NO);

NS_ASSUME_NONNULL_END

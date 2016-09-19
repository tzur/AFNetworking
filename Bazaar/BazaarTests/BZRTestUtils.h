// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRContentFetcherParameters, BZRProduct, BZRReceiptInAppPurchaseInfo,
    BZRReceiptValidationStatus;

/// Returns a \c BZRProduct with identifier set to \c identifier with content.
BZRProduct *BZRProductWithIdentifierAndContent(NSString *identifier);

/// Returns a \c BZRProduct with identifier set to \c identifier without content.
BZRProduct *BZRProductWithIdentifier(NSString *identifier);

/// Returns a \c BZRProduct with identifier set to \c identifier and with
/// \c contentProviderParameters set to \c parameters.
BZRProduct *BZRProductWithIdentifierAndParameters(NSString *identifier,
    BZRContentFetcherParameters * _Nullable parameters);

/// Returns a \c BZRReceiptValidationStatus with \c subscription expiry set to \c expiry.
BZRReceiptValidationStatus *BZRReceiptValidationStatusWithExpiry(BOOL expiry);

/// Returns a \c BZRReceiptValidationStatus with an in-app purchase with identifier set to
/// \c identifier and \c subscription expiry set to \c expiry.
BZRReceiptValidationStatus *BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(
    NSString *identifier, BOOL expiry);

NS_ASSUME_NONNULL_END

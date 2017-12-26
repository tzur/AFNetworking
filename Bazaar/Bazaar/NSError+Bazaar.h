// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@class BZRContentFetcherParameters;

/// Adds methods and properties to conveniently create Bazaar errors.
@interface NSError (Bazaar)

/// Creates and returns an instance of \c NSError with the given error \c code wrapping the given
/// \c exception object. Meant to be used to convert \c NSException based error reporting to
/// \c NSError based reporting.
+ (instancetype)bzr_errorWithCode:(NSInteger)code exception:(NSException *)exception;

/// Creates and returns an instance of \c NSError with the given products \c request wrapping the
/// given \c underlyingError.
+ (instancetype)bzr_errorWithCode:(NSInteger)code productsRequest:(SKProductsRequest *)request
                  underlyingError:(NSError *)underlyingError;

/// Creates and returns an instance of \c NSError with the given error \c code. \c arhivePath
/// is the path to the archive file that the failing archiving operation was executed on.
/// \c failingItemPath is the path to the file or directory that caused the failure.
/// \c underlyingError may be provided to specify an underlying error. A custom error \c description
/// may be provided.
+ (instancetype)bzr_errorWithCode:(NSInteger)code
                      archivePath:(NSString *)archivePath
           failingArchiveItemPath:(nullable NSString *)failingItemPath
                  underlyingError:(nullable NSError *)underlyingError
                      description:(nullable NSString *)description;

/// Creates and returns an instance of \c NSError with the given error \c code wrapping the given
/// \c transaction.
+ (instancetype)bzr_errorWithCode:(NSInteger)code transaction:(SKPaymentTransaction *)transaction;

/// Creates and returns an instance of \c NSError with \c domain set to \c LTErrorDomain, \c code
/// set to \c BZRErrorCodeInvalidProductIdentifier and \c bzr_productIdentifiers set to the given
/// \c productIdentifiers.
+ (instancetype)bzr_invalidProductsErrorWithIdentifiers:(NSSet<NSString *> *)productIdentifiers;

/// Creates and returns an instance of \c NSError with error code
/// \c BZRErrorPeriodicReceiptValidationFailed. \c secondsUntilSubscriptionInvalidation is the
/// number of seconds left until subscription is marked as expired. \c receiptLastValidationDate is
/// the date of the last receipt validation. \c underlyingError specifies the reason for the failure
/// in the periodic validation.
+ (instancetype)bzr_errorWithSecondsUntilSubscriptionInvalidation:
    (NSNumber *)secondsUntilSubscriptionInvalidation
    lastReceiptValidationDate:(NSDate *)lastReceiptValidationDate
    underlyingError:(NSError *)underlyingError;

/// Creates and returns an instance of \c NSError with \c code set to
/// \c BZRErrorCodePurchasedProductNotFoundInReceipt and \c bzr_purchasedProductIdentifier set to
/// the given \c productIdentifier.
+ (instancetype)bzr_purchasedProductNotFoundInReceipt:(NSString *)productIdentifier;

/// Creates and returns an instance of \c NSError with \c code set to
/// \c BZRErrorCodeFetchingProductContentFailed and \c bzr_contentFetcherParameters set to the
/// given \c parameters. \c underlyingError specifies the reason for the failure in the content
/// fetching.
+ (instancetype)bzr_errorWithContentFetcherParameters:(BZRContentFetcherParameters *)parameters
                                      underlyingError:(NSError *)underlyingError;

/// Exception object wrapped by this error.
@property (readonly, nonatomic, nullable) NSException *bzr_exception;

/// Failing products request.
@property (readonly, nonatomic, nullable) SKProductsRequest *bzr_productsRequest;

/// Path of the archive file that a failing archiving operation was executed on.
@property (readonly, nonatomic, nullable) NSString *bzr_archivePath;

/// Path of the failing item that was archived or unarchived.
@property (readonly, nonatomic, nullable) NSString *bzr_failingItemPath;

/// Failed transaction wrapped by this error.
@property (readonly, nonatomic, nullable) SKPaymentTransaction *bzr_transaction;

/// Invalid product identifiers related to the error.
@property (readonly, nonatomic, nullable) NSSet<NSString *> *bzr_productIdentifiers;

/// Seconds left until subscription is marked as expired. a negative value means the subscription
/// was marked as expired already or will be marked as expired shortly.
@property (readonly, nonatomic, nullable) NSNumber *bzr_secondsUntilSubscriptionInvalidation;

/// Date of the last time receipt was validated.
@property (readonly, nonatomic, nullable) NSDate *bzr_lastReceiptValidationDate;

/// Identifier of the product that was purchased but not found in the receipt.
@property (readonly, nonatomic, nullable) NSString *bzr_purchasedProductIdentifier;

/// Parameters of the content whose fetching has failed.
@property (readonly, nonatomic, nullable) BZRContentFetcherParameters *bzr_contentFetcherParameters;

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorage, BZRReceiptValidationStatus;

@protocol BZRReceiptValidationParametersProvider, BZRReceiptValidator;

/// Provider used to provide \c BZRReceiptValidationStatus by validating the receipt and by giving
/// access to the status of the latest successful validation.
@interface BZRReceiptValidationStatusProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the receiver with \c keychainStorage used to cache receipt validation status. 
/// The receiver will use \c BZRValidatricksReceiptValidator for validating the receipt feeding
/// it with validation parameters provided by a \c BZRReceiptValidationParametersProvider.
- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage;

/// Initializes with \c keychainStorage, used to cache receipt validation status.
/// \c receiptValidator is used to validate the receipt and return the latest
/// \c BZRReceiptValidationStatus. \c validationParametersProvider is used to provide validation
/// parameters to \c receiptValidator to validate the receipt.
- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage
    receiptValidator:(id<BZRReceiptValidator>)receiptValidator
    validationParametersProvider:
    (id<BZRReceiptValidationParametersProvider>)validationParametersProvider
    NS_DESIGNATED_INITIALIZER;

/// Validates the receipt and provides \c BZRReceiptValidationStatus if the validation has
/// succeeded.
///
/// Returns a signal that validates the receipt and delivers a \c BZRReceiptValidationStatus as
/// provided by the underlying validator and then completes. The signal errs if there was a problem
/// while performing the validation, or if the validation has failed. Upon success,
/// /c receiptValidationResponse property will be updated and stored into secure storage.
///
/// @return <tt>RACSignal<BZRReceiptValidationStatus></tt>
- (RACSignal *)validateReceipt;

/// Holds the most recent receipt validation status that was completed successfully. If
/// \c validateReceipt has never completed successfully, this holds the value loaded using
/// \c keychainStorage. If the value doesn't exist in storage, this property will be \c nil.
@property (readonly, nonatomic, nullable) BZRReceiptValidationStatus *receiptValidationStatus;

/// Sends storage errors as values. The signal completes when the receiver is deallocated. The
/// signal doesn't err.
///
/// @return <tt>RACSignal<NSError></tt>
@property (readonly, nonatomic) RACSignal *storageErrorsSignal;

@end

NS_ASSUME_NONNULL_END

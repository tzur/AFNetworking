// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRExternalTriggerReceiptValidator, BZRMultiAppReceiptValidationStatusProvider;

@protocol LTDateProvider;

@protocol BZRReceiptValidationDateProvider;

/// Activator used to activate and deactivate periodic receipt validation. The periodic validation
/// is activated only if the user is a subscriber, and the interval between validations is
/// calculated as a function of the subscription length.
@interface BZRPeriodicReceiptValidatorActivator : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Convenience initializer that initializes \c receiptValidator with the designated initializer
/// with the given \c multiAppReceiptValidationStatusProvider.
- (instancetype)initWithMultiAppValidationStatusProvider:
    (BZRMultiAppReceiptValidationStatusProvider *)multiAppReceiptValidationStatusProvider
    validationDateProvider:(id<BZRReceiptValidationDateProvider>)validationDateProvider
    dateProvider:(id<LTDateProvider>)dateProvider;

/// Initializes with \c receiptValidator used to validate the receipt periodically.
/// \c validationDateProvider is used to provide the next validation date. \c dateProvider is used
/// to provide the current date.
- (instancetype)initWithReceiptValidator:(BZRExternalTriggerReceiptValidator *)receiptValidator
    validationDateProvider:(id<BZRReceiptValidationDateProvider>)validationDateProvider
    dateProvider:(id<LTDateProvider>)dateProvider NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRAggregatedReceiptValidationStatusProvider, BZRExternalTriggerReceiptValidator,
    BZRTimeProvider;

@protocol BZRReceiptValidationDateProvider;

/// Activator used to activate and deactivate periodic receipt validation. The periodic validation
/// is activated only if the user is a subscriber, and the interval between validations is
/// calculated as a function of the subscription length.
@interface BZRPeriodicReceiptValidatorActivator : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Convenience initializer that initializes \c receiptValidator with the designated initializer
/// with the given \c aggregatedValidationStatusProvider.
- (instancetype)initWithAggregatedValidationStatusProvider:
    (BZRAggregatedReceiptValidationStatusProvider *)aggregatedValidationStatusProvider
    validationDateProvider:(id<BZRReceiptValidationDateProvider>)validationDateProvider
    timeProvider:(BZRTimeProvider *)timeProvider;

/// Initializes with \c receiptValidator used to validate the receipt periodically.
/// \c validationDateProvider is used to provide the next validation date. \c timeProvider is used
/// to provide the current time.
- (instancetype)initWithReceiptValidator:(BZRExternalTriggerReceiptValidator *)receiptValidator
    validationDateProvider:(id<BZRReceiptValidationDateProvider>)validationDateProvider
    timeProvider:(BZRTimeProvider *)timeProvider NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

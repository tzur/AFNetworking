// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRAggregatedReceiptValidationStatusProvider, BZRCachedReceiptValidationStatusProvider,
    BZREvent, BZRExternalTriggerReceiptValidator;

@protocol BZRTimeProvider;

/// Activator used to activate and deactivate periodic receipt validation. The periodic validation
/// is activated only if the user is a subscriber, and the interval between validations is
/// calculated as a function of the subscription length.
@interface BZRPeriodicReceiptValidatorActivator : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the receiver with the given \c validationStatusProvider that will be used to
/// fetch receipt validation status. The \c timeProvider will be used to determine whether and when
/// to fetch the receipt validation status.
- (instancetype)initWithValidationStatusProvider:
    (BZRCachedReceiptValidationStatusProvider *)validationStatusProvider
    timeProvider:(id<BZRTimeProvider>)timeProvider
    bundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs
    aggregatedValidationStatusProvider:
    (BZRAggregatedReceiptValidationStatusProvider *)aggregatedValidationStatusProvider;

/// Initializes with \c receiptValidator used to validate the receipt periodically.
/// \c validationStatusProvider is used to fetch the latest receipt validation status and provide
/// the validation date. \c timeProvider is used to check if the receipt should be validated.
/// \c bundledApplicationsIDs is the set of applications for which validation will be performed.
/// \c aggregatedValidationStatusProvider is used to provide the latest aggregated receipt
/// validation status and determine whether periodic validation is required.
///
/// If both the periodic validation interval and the grace period have passed, subscription is
/// marked as expired.
- (instancetype)initWithReceiptValidator:(BZRExternalTriggerReceiptValidator *)receiptValidator
    validationStatusProvider:(BZRCachedReceiptValidationStatusProvider *)validationStatusProvider
    timeProvider:(id<BZRTimeProvider>)timeProvider
    bundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs
    aggregatedValidationStatusProvider:
    (BZRAggregatedReceiptValidationStatusProvider *)aggregatedValidationStatusProvider
    NS_DESIGNATED_INITIALIZER;

@end

/// Category exposing properties for testing purposes.
@interface BZRPeriodicReceiptValidatorActivator (ForTesting)

/// Time between each periodic validation.
@property (readonly, nonatomic) NSTimeInterval periodicValidationInterval;

/// Returns a signal that sends \c [NSDate date] after \c timeToNextValidation seconds if its larger
/// than 0, and otherwise sends \c [NSDate date] immediately. After that, it sends \c [NSDate date]
/// every \c periodicValidationInterval seconds.
- (RACSignal<NSDate *> *)timerSignal:(NSNumber *)timeToNextValidation;

@end

NS_ASSUME_NONNULL_END

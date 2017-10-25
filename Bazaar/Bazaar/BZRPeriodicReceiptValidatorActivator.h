// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRCachedReceiptValidationStatusProvider, BZREvent, BZRExternalTriggerReceiptValidator;

@protocol BZRTimeProvider;

/// Activator used to activate and deactivate periodic receipt validation. The periodic validation
/// is activated only if the user is a subscriber, and the interval between validations is
/// calculated as a function of the subscription length.
@interface BZRPeriodicReceiptValidatorActivator : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the receiver with the given \c validationStatusProvider that will be used to
/// fetch receipt validation status. The \c timeProvider and \c gracePeriod will be used to
/// determine whether and when to fetch the receipt validation status.
- (instancetype)initWithValidationStatusProvider:
    (BZRCachedReceiptValidationStatusProvider *)validationStatusProvider
    timeProvider:(id<BZRTimeProvider>)timeProvider gracePeriod:(NSUInteger)gracePeriod;

/// Initializes with \c receiptValidator used to validate the receipt periodically.
/// \c validationStatusProvider is used to fetch the latest receipt validation status and provide
/// the validation date. \c timeProvider is used to check if the receipt should be validated.
/// \c gracePeriod is the number of days the receipt is allowed to remain not validated
/// beyond the calculated period validation interval.
///
/// If both the periodic validation interval and the grace period have passed, subscription is
/// marked as expired.
- (instancetype)initWithReceiptValidator:(BZRExternalTriggerReceiptValidator *)receiptValidator
    validationStatusProvider:(BZRCachedReceiptValidationStatusProvider *)validationStatusProvider
    timeProvider:(id<BZRTimeProvider>)timeProvider gracePeriod:(NSUInteger)gracePeriod
    NS_DESIGNATED_INITIALIZER;

/// Sends error events when periodic validation failed or when other errors occurred. In case of
/// periodic validation error, the days until subscription expiration and the last validation date
/// will be sent in \c error property. The signal completes when the receiver is deallocated. The
/// signal doesn't err.
@property (readonly, nonatomic) RACSignal<BZREvent *> *errorEventsSignal;

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

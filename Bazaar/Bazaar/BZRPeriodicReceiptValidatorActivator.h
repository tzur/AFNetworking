// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRCachedReceiptValidationStatusProvider, BZRPeriodicReceiptValidator;

@protocol BZRTimeProvider;

/// Activator used to activate and deactivate periodic receipt validation. The periodic validation
/// is activated only if the user is a subscriber, and the interval between validations is
/// calculated as a function of the subscription length.
@interface BZRPeriodicReceiptValidatorActivator : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c periodicReceiptValidator used to be activated and deactivated.
/// \c receiptValidationProvider is used to provide the latest receipt validation
/// status and last validation date. \c timeProvider is used to check if the receipt should be
/// validated. \c gracePeriod is the number of days the receipt is allowed to remain not validated
/// beyond the calculated period validation interval. If both the periodic validation interval and
/// the grace period has passed, subscription is marked as expired.
- (instancetype)initWithPeriodicReceiptValidator:
    (BZRPeriodicReceiptValidator *)periodicReceiptValidator
    validationStatusProvider:(BZRCachedReceiptValidationStatusProvider *)validationStatusProvider
    timeProvider:(id<BZRTimeProvider>)timeProvider gracePeriod:(NSUInteger)gracePeriod
    NS_DESIGNATED_INITIALIZER;

/// Sends error events when periodic validation failed or when other errors occurred. In case of
/// periodic validation error, the days until subscription expiration and the last validation date
/// will be sent in \c error property. The signal completes when the receiver is deallocated. The
/// signal doesn't err.
///
/// @return <tt>RACSignal<BZREvent></tt>
@property (readonly, nonatomic) RACSignal *errorEventsSignal;

@end

/// Category exposing properties for testing purposes.
@interface BZRPeriodicReceiptValidatorActivator (ForTesting)

/// Time between each periodic validation.
@property (readonly, nonatomic) NSTimeInterval periodicValidationInterval;

/// Returns a signal that sends \c [NSDate date] after \c timeToNextValidation seconds if its larger
/// than 0, and otherwise sends \c [NSDate date] immediately. After that, it sends \c [NSDate date]
/// every \c periodicValidationInterval seconds.
///
/// @return <tt>RACSignal<NSDate></tt>
- (RACSignal *)timerSignal:(NSNumber *)timeToNextValidation;

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPeriodicReceiptValidatorActivator.h"

#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRPeriodicReceiptValidator.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTimeConversion.h"
#import "BZRTimeProvider.h"
#import "NSError+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRPeriodicReceiptValidatorActivator ()

/// Validator that is activated and deactivated depending on the receipt validation status.
@property (readonly, nonatomic) BZRPeriodicReceiptValidator *periodicReceiptValidator;

/// Provider used to provide the latest receipt validation status.
@property (readonly, nonatomic) BZRCachedReceiptValidationStatusProvider *validationStatusProvider;

/// Provider used to check if the receipt should be validated.
@property (readonly, nonatomic) id<BZRTimeProvider> timeProvider;

/// Number of seconds the receipt is allowed to remain not validated until the subscription becomes
/// expired.
@property (readonly, nonatomic) NSTimeInterval gracePeriod;

/// The other end of \c errorsSignal used to send errors with.
@property (readonly, nonatomic) RACSubject *errorsSubject;

/// Time between each periodic validation.
@property (readwrite, nonatomic) NSTimeInterval periodicValidationInterval;

@end

@implementation BZRPeriodicReceiptValidatorActivator

/// Factor to multiply by the subscription duration to get the timer period.
const double kTimerPeriodFromSubscriptionDurationFactor = 0.5;

/// The maximum number of days between each timer activation.
const NSUInteger kMaxPeriodicValidationInterval = 28;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithPeriodicReceiptValidator:
    (BZRPeriodicReceiptValidator *)periodicReceiptValidator
    validationStatusProvider:(BZRCachedReceiptValidationStatusProvider *)validationStatusProvider
    timeProvider:(id<BZRTimeProvider>)timeProvider gracePeriod:(NSUInteger)gracePeriod {
  if (self = [super init]) {
    _validationStatusProvider = validationStatusProvider;
    _periodicReceiptValidator = periodicReceiptValidator;
    _timeProvider = timeProvider;
    _gracePeriod = [BZRTimeConversion numberOfSecondsInDays:gracePeriod];
    _errorsSubject = [RACSubject subject];
    _errorsSignal = [[RACSignal merge:@[
      self.errorsSubject,
      [[self periodicValidationErrorsSignal] replayLast]
    ]]
    takeUntil:[self rac_willDeallocSignal]];

    [self activateTimerWhenSubscriptionExists];
  }
  return self;
}

#pragma mark -
#pragma mark Activating/deactivating timer
#pragma mark -

- (void)activateTimerWhenSubscriptionExists {
  @weakify(self);
  [RACObserve(self.validationStatusProvider, receiptValidationStatus)
      subscribeNext:^(BZRReceiptValidationStatus * _Nullable receiptValidationStatus) {
        @strongify(self);
        BZRReceiptSubscriptionInfo *subscription = receiptValidationStatus.receipt.subscription;
        if (subscription) {
          [self activatePeriodicValidation:subscription];
        } else {
          [self.periodicReceiptValidator deactivatePeriodicValidationCheck];
        }
      }];
}

- (void)activatePeriodicValidation:(BZRReceiptSubscriptionInfo *)subscription {
  @weakify(self);
  [[self.timeProvider currentTime] subscribeNext:^(NSDate *currentTime) {
    @strongify(self);
    self.periodicValidationInterval = [self periodicValidationIntervalForSubscription:subscription];
    [self activatePeriodicValidationWithTime:currentTime];
  } error:^(NSError *error) {
    @strongify(self);
    [self.errorsSubject sendNext:error];
  }];
}

- (NSTimeInterval)periodicValidationIntervalForSubscription:
    (BZRReceiptSubscriptionInfo *)subscription {
  NSTimeInterval subscriptionDuration =
      [subscription.expirationDateTime timeIntervalSinceDate:
       (subscription.lastPurchaseDateTime ?: subscription.originalPurchaseDateTime)];
  return std::min(subscriptionDuration * kTimerPeriodFromSubscriptionDurationFactor,
      [BZRTimeConversion numberOfSecondsInDays:kMaxPeriodicValidationInterval]);
}

- (void)activatePeriodicValidationWithTime:(NSDate *)currentTime {
  NSDate *lastReceiptValidation = self.validationStatusProvider.lastReceiptValidationDate;
  NSTimeInterval timeToNextValidation;
  if (lastReceiptValidation) {
    timeToNextValidation = self.periodicValidationInterval -
        [currentTime timeIntervalSinceDate:lastReceiptValidation];
  } else {
    timeToNextValidation = 0;
  }
  [self.periodicReceiptValidator activatePeriodicValidationCheck:
   [self timerSignal:@(timeToNextValidation)]];
}

- (RACSignal *)timerSignal:(NSNumber *)timeToNextValidation {
  RACSignal *timerSignal =
      [RACSignal interval:self.periodicValidationInterval onScheduler:[RACScheduler scheduler]];
  if ([timeToNextValidation doubleValue] <= 0) {
    return [timerSignal startWith:[NSDate date]];
  }

  return [[[RACSignal
      interval:[timeToNextValidation doubleValue] onScheduler:[RACScheduler scheduler]]
      take:1]
      concat:timerSignal];
}

#pragma mark -
#pragma mark Handling errors
#pragma mark -

- (RACSignal *)periodicValidationErrorsSignal {
  @weakify(self);
  return [[[[self.periodicReceiptValidator.errorsSignal
  flattenMap:^RACStream *(NSError *validationError) {
    @strongify(self);
    return [RACSignal zip:@[[RACSignal return:validationError], [self.timeProvider currentTime]]];
  }]
  reduceEach:(id)^NSError *(NSError *validationError, NSDate *currentTime) {
    @strongify(self);
    return [self sendPeriodicValidationError:validationError currentTime:currentTime];
  }]
  ignore:nil]
  catch:^RACSignal *(NSError *error) {
    return [RACSignal return:error];
  }];
}

- (nullable NSError *)sendPeriodicValidationError:(NSError *)validationError
                                      currentTime:(NSDate *)currentTime {
  NSDate *lastReceiptValidationDate = self.validationStatusProvider.lastReceiptValidationDate;
  if (!lastReceiptValidationDate) {
    /// This case can happen only if \c receiptValidationStatus is not \c nil but
    /// \c lastReceiptValidationDate is. This, in turn, is only possible if the
    /// \c receiptValidationStatus was saved to secure storage but there was an error saving
    /// \c lastReceiptValidationDate. In this case a storage error will be sent in
    /// \c validationStatusProvider, so we don't need to send another error.
    return nil;
  }
  NSTimeInterval secondsUntilInvalidation =
      [[self dateOfInvalidation:lastReceiptValidationDate] timeIntervalSinceDate:currentTime];

  if (secondsUntilInvalidation < 0) {
    [self.validationStatusProvider expireSubscription];
  }

  return [NSError bzr_errorWithSecondsUntilSubscriptionInvalidation:@(secondsUntilInvalidation)
                                          lastReceiptValidationDate:lastReceiptValidationDate
                                                    underlyingError:validationError];
}

- (NSDate *)dateOfInvalidation:(NSDate *)lastReceiptValidationDate {
  return [[lastReceiptValidationDate
          dateByAddingTimeInterval:self.periodicValidationInterval]
          dateByAddingTimeInterval:self.gracePeriod];
}

@end

NS_ASSUME_NONNULL_END

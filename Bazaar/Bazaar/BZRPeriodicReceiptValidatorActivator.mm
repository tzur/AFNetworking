// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPeriodicReceiptValidatorActivator.h"

#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZREvent.h"
#import "BZRExternalTriggerReceiptValidator.h"
#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTimeConversion.h"
#import "BZRTimeProvider.h"
#import "NSError+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRPeriodicReceiptValidatorActivator ()

/// Validator that is activated and deactivated depending on the receipt validation status.
@property (readonly, nonatomic) BZRExternalTriggerReceiptValidator *receiptValidator;

/// Provider used to provide the latest receipt validation status.
@property (readonly, nonatomic) BZRCachedReceiptValidationStatusProvider *validationStatusProvider;

/// Provider used to check if the receipt should be validated.
@property (readonly, nonatomic) id<BZRTimeProvider> timeProvider;

/// Number of seconds the receipt is allowed to remain not validated until the subscription becomes
/// expired.
@property (readonly, nonatomic) NSTimeInterval gracePeriod;

/// Sends time provider as values. The subject completes when the receiver is deallocated. The
/// subject doesn't err.
@property (readonly, nonatomic) RACSubject *timeProviderErrorsSubject;

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

- (instancetype)initWithValidationStatusProvider:
    (BZRCachedReceiptValidationStatusProvider *)validationStatusProvider
    timeProvider:(id<BZRTimeProvider>)timeProvider gracePeriod:(NSUInteger)gracePeriod {
  BZRExternalTriggerReceiptValidator *receiptValidator =
      [[BZRExternalTriggerReceiptValidator alloc]
       initWithValidationStatusProvider:validationStatusProvider];

  return [self initWithReceiptValidator:receiptValidator
               validationStatusProvider:validationStatusProvider timeProvider:timeProvider
                            gracePeriod:gracePeriod];
}

- (instancetype)initWithReceiptValidator:(BZRExternalTriggerReceiptValidator *)receiptValidator
    validationStatusProvider:(BZRCachedReceiptValidationStatusProvider *)validationStatusProvider
    timeProvider:(id<BZRTimeProvider>)timeProvider gracePeriod:(NSUInteger)gracePeriod {
  if (self = [super init]) {
    _validationStatusProvider = validationStatusProvider;
    _receiptValidator = receiptValidator;
    _timeProvider = timeProvider;
    _gracePeriod = [BZRTimeConversion numberOfSecondsInDays:gracePeriod];
    _timeProviderErrorsSubject = [RACSubject subject];

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
        if ([self shouldActivatePeriodicValidatorForValidationStatus:receiptValidationStatus]) {
          [self activatePeriodicValidationForSubscription:
           receiptValidationStatus.receipt.subscription];
        } else {
          [self.receiptValidator deactivate];
        }
      }];
}

- (BOOL)shouldActivatePeriodicValidatorForValidationStatus:
    (BZRReceiptValidationStatus *)receiptValidationStatus {
  BZRReceiptSubscriptionInfo *subscription = receiptValidationStatus.receipt.subscription;

  // If the user has no subscription there's no need to activate periodic validation.
  if (!subscription) {
    return NO;
  }

  // If the subscription is marked as expired because it was cancelled, no need to activate.
  // If the subscription is marked as expired and the last validation occurred after the
  // expiration date then the subscription is surely expired (and grace period is over), no
  // need to activate.
  if (subscription.isExpired && (subscription.cancellationDateTime ||
      [subscription.expirationDateTime compare:receiptValidationStatus.validationDateTime] ==
      NSOrderedAscending)) {
    return NO;
  }

  // Subcription is either not marked as expired or marked as expired because the last successful
  // validation occured too long ago. In these scenarios periodic validation is required.
  return YES;
}

- (void)activatePeriodicValidationForSubscription:(BZRReceiptSubscriptionInfo *)subscription {
  @weakify(self);
  [[self currentTime] subscribeNext:^(NSDate *currentTime) {
    @strongify(self);
    self.periodicValidationInterval = [self periodicValidationIntervalForSubscription:subscription];
    [self activatePeriodicValidationWithCurrentTime:currentTime];
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

- (void)activatePeriodicValidationWithCurrentTime:(NSDate *)currentTime {
  NSDate *lastReceiptValidation = self.validationStatusProvider.lastReceiptValidationDate;
  NSTimeInterval timeToNextValidation;
  if (lastReceiptValidation) {
    timeToNextValidation = self.periodicValidationInterval -
        [currentTime timeIntervalSinceDate:lastReceiptValidation];
  } else {
    timeToNextValidation = 0;
  }

  [self.receiptValidator activateWithTrigger:[self timerSignal:@(timeToNextValidation)]];
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

- (RACSignal *)errorEventsSignal {
    return [[RACSignal merge:@[
      [self.timeProviderErrorsSubject map:^BZREvent *(NSError *error) {
        return [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error];
      }],
      [self periodicValidationErrorsSignal]
    ]]
    takeUntil:[self rac_willDeallocSignal]];
}

- (RACSignal *)periodicValidationErrorsSignal {
  @weakify(self);
  return [[[[[self.receiptValidator.eventsSignal
      filter:^BOOL(BZREvent *event) {
        return event.eventError != nil;
      }]
      map:^NSError *(BZREvent *event) {
        return event.eventError;
      }]
      zipWith:[self currentTime]]
      reduceEach:(id)^BZREvent *(NSError *validationError, NSDate *currentTime) {
        @strongify(self);
        return [self periodicValidationError:validationError withTimeStamp:currentTime];
      }]
      ignore:nil];
}

- (RACSignal *)currentTime {
  @weakify(self);
  return [[[self.timeProvider currentTime]
      doError:^(NSError *error) {
        @strongify(self);
        [self.timeProviderErrorsSubject sendNext:error];
      }]
      catchTo:[RACSignal return:[NSDate date]]];
}

- (nullable BZREvent *)periodicValidationError:(NSError *)validationError
                                 withTimeStamp:(NSDate *)timeStamp {
  NSDate *lastReceiptValidationDate = self.validationStatusProvider.lastReceiptValidationDate;
  if (!lastReceiptValidationDate) {
    // This case can happen only if \c receiptValidationStatus is not \c nil but
    // \c lastReceiptValidationDate is. This, in turn, is only possible if the
    // \c receiptValidationStatus was saved to secure storage but there was an error saving
    // \c lastReceiptValidationDate. In this case a storage error will be sent in
    // \c validationStatusProvider, so we don't need to send another error.
    return nil;
  }
  NSTimeInterval secondsUntilInvalidation =
      [[self dateOfInvalidationForLastReceiptValidation:lastReceiptValidationDate]
       timeIntervalSinceDate:timeStamp];

  if (secondsUntilInvalidation < 0) {
    [self.validationStatusProvider expireSubscription];
  }

  NSError *error =
      [NSError bzr_errorWithSecondsUntilSubscriptionInvalidation:@(secondsUntilInvalidation)
                                       lastReceiptValidationDate:lastReceiptValidationDate
                                                 underlyingError:validationError];
  return [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error];
}

- (NSDate *)dateOfInvalidationForLastReceiptValidation:(NSDate *)lastReceiptValidationDate {
  NSDate *dateOfInvalidation =
      [lastReceiptValidationDate dateByAddingTimeInterval:self.periodicValidationInterval];
  return [self.validationStatusProvider.receiptValidationStatus.receipt.environment
          isEqual:$(BZRReceiptEnvironmentSandbox)] ? dateOfInvalidation :
      [dateOfInvalidation dateByAddingTimeInterval:self.gracePeriod];
}

@end

NS_ASSUME_NONNULL_END

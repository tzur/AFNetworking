// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPeriodicReceiptValidatorActivator.h"

#import <LTKit/NSDictionary+Functional.h>

#import "BZRAggregatedReceiptValidationStatusProvider.h"
#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZREvent.h"
#import "BZRExternalTriggerReceiptValidator.h"
#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
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

/// Set of applications bundle IDs.
@property (readonly, nonatomic) NSSet<NSString *> *bundledApplicationsIDs;

/// Provider used to provide and fetch the aggregated receipt validation status.
@property (readonly, nonatomic)
    BZRAggregatedReceiptValidationStatusProvider *aggregatedValidationStatusProvider;

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
    timeProvider:(id<BZRTimeProvider>)timeProvider
    bundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs
    aggregatedValidationStatusProvider:
    (BZRAggregatedReceiptValidationStatusProvider *)aggregatedValidationStatusProvider {
   BZRExternalTriggerReceiptValidator *receiptValidator =
       [[BZRExternalTriggerReceiptValidator alloc]
        initWithValidationStatusProvider:aggregatedValidationStatusProvider];

   return [self initWithReceiptValidator:receiptValidator
                validationStatusProvider:validationStatusProvider timeProvider:timeProvider
                  bundledApplicationsIDs:bundledApplicationsIDs
      aggregatedValidationStatusProvider:aggregatedValidationStatusProvider];
}

- (instancetype)initWithReceiptValidator:(BZRExternalTriggerReceiptValidator *)receiptValidator
    validationStatusProvider:(BZRCachedReceiptValidationStatusProvider *)validationStatusProvider
    timeProvider:(id<BZRTimeProvider>)timeProvider
    bundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs
    aggregatedValidationStatusProvider:
    (BZRAggregatedReceiptValidationStatusProvider *)aggregatedValidationStatusProvider {
  if (self = [super init]) {
    _validationStatusProvider = validationStatusProvider;
    _receiptValidator = receiptValidator;
    _timeProvider = timeProvider;
    _bundledApplicationsIDs = bundledApplicationsIDs;
    _aggregatedValidationStatusProvider = aggregatedValidationStatusProvider;

    [self activateTimerWhenSubscriptionExists];
  }
  return self;
}

#pragma mark -
#pragma mark Activating/deactivating timer
#pragma mark -

- (void)activateTimerWhenSubscriptionExists {
  @weakify(self);
  [RACObserve(self.aggregatedValidationStatusProvider, receiptValidationStatus)
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
  // expiration date then the subscription is surely expired, no need to activate.
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
  self.periodicValidationInterval = [self periodicValidationIntervalForSubscription:subscription];
  [self rac_liftSelector:@selector(activatePeriodicValidationWithCurrentTime:)
    withSignalsFromArray:@[[self.timeProvider currentTime]]];
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
  NSDate * _Nullable lastReceiptValidation = [self earliestLastReceiptValidationDate];
  NSTimeInterval timeToNextValidation;
  if (lastReceiptValidation) {
    timeToNextValidation = self.periodicValidationInterval -
        [currentTime timeIntervalSinceDate:lastReceiptValidation];
  } else {
    timeToNextValidation = 0;
  }

  [self.receiptValidator activateWithTrigger:[self timerSignal:@(timeToNextValidation)]];
}

- (nullable NSDate *)earliestLastReceiptValidationDate {
  auto lastValidationDates = [self lastReceiptValidationDatesForBundledApplications];
  return [lastValidationDates sortedArrayUsingDescriptors:@[
    [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES]
  ]].firstObject;
}

- (NSArray<NSDate *> *)lastReceiptValidationDatesForBundledApplications {
  return [[[[self.validationStatusProvider
      loadReceiptValidationStatusCacheEntries:self.bundledApplicationsIDs]
      lt_filter:^BOOL(NSString *, BZRReceiptValidationStatusCacheEntry *cacheEntry) {
        return [self shouldActivatePeriodicValidatorForValidationStatus:
                cacheEntry.receiptValidationStatus];
      }]
      lt_mapValues:^NSDate *(NSString *, BZRReceiptValidationStatusCacheEntry *cacheEntry) {
        return cacheEntry.cachingDateTime;
      }]
      allValues];
}

- (RACSignal<NSDate *> *)timerSignal:(NSNumber *)timeToNextValidation {
  RACSignal<NSDate *> *timerSignal =
      [RACSignal interval:self.periodicValidationInterval onScheduler:[RACScheduler scheduler]];
  if ([timeToNextValidation doubleValue] <= 0) {
    return [timerSignal startWith:[NSDate date]];
  }

  return [[[RACSignal
      interval:[timeToNextValidation doubleValue] onScheduler:[RACScheduler scheduler]]
      take:1]
      concat:timerSignal];
}

@end

NS_ASSUME_NONNULL_END

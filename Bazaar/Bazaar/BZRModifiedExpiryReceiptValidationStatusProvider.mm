// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRModifiedExpiryReceiptValidationStatusProvider.h"

#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTimeConversion.h"
#import "BZRTimeProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRModifiedExpiryReceiptValidationStatusProvider ()

/// Provider used to check if the expired subscription grace period is over.
@property (readonly, nonatomic) id<BZRTimeProvider> timeProvider;

/// Specifies the number of days the user is allowed to use products that he acquired via
/// subscription after its subscription has been expired.
@property (readonly, nonatomic) NSTimeInterval expiredSubscriptionGracePeriodSeconds;

/// Provider used to fetch the receipt validation status.
@property (readonly, nonatomic) id<BZRReceiptValidationStatusProvider> underlyingProvider;

/// Sends time provider as values. The subject completes when the receiver is deallocated. The
/// subject doesn't err.
@property (readonly, nonatomic) RACSubject *timeProviderErrorsSubject;

@end

@implementation BZRModifiedExpiryReceiptValidationStatusProvider

@synthesize nonCriticalErrorsSignal = _nonCriticalErrorsSignal;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithTimeProvider:(id<BZRTimeProvider>)timeProvider
    expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod
    underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider {
  if (self = [super init]) {
    _timeProvider = timeProvider;
    _expiredSubscriptionGracePeriodSeconds =
        [BZRTimeConversion numberOfSecondsInDays:expiredSubscriptionGracePeriod];
    _underlyingProvider = underlyingProvider;
    _timeProviderErrorsSubject = [RACSubject subject];
    _nonCriticalErrorsSignal = [[RACSignal merge:@[
      self.timeProviderErrorsSubject,
      self.underlyingProvider.nonCriticalErrorsSignal
    ]]
    takeUntil:[self rac_willDeallocSignal]];
  }
  return self;
}

- (RACSignal *)fetchReceiptValidationStatus {
  @weakify(self);
  return [[[self.underlyingProvider fetchReceiptValidationStatus]
      flattenMap:^RACSignal *(BZRReceiptValidationStatus *receiptValidationStatus) {
        @strongify(self);
        return [[[[self.timeProvider currentTime]
            map:^BZRReceiptValidationStatus *(NSDate *currentTime) {
              return [self extendedValidationStatusWithGracePeriod:receiptValidationStatus
                                                       currentTime:currentTime];
            }]
            doError:^(NSError *error) {
              [self.timeProviderErrorsSubject sendNext:error];
            }]
            catchTo:[RACSignal return:receiptValidationStatus]];
      }]
      setNameWithFormat:@"%@ -fetchReceiptValidationStatus", self.description];
}

- (BZRReceiptValidationStatus *)extendedValidationStatusWithGracePeriod:
    (BZRReceiptValidationStatus *)receiptValidationStatus
    currentTime:(NSDate *)currentTime {
  if (!receiptValidationStatus.receipt.subscription) {
    return receiptValidationStatus;
  }

  BZRReceiptSubscriptionInfo *subscription = receiptValidationStatus.receipt.subscription;
  NSDate *expirationTimePlusGracePeriod =
      [subscription.expirationDateTime
       dateByAddingTimeInterval:self.expiredSubscriptionGracePeriodSeconds];
  BOOL isExpired = [expirationTimePlusGracePeriod compare:currentTime] == NSOrderedAscending;
  subscription =
      [subscription modelByOverridingProperty:@keypath(subscription, isExpired)
                                    withValue:@(isExpired)];
  BZRReceiptInfo *receipt =
      [receiptValidationStatus.receipt modelByOverridingProperty:@keypath(receipt, subscription)
                                                       withValue:subscription];
  return [receiptValidationStatus
          modelByOverridingProperty:@keypath(receiptValidationStatus, receipt) withValue:receipt];
}

@end

NS_ASSUME_NONNULL_END

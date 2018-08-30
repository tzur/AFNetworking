// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationDateProvider.h"

#import "BZRAggregatedReceiptValidationStatusProvider.h"
#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTimeConversion.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRReceiptValidationDateProvider ()

/// Provider used to provide the aggregated receipt validation status.
@property (readonly, nonatomic) BZRAggregatedReceiptValidationStatusProvider *
    receiptValidationStatusProvider;

/// Seconds until the cache is invalidated, starting from the date it was cached.
@property (readonly, nonatomic) NSTimeInterval validationInterval;

/// Redeclared as readwrite.
@property (strong, readwrite, nonatomic) NSDate *nextValidationDate;

@end

@implementation BZRReceiptValidationDateProvider

@synthesize nextValidationDate = _nextValidationDate;

- (instancetype)initWithReceiptValidationStatusProvider:
    (BZRAggregatedReceiptValidationStatusProvider *)receiptValidationStatusProvider
    validationIntervalDays:(NSUInteger)validationIntervalDays {
  if (self = [super init]) {
    _receiptValidationStatusProvider = receiptValidationStatusProvider;
    _validationInterval = [BZRTimeConversion numberOfSecondsInDays:validationIntervalDays];

    [self setupNextValidationDateUpdates];
  }
  return self;
}

- (void)setupNextValidationDateUpdates {
  @weakify(self);
  RAC(self, nextValidationDate) =
      [RACObserve(self.receiptValidationStatusProvider, receiptValidationStatus)
       map:^NSDate * _Nullable(BZRReceiptValidationStatus * _Nullable receiptValidationStatus) {
         @strongify(self);
         if (![self shouldValidateReceiptForValidationStatus:receiptValidationStatus]) {
           return nil;
         }

         return [receiptValidationStatus.validationDateTime
                 dateByAddingTimeInterval:self.intervalBetweenValidations];
      }];
}

- (BOOL)shouldValidateReceiptForValidationStatus:
    (nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  auto _Nullable subscription = receiptValidationStatus.receipt.subscription;

  // If the user has no subscription there's no need to validate.
  if (!subscription) {
    return NO;
  }

  // If the subscription is marked as expired because it was cancelled, no need to validate.
  // If the subscription is marked as expired and the last validation occurred after the
  // expiration date then the subscription is surely expired, no need to validate.
  auto receiptWasValidatedAfterSubscriptionExpiration =
      [subscription.expirationDateTime compare:receiptValidationStatus.validationDateTime] ==
      NSOrderedAscending;
  if (subscription.isExpired &&
      (subscription.cancellationDateTime || receiptWasValidatedAfterSubscriptionExpiration)) {
    return NO;
  }

  // Subscription is either not marked as expired or marked as expired because the last successful
  // validation occurred too long ago. In these scenarios periodic validation is required.
  return YES;
}

- (NSTimeInterval)intervalBetweenValidations {
  static const NSTimeInterval kIntervalBetweenValidationsInSandbox = 150.0;

  if ([self.receiptValidationStatusProvider.receiptValidationStatus.receipt.environment
      isEqual:$(BZRReceiptEnvironmentSandbox)]) {
    return kIntervalBetweenValidationsInSandbox;
  }

  return self.validationInterval;
}

@end

NS_ASSUME_NONNULL_END

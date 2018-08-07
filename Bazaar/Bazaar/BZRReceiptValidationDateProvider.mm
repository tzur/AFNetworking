// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationDateProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRAggregatedReceiptValidationStatusProvider.h"
#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRTimeConversion.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRReceiptValidationDateProvider ()

/// Cache used to load receipt validation status cache entry from storage.
@property (readonly, nonatomic) BZRReceiptValidationStatusCache *receiptValidationStatusCache;

/// Provider used to provide the aggregated receipt validation status.
@property (readonly, nonatomic) BZRAggregatedReceiptValidationStatusProvider *
    receiptValidationStatusProvider;

/// Set of applications bundle IDs.
@property (readonly, nonatomic) NSSet<NSString *> *bundledApplicationsIDs;

/// Seconds until the cache is invalidated, starting from the date it was cached.
@property (readonly, nonatomic) NSTimeInterval validationInterval;

/// Redeclared as readwrite.
@property (strong, readwrite, nonatomic) NSDate *nextValidationDate;

@end

@implementation BZRReceiptValidationDateProvider

@synthesize nextValidationDate = _nextValidationDate;

- (instancetype)initWithReceiptValidationStatusCache:
    (BZRReceiptValidationStatusCache *)receiptValidationStatusCache
    receiptValidationStatusProvider:(BZRAggregatedReceiptValidationStatusProvider *)
    receiptValidationStatusProvider
    bundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs
    validationIntervalDays:(NSUInteger)validationIntervalDays {
  if (self = [super init]) {
    _receiptValidationStatusCache = receiptValidationStatusCache;
    _receiptValidationStatusProvider = receiptValidationStatusProvider;
    _bundledApplicationsIDs = bundledApplicationsIDs;
    _validationInterval = [BZRTimeConversion numberOfSecondsInDays:validationIntervalDays];

    [self setupNextValidationDateUpdates];
  }
  return self;
}

- (void)setupNextValidationDateUpdates {
  @weakify(self);
  RAC(self, nextValidationDate) =
      [RACObserve(self.receiptValidationStatusProvider, receiptValidationStatus)
       map:^NSDate * _Nullable(BZRReceiptValidationStatus *receiptValidationStatus) {
         @strongify(self);
         if (![self shouldValidateReceiptForValidationStatus:receiptValidationStatus]) {
           return nil;
         }

         auto _Nullable lastReceiptValidation = [self earliestReceiptValidationDate];
         return [lastReceiptValidation dateByAddingTimeInterval:self.intervalBetweenValidations];
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

- (nullable NSDate *)earliestReceiptValidationDate {
  auto lastValidationDates = [self lastReceiptValidationDatesForBundledApplications];
  return [lastValidationDates valueForKeyPath:@"@min.self"];
}

- (NSArray<NSDate *> *)lastReceiptValidationDatesForBundledApplications {
  return [[[self.receiptValidationStatusCache
      loadReceiptValidationStatusCacheEntries:self.bundledApplicationsIDs]
      allValues]
      lt_map:^NSDate *(BZRReceiptValidationStatusCacheEntry *cacheEntry) {
        return cacheEntry.cachingDateTime;
      }];
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

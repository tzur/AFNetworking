// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRMultiAppReceiptValidationStatusProvider.h"

#import <LTKit/NSDictionary+Functional.h>

#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRMultiAppReceiptValidationStatusAggregator.h"
#import "BZRMultiAppSubscriptionClassifier.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRMultiAppReceiptValidationStatusProvider ()

/// Object used to fetch and get the latest receipt validation status of multiple applications.
@property (readonly, nonatomic) BZRCachedReceiptValidationStatusProvider *underlyingProvider;

/// Aggregator used to compute an aggregated receipt validation status from a set of receipt
/// validation statuses.
@property (readonly, nonatomic) BZRMultiAppReceiptValidationStatusAggregator *aggregator;

/// Set of applications identifiers for which validation will be performed.
@property (readonly, nonatomic) NSSet<NSString *> *bundleIDsForValidation;

/// The most recent receipt validation status.
@property (readwrite, atomic, nullable) BZRReceiptValidationStatus
    *aggregatedReceiptValidationStatus;

/// Redeclare as readwrite.
@property (readwrite, atomic, nullable) NSDictionary<NSString *, BZRReceiptValidationStatus *>
    *multiAppReceiptValidationStatus;
@end

@implementation BZRMultiAppReceiptValidationStatusProvider

@synthesize eventsSignal = _eventsSignal;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithUnderlyingProvider:
    (BZRCachedReceiptValidationStatusProvider *)underlyingProvider
    currentApplicationBundleID:(NSString *)currentApplicationBundleID
    bundleIDsForValidation:(NSSet<NSString *> *)bundleIDsForValidation
    multiAppSubscriptionClassifier:
    (nullable id<BZRMultiAppSubscriptionClassifier>)multiAppSubscriptionClassifier {
  auto aggregator = [[BZRMultiAppReceiptValidationStatusAggregator alloc]
                     initWithCurrentApplicationBundleID:currentApplicationBundleID
                     multiAppSubscriptionClassifier:multiAppSubscriptionClassifier];
  return [self initWithUnderlyingProvider:underlyingProvider aggregator:aggregator
                   bundleIDsForValidation:bundleIDsForValidation];
}

- (instancetype)initWithUnderlyingProvider:
    (BZRCachedReceiptValidationStatusProvider *)underlyingProvider
    aggregator:(BZRMultiAppReceiptValidationStatusAggregator *)aggregator
    bundleIDsForValidation:(NSSet<NSString *> *)bundleIDsForValidation {
  if (self = [super init]) {
    _underlyingProvider = underlyingProvider;
    _aggregator = aggregator;
    _bundleIDsForValidation = [bundleIDsForValidation copy];
    _eventsSignal = [self.underlyingProvider.eventsSignal takeUntil:[self rac_willDeallocSignal]];

    [self loadReceiptValidationStatusesFromStorage];
  }

  return self;
}

- (void)loadReceiptValidationStatusesFromStorage {
  _multiAppReceiptValidationStatus =
      [[self.underlyingProvider.cache
          loadReceiptValidationStatusCacheEntries:self.bundleIDsForValidation]
          lt_mapValues:^(NSString *, BZRReceiptValidationStatusCacheEntry *cacheEntry) {
            return cacheEntry.receiptValidationStatus;
          }];

  _aggregatedReceiptValidationStatus =
      [self.aggregator
       aggregateMultiAppReceiptValidationStatuses:self.multiAppReceiptValidationStatus];
}

#pragma mark -
#pragma mark Fetching aggregated receipt validation status
#pragma mark -

- (RACSignal<BZRReceiptValidationStatus *> *)fetchReceiptValidationStatus {
  @weakify(self);
  return [[[[self.underlyingProvider fetchReceiptValidationStatuses:self.bundleIDsForValidation]
      doNext:^(BZRMultiAppReceiptValidationStatus *bundleIDToReceiptValidationStatus) {
        @strongify(self);
        self.multiAppReceiptValidationStatus = bundleIDToReceiptValidationStatus;
      }]
      tryMap:^BZRReceiptValidationStatus *
          (BZRMultiAppReceiptValidationStatus *bundleIDToReceiptValidationStatus,
           NSError * __autoreleasing *error) {
        @strongify(self);
        return [self aggregateMultiAppReceiptValidationStatus:bundleIDToReceiptValidationStatus
                                                        error:error];
      }]
      doNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
        @strongify(self);
        self.aggregatedReceiptValidationStatus = receiptValidationStatus;
      }];
}

- (nullable BZRReceiptValidationStatus *)aggregateMultiAppReceiptValidationStatus:
    (BZRMultiAppReceiptValidationStatus *)bundleIDToReceiptValidationStatus
    error:(NSError * __autoreleasing *)error {
  auto _Nullable aggregatedReceiptValidationStatus = [self.aggregator
      aggregateMultiAppReceiptValidationStatuses:bundleIDToReceiptValidationStatus];
  if (!aggregatedReceiptValidationStatus) {
    if (error) {
      *error = [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed
                             description:@"No receipt validation status that is relevant "
                "for the current application was found"];
    }
  }

  return aggregatedReceiptValidationStatus;
}

@end

NS_ASSUME_NONNULL_END

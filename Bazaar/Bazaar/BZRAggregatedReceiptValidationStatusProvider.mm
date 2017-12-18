// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRAggregatedReceiptValidationStatusProvider.h"

#import <LTKit/NSDictionary+Functional.h>

#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRMultiAppConfiguration.h"
#import "BZRMultiAppReceiptValidationStatusAggregator.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRAggregatedReceiptValidationStatusProvider ()

/// Object used to fetch and get the latest receipt validation status of multiple applications.
@property (readonly, nonatomic) BZRCachedReceiptValidationStatusProvider *underlyingProvider;

/// Aggregator used to compute an aggregated receipt validation status from a set of receipt
/// validation statuses.
@property (readonly, nonatomic) BZRMultiAppReceiptValidationStatusAggregator *aggregator;

/// Set of applications identifiers for which validation will be performed.
@property (readonly, nonatomic) NSSet<NSString *> *bundledApplicationsIDs;

/// The most recent receipt validation status.
@property (readwrite, atomic, nullable) BZRReceiptValidationStatus *receiptValidationStatus;

@end

@implementation BZRAggregatedReceiptValidationStatusProvider

@synthesize eventsSignal = _eventsSignal;
@synthesize receiptValidationStatus = _receiptValidationStatus;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithUnderlyingProvider:
    (BZRCachedReceiptValidationStatusProvider *)underlyingProvider
    currentApplicationBundleID:(NSString *)currentApplicationBundleID
    multiAppConfiguration:(nullable BZRMultiAppConfiguration *)multiAppConfiguration {
  auto aggregator = [[BZRMultiAppReceiptValidationStatusAggregator alloc]
                     initWithCurrentApplicationBundleID:currentApplicationBundleID
                     multiAppSubscriptionIdentifierMarker:
                     multiAppConfiguration.multiAppSubscriptionIdentifierMarker];

  auto bundleIDsForValidation = multiAppConfiguration.bundledApplicationsIDs ?:
      @[currentApplicationBundleID].lt_set;
  return [self initWithUnderlyingProvider:underlyingProvider aggregator:aggregator
                   bundledApplicationsIDs:bundleIDsForValidation];
}

- (instancetype)initWithUnderlyingProvider:
    (BZRCachedReceiptValidationStatusProvider *)underlyingProvider
    aggregator:(BZRMultiAppReceiptValidationStatusAggregator *)aggregator
    bundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs {
  if (self = [super init]) {
    _underlyingProvider = underlyingProvider;
    _aggregator = aggregator;
    _bundledApplicationsIDs = [bundledApplicationsIDs copy];
    _eventsSignal = [self.underlyingProvider.eventsSignal takeUntil:[self rac_willDeallocSignal]];

    [self loadAggregatedReceiptValidationStatusFromStorage];
  }

  return self;
}

- (void)loadAggregatedReceiptValidationStatusFromStorage {
  BZRMultiAppReceiptValidationStatus *bundleIDToReceiptValidationStatus =
      [[self.underlyingProvider loadReceiptValidationStatusCacheEntries:self.bundledApplicationsIDs]
      lt_mapValues:^BZRReceiptValidationStatus *
          (NSString *, BZRReceiptValidationStatusCacheEntry *cacheEntry) {
        return cacheEntry.receiptValidationStatus;
      }];

  _receiptValidationStatus = [self.aggregator
      aggregateMultiAppReceiptValidationStatuses:bundleIDToReceiptValidationStatus];
}

#pragma mark -
#pragma mark Fetching aggregated receipt validation status
#pragma mark -

- (RACSignal<BZRReceiptValidationStatus *> *)fetchReceiptValidationStatus {
  @weakify(self);
  return [[[self.underlyingProvider fetchReceiptValidationStatuses:self.bundledApplicationsIDs]
      tryMap:^BZRReceiptValidationStatus *
          (BZRMultiAppReceiptValidationStatus *bundleIDToReceiptValidationStatus,
           NSError * __autoreleasing *error) {
        @strongify(self);
        return [self aggregateMultiAppReceiptValidationStatus:bundleIDToReceiptValidationStatus
                                                        error:error];
      }]
      doNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
        @strongify(self);
        self.receiptValidationStatus = receiptValidationStatus;
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

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRCachedReceiptValidationStatusProvider, BZRMultiAppConfiguration,
    BZRMultiAppReceiptValidationStatusAggregator, BZRReceiptValidationStatus;

/// Provides an aggregated receipt validation status from receipt validation statuses of multiple
/// applications. The aggregation occurs at two points: after performing receipt validation of
/// multiple applications, and when loading receipt validation status of multiple applications from
/// cache.
///
/// @see \c BZRMultiAppReceiptValidationStatusAggregator for more information about how the receipt
/// validation statuses are aggregated.
@interface BZRAggregatedReceiptValidationStatusProvider : NSObject <BZREventEmitter>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c underlyingProvider. \c bundledApplicationsIDs is taken from
/// \c multiAppConfiguration. \c aggregator is set to a newly created
/// \c BZRMultiAppReceiptValidationStatusAggregator from the given
/// \c currentApplicationBundleID, and
/// \c multiAppConfiguration.multiAppSubscriptionIdentifierMarker. If \c multiAppConfiguration is
/// \c nil, the receiver will perform validation only for the currently running application.
- (instancetype)initWithUnderlyingProvider:
    (BZRCachedReceiptValidationStatusProvider *)underlyingProvider
    currentApplicationBundleID:(NSString *)currentApplicationBundleID
    multiAppConfiguration:(nullable BZRMultiAppConfiguration *)multiAppConfiguration;

/// Initializes with \c provider, used to fetch receipt validation status of multiple applications
/// and to get the latest receipt validation statuses from cache. \c aggregator is used to aggregate
/// the fetchied receipt validation statuses. \c bundledApplicationsIDs is the set of applications
/// identifiers for which validation will be performed.
- (instancetype)initWithUnderlyingProvider:
    (BZRCachedReceiptValidationStatusProvider *)underlyingProvider
    aggregator:(BZRMultiAppReceiptValidationStatusAggregator *)aggregator
    bundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs NS_DESIGNATED_INITIALIZER;

/// Fetches receipt validation statuses of multiple applications and sends an aggregated receipt
/// validation status. The signal completes after sending the value. The signal errs if there the
/// provider erred, or if no relevant receipt validation status was found.
- (RACSignal<BZRReceiptValidationStatus *> *)fetchReceiptValidationStatus;

/// Holds the most recent aggregated receipt validation status. Before fetching has completed
/// successfully for the first time this property holds the value loaded from cache. If no value
/// exists in the cache or there was an error while loading from cache, this property will be
/// \c nil. KVO compliant. Changes may be delivered on an arbitrary thread.
@property (readonly, atomic, nullable) BZRReceiptValidationStatus *receiptValidationStatus;

@end

NS_ASSUME_NONNULL_END

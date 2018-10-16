// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRCachedReceiptValidationStatusProvider, BZRMultiAppReceiptValidationStatusAggregator,
    BZRReceiptValidationStatus;

@protocol BZRMultiAppSubscriptionClassifier;

/// Provides the receipt validation statuses of multiple applications and an aggregated receipt
/// validation status extracted from them.
/// The aggregation occurs at two points: after performing receipt validation of
/// multiple applications, and when loading receipt validation status of multiple applications from
/// cache.
///
/// @see \c BZRMultiAppReceiptValidationStatusAggregator for more information about how the receipt
/// validation statuses are aggregated.
@interface BZRMultiAppReceiptValidationStatusProvider : NSObject <BZREventEmitter>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c underlyingProvider. \c bundleIDsForValidation is the set of
/// applications bundle identifiers for which validation will be performed. \c aggregator is set to
/// a newly created \c BZRMultiAppReceiptValidationStatusAggregator with the given
/// \c currentApplicationBundleID, and \c multiAppSubscriptionClassifier.
- (instancetype)initWithUnderlyingProvider:
    (BZRCachedReceiptValidationStatusProvider *)underlyingProvider
    currentApplicationBundleID:(NSString *)currentApplicationBundleID
    bundleIDsForValidation:(NSSet<NSString *> *)bundleIDsForValidation
    multiAppSubscriptionClassifier:
    (nullable id<BZRMultiAppSubscriptionClassifier>)multiAppSubscriptionClassifier;

/// Initializes with \c provider, used to fetch receipt validation status of multiple applications
/// and to get the latest receipt validation statuses from cache. \c aggregator is used to aggregate
/// the fetchied receipt validation statuses. \c bundleIDsForValidation is the set of applications
/// bundle identifiers for which validation will be performed.
- (instancetype)initWithUnderlyingProvider:
    (BZRCachedReceiptValidationStatusProvider *)underlyingProvider
    aggregator:(BZRMultiAppReceiptValidationStatusAggregator *)aggregator
    bundleIDsForValidation:(NSSet<NSString *> *)bundleIDsForValidation NS_DESIGNATED_INITIALIZER;

/// Fetches receipt validation statuses of multiple applications and sends an aggregated receipt
/// validation status. The signal completes after sending the value. The signal errs if there the
/// provider erred, or if no relevant receipt validation status was found.
- (RACSignal<BZRReceiptValidationStatus *> *)fetchReceiptValidationStatus;

/// Holds the most recent aggregated receipt validation status. Before fetching has completed
/// successfully for the first time this property holds the value loaded from cache. If no value
/// exists in the cache or there was an error while loading from cache, this property will be
/// \c nil. KVO compliant. Changes may be delivered on an arbitrary thread.
@property (readonly, atomic, nullable) BZRReceiptValidationStatus
    *aggregatedReceiptValidationStatus;

/// Holds the most recent dictionary mapping application bundle ID to receipt validation status.
/// Before fetching has completed successfully for the first time this property holds the
/// values loaded from cache. If no value exists in the cache or there was an error while
/// loading from cache, this property will be \c nil. KVO compliant. Changes may be delivered
/// on an arbitrary thread.
@property (readonly, atomic, nullable) NSDictionary<NSString *, BZRReceiptValidationStatus *>
    *multiAppReceiptValidationStatus;

@end

NS_ASSUME_NONNULL_END

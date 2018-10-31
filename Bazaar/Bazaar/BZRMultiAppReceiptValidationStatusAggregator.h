// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptValidationStatus;

@protocol BZRMultiAppSubscriptionClassifier;

/// Aggregates a set of receipt validation statuses of multiple applications into one receipt
/// validation status.
///
/// Definitions:
/// Active subscription - Subscription that's not expired and not cancelled.
/// Relevant subscription - Subscription which can unlock content for the current application,
/// i.e. subscription of the current application or a multi-app subscription that was purchased in a
/// different application and grants access to features in the current application.
/// Effective expiration date - The minimum between the expiration date and the cancellation date of
/// a subscription. If the cancellation date doesn't exist, it is the expiration date of the
/// subscription.
/// Most fit subscription - If an active relevant subscription exists, it is the subsription with
/// the farthest effective expiration date amongst them. If no active subscription exists, it is the
/// subsription with the farthest effective expiration date amongst them.
///
/// The aggregated receipt validation status is built according to the following rules:
/// - Only receipt validation statuses with relevant subscriptions are examined.
/// - The receipt validation status of the current application is added the most fit subscription.
/// - If the receipt validation status of the current applicaiton doesn't exist, a fictive receipt
/// validation status is created with the most fit subscription and the validation date time from
/// the receipt validation status of the most fit subscription.
@interface BZRMultiAppReceiptValidationStatusAggregator : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c currentApplicationBundleID, the bundle identifier of the current
/// application. \c multiAppSubscriptionClassifier is used to determine whether a subscription
/// of another application is a relevant multi-app subscription. \c nil signifies that other
/// applications' receipt validation statuses should be ignored.
- (instancetype)initWithCurrentApplicationBundleID:(NSString *)currentApplicationBundleID
    multiAppSubscriptionClassifier:(nullable id<BZRMultiAppSubscriptionClassifier>)
    multiAppSubscriptionClassifier;

/// Returns the aggregated receipt validation status from the given
/// \c bundleIDToReceiptValidationStatus. \c nil if no relevant subscription amongst
/// \c bundleIDToReceiptValidationStatus was found or if \c bundleIDToReceiptValidationStatus is
/// \c nil.
- (nullable BZRReceiptValidationStatus *)aggregateMultiAppReceiptValidationStatuses:
    (nullable BZRMultiAppReceiptValidationStatus *)bundleIDToReceiptValidationStatus;

@end

NS_ASSUME_NONNULL_END

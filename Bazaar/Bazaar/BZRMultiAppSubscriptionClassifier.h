// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for objects used to determine whether specific subscription products are multi-app
/// subscriptions or not.
@protocol BZRMultiAppSubscriptionClassifier <NSObject>

/// Returns \c YES if the product with the given \c productIdentifier is a multi-app subscription.
- (BOOL)isMultiAppSubscription:(NSString *)productIdentifier;

@end

/// Default implementation of the \c BZRMultiAppSubscriptionInfoProvider protocol. This
/// implementation assumes product identifiers are formatted as follow:
/// "<Application Bundle ID>_<Subscription Group Name>_<Product Name>[_<Introudctory Discount>]",
/// where <Product Name> is a "." separated string marking different attributes of the subscription
/// product such as its billing period and service level. The service level marker is what used by
/// this provider in order to identify multi-app subscription.
///
/// @note The markers in the product identifier are merely a convention not mandatory. They should
/// reflect the parameters that are configured on iTunes Connect for the product but there is no way
/// to enforce that.
@interface BZRMultiAppSubscriptionClassifier : NSObject <BZRMultiAppSubscriptionClassifier>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c multiAppServiceLevelMarker used to determine whether a
/// subscription product is a multi-app subscription.
- (instancetype)initWithMultiAppServiceLevelMarker:(NSString *)multiAppServiceLevelMarker
    NS_DESIGNATED_INITIALIZER;

/// Returns \c YES if one of the attributes of the <Product Name> section of the identifier equals
/// to the \c multiAppServiceLevelMarker. If the product identifier is not of the expected format
/// \c NO is returned.
- (BOOL)isMultiAppSubscription:(NSString *)productIdentifier;

@end

NS_ASSUME_NONNULL_END

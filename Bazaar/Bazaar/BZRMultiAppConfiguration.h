// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Object that represents multi-app configuration for Bazaar.
@interface BZRMultiAppConfiguration : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c bundledApplicationsIDs, the set of applications identifiers that can unlock
/// content for the current application, and with \c multiAppSubscriptionIdentifierMarker, used to
/// determine whether a subscription should be considered a multi-app subscription.
- (instancetype)initWithBundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs
    multiAppSubscriptionIdentifierMarker:(NSString *)multiAppSubscriptionIdentifierMarker
    NS_DESIGNATED_INITIALIZER;

/// Set of applications identifiers which can unlock content for the current application.
@property (readonly, nonatomic) NSSet<NSString *> *bundledApplicationsIDs;

/// Substring of subscription identifier, by which Bazaar determines whether a subscription should
/// be considered a multi-app subscription.
@property (readonly, nonatomic) NSString *multiAppSubscriptionIdentifierMarker;

@end

NS_ASSUME_NONNULL_END

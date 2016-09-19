// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRAcquiredViaSubscriptionProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake provider that provides a set of products acquired via subscription manually injected to
/// its \c productsAcquiredViaSubscription property.
@interface BZRFakeAcquiredViaSubscriptionProvider : BZRAcquiredViaSubscriptionProvider

/// Initializes with \c keychainStorage set to \c OCMClassMock([BZRKeychainStorage class]).
- (instancetype)init;

/// Set of products acquired via subscription.
@property (strong, readwrite, nonatomic) NSSet<NSString *> *productsAcquiredViaSubscription;

@end

NS_ASSUME_NONNULL_END

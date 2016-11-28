// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorage;

/// Provider that provides a set of products that were acquired via subscription. This class is
/// thread safe.
@interface BZRAcquiredViaSubscriptionProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c keychainStorage, used to persist the set of products that were acquired via
/// subscription.
- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage
    NS_DESIGNATED_INITIALIZER;

/// Adds a product identifier to the set of products that were acquired via subscription and saves
/// the set to storage.
- (void)addAcquiredViaSubscriptionProduct:(NSString *)productIdentifier;

/// Removes a product identifier from the set of products that were acquired via subscription and
/// saves the set to storage.
- (void)removeAcquiredViaSubscriptionProduct:(NSString *)productIdentifier;

/// Set of products that were acquired via subscription. KVO compliant. Changes may be delivered on
/// an arbitrary thread.
@property (readonly, nonatomic) NSSet<NSString *> *productsAcquiredViaSubscription;

/// Sends storage errors as values. The signal completes when the receiver is deallocated. The
/// signal doesn't err.
///
/// @return <tt>RACSignal<NSError></tt>
@property (readonly, nonatomic) RACSignal *storageErrorsSignal;

@end

NS_ASSUME_NONNULL_END

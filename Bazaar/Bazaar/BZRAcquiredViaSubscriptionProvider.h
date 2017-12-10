// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZREvent, BZRKeychainStorage, BZRKeychainStorageMigrator;

/// Provider that provides a set of products that were acquired via subscription. This class is
/// thread safe.
@interface BZRAcquiredViaSubscriptionProvider : NSObject

/// Copies the set of products that were acquired via subscription from source storage to target
/// storage that specefied in \c migrator. Returns \c YES in a case of successful migration or if
/// the target storage is already holding the products set, otherwise returns \c NO and \c error is
/// set with an appropriate error.
+ (BOOL)migrateProductsAcquiredViaSubscriptionWithMigrator:(BZRKeychainStorageMigrator *)migrator
                                                     error:(NSError **)error;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c keychainStorage, used to persist the set of products that were acquired via
/// subscription.
- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage
    NS_DESIGNATED_INITIALIZER;

/// Adds a product identifier to the set of products that were acquired via subscription and saves
/// the set to storage.
- (void)addAcquiredViaSubscriptionProduct:(NSString *)productIdentifier;

/// Adds multiple product identifiers to the set of products that were acquired via subscription
/// and saves the set to storage.
- (void)addAcquiredViaSubscriptionProducts:(NSSet<NSString *> *)productIdentifiers;

/// Removes a product identifier from the set of products that were acquired via subscription and
/// saves the set to storage.
- (void)removeAcquiredViaSubscriptionProduct:(NSString *)productIdentifier;

/// Loads the set of products that were acquired via subscription set from storage and saves it in
/// \c productsAcquiredViaSubscription. If an error occurred while loading from cache,
/// \c productsAcquiredViaSubscription is not modified, \c error is populated with error information
/// and \c nil is returned.
/// Returns the loaded \c productsAcquiredViaSubscription, or \c nil in case of an error.
- (nullable NSSet<NSString *> *)refreshProductsAcquiredViaSubscription:(NSError **)error;

/// Set of products that were acquired via subscription. KVO compliant. Changes may be delivered on
/// an arbitrary thread.
@property (readonly, nonatomic) NSSet<NSString *> *productsAcquiredViaSubscription;

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorageRoute, BZRReceiptValidationStatus, BZRKeychainStorageMigrator,
    BZRReceiptValidationStatusCache;

@protocol BZRTimeProvider;

/// Value class representing an entry of the \c BZRReceiptValidationStatusCache. Holds the receipt
/// validation status and the caching date.
@interface BZRReceiptValidationStatusCacheEntry : BZRModel

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with \c validationStatus and \c cachingDateTime.
- (instancetype)initWithReceiptValidationStatus:(BZRReceiptValidationStatus *)validationStatus
                                cachingDateTime:(NSDate *)cachingDateTime
    NS_DESIGNATED_INITIALIZER;

/// Holds the recent receipt validation status.
@property (readonly, nonatomic) BZRReceiptValidationStatus *receiptValidationStatus;

/// Holds the date of the receipt caching time.
@property (readonly, nonatomic) NSDate *cachingDateTime;

@end

/// Cache for \c BZRReceiptValidationStatus using keychain storage.
@interface BZRReceiptValidationStatusCache : NSObject

/// Copies the receipt validation status from source storage to target storage that specified in
/// \c migrator. Returns \c YES in a case of successful migration or if the target storage is
/// already holding receipt validation status, otherwise returns \c NO and \c error is set with an
/// appropriate error.
+ (BOOL)migrateReceiptValidationStatusWithMigrator:(BZRKeychainStorageMigrator *)migrator
                                             error:(NSError **)error;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c keychainStorageRoute, used to store and retrieve receipt validation status
/// of multiple applications.
- (instancetype)initWithKeychainStorage:(BZRKeychainStorageRoute *)keychainStorageRoute
    NS_DESIGNATED_INITIALIZER;

/// Stores the receipt validation status to the storage of the application specified by
/// \c applicationBundleID and returns \c YES on success. If an error occurred while writing to the
/// cache \c error is populated with error information and \c NO is returned.
- (BOOL)storeCacheEntry:(nullable BZRReceiptValidationStatusCacheEntry *)cacheEntry
    applicationBundleID:(NSString *)applicationBundleID
    error:(NSError **)error;

/// Returns the receipt validation status of the application with the given \c applicationBundleID.
/// If an error occurred while loading from cache \c error is populated with error information and
/// \c nil is returned.
- (nullable BZRReceiptValidationStatusCacheEntry *)loadCacheEntryOfApplicationWithBundleID:
    (NSString *)applicationBundleID error:(NSError **)error;

@end

#pragma mark -
#pragma mark BZRReceiptValidationStatusCache+MultiApp
#pragma mark -

/// Adds convenience method for loading cache entries of multiple applications.
@interface BZRReceiptValidationStatusCache (MultiApp)

/// Loads the cache entry of the applications specified by \c bundledApplicationsIDs. If there was
/// an error loading a cache cache entry or it was not found in cache, it will not appear in the
/// returned dictionary.
- (NSDictionary<NSString *, BZRReceiptValidationStatusCacheEntry *> *)
    loadReceiptValidationStatusCacheEntries:(NSSet<NSString *> *)bundledApplicationsIDs;

@end

NS_ASSUME_NONNULL_END

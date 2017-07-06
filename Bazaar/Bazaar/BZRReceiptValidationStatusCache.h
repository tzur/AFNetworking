// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorage, BZRReceiptValidationStatus, BZRKeychainStorageMigrator,
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

/// Initializes with \c keychainStorage, used to read and store receipt validation status.
- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage
    NS_DESIGNATED_INITIALIZER;

/// Stores the receipt validation status to storage and returns \c YES on success. If an error
/// occurred while writing to the cache \c error is populated with error information and \c NO
/// is returned.
- (BOOL)storeCacheEntry:
    (nullable BZRReceiptValidationStatusCacheEntry *)receiptValidationStatusCacheEntry
    error:(NSError **)error;

/// Returns the receipt validation status from storage. If an error occurred while loading from
/// cache \c error is populated with error information and \c nil is returned.
- (nullable BZRReceiptValidationStatusCacheEntry *)loadCacheEntry:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

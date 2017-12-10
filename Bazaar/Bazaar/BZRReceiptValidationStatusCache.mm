// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRReceiptValidationStatusCache.h"

#import "BZREvent.h"
#import "BZRKeychainStorageMigrator.h"
#import "BZRKeychainStorageRoute.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTimeProvider.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRReceiptValidationStatusCacheEntry
#pragma mark -

@implementation BZRReceiptValidationStatusCacheEntry

- (instancetype)initWithReceiptValidationStatus:(BZRReceiptValidationStatus *)validationStatus
                                cachingDateTime:(NSDate *)cachingDateTime {
  if (self = [super init]) {
    _receiptValidationStatus = validationStatus;
    _cachingDateTime = cachingDateTime;
  }
  return self;
}

@end

#pragma mark -
#pragma mark BZRReceiptValidationStatusCache
#pragma mark -

@interface BZRReceiptValidationStatusCache ()

/// Storage used to cache the latest fetched \c receiptValidationStatus.
@property (readonly, nonatomic) BZRKeychainStorageRoute *keychainStorageRoute;

@end

@implementation BZRReceiptValidationStatusCache

/// Storage key to which the cached cache entry will be written to. The cached entry is stored
/// as an \c NSDictionary with two entries, one is the receipt validation status and the other is
/// a timestamp.
NSString * const kCachedReceiptValidationStatusStorageKey = @"receiptValidationStatus";

/// Key to a \c BZRReceiptValidationStatus in the cached entry.
NSString * const kValidationStatusKey = @"validationStatus";

/// Key to an \c NSDate in the cached entry specifying the time and date of the cached receipt
/// validation status.
NSString * const kValidationDateKey = @"validationDate";

#pragma mark -
#pragma mark Migration
#pragma mark -

+ (BOOL)migrateReceiptValidationStatusWithMigrator:(BZRKeychainStorageMigrator *)migrator
                                             error:(NSError * __autoreleasing *)error {
  return [migrator migrateValueForKey:kCachedReceiptValidationStatusStorageKey
                              ofClass:[NSDictionary class] error:error];
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithKeychainStorage:(BZRKeychainStorageRoute *)keychainStorageRoute {
  if (self = [super init]) {
    _keychainStorageRoute = keychainStorageRoute;
  }
  return self;
}

#pragma mark -
#pragma mark Storing receipt validation status
#pragma mark -

- (BOOL)storeCacheEntry:
    (nullable BZRReceiptValidationStatusCacheEntry *)receiptValidationStatusCacheEntry
    applicationBundleID:(NSString *)applicationBundleID
    error:(NSError * __autoreleasing *)error {
  NSDictionary<NSString *, NSObject *> *receiptValidationStatusForCaching;
  if (receiptValidationStatusCacheEntry) {
    receiptValidationStatusForCaching = @{
      kValidationStatusKey: receiptValidationStatusCacheEntry.receiptValidationStatus,
      kValidationDateKey: receiptValidationStatusCacheEntry.cachingDateTime
    };
  }
  return [self storeValue:receiptValidationStatusForCaching
          forKey:kCachedReceiptValidationStatusStorageKey applicationBundleID:applicationBundleID
          error:error];
}

- (BOOL)storeValue:(nullable id)value forKey:(NSString *)key
    applicationBundleID:(NSString *)applicationBundleID error:(NSError * __autoreleasing *)error {
  NSError *storageError;
  BOOL success = [self.keychainStorageRoute setValue:value forKey:key
                                         serviceName:applicationBundleID error:&storageError];
  if (!success && error) {
    auto description =
        [NSString stringWithFormat:@"Failed to store the value: %@ for key: %@", value, key];
    *error = [NSError lt_errorWithCode:BZRErrorCodeStoringToKeychainStorageFailed
                       underlyingError:storageError description:@"%@", description];
  }

  return success;
}

#pragma mark -
#pragma mark Loading receipt validation status
#pragma mark -

- (nullable BZRReceiptValidationStatusCacheEntry *)loadCacheEntryOfApplicationWithBundleID:
    (NSString *)applicationBundleID error:(NSError * __autoreleasing *)error {
  NSDictionary<NSString *, id> * _Nullable cachedReceiptValidationStatus =
      (NSDictionary *)[self.keychainStorageRoute
                       valueForKey:kCachedReceiptValidationStatusStorageKey
                       serviceName:applicationBundleID error:error];

  if (!cachedReceiptValidationStatus) {
    return nil;
  }
  return [[BZRReceiptValidationStatusCacheEntry alloc]
          initWithReceiptValidationStatus:cachedReceiptValidationStatus[kValidationStatusKey]
          cachingDateTime:cachedReceiptValidationStatus[kValidationDateKey]];
}

@end

NS_ASSUME_NONNULL_END

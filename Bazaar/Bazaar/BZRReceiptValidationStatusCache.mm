// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRReceiptValidationStatusCache.h"

#import "BZREvent.h"
#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRKeychainStorageMigrator.h"
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
@property (readonly, nonatomic) BZRKeychainStorage *keychainStorage;

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

- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage {
  if (self = [super init]) {
    _keychainStorage = keychainStorage;
  }
  return self;
}

#pragma mark -
#pragma mark Storing receipt validation status
#pragma mark -

- (BOOL)storeCacheEntry:
    (nullable BZRReceiptValidationStatusCacheEntry *)receiptValidationStatusCacheEntry
    error:(NSError * __autoreleasing *)error {
  NSDictionary<NSString *, NSObject *> *receiptValidationStatusForCaching;
  if (receiptValidationStatusCacheEntry) {
    receiptValidationStatusForCaching = @{
      kValidationStatusKey: receiptValidationStatusCacheEntry.receiptValidationStatus,
      kValidationDateKey: receiptValidationStatusCacheEntry.cachingDateTime
    };
  }
  return [self storeValue:receiptValidationStatusForCaching
                   forKey:kCachedReceiptValidationStatusStorageKey error:error];
}

- (BOOL)storeValue:(nullable id)value forKey:(NSString *)key
             error:(NSError * __autoreleasing *)error {
  NSError *storageError;
  BOOL success = [self.keychainStorage setValue:value forKey:key error:&storageError];
  if (!success && error) {
    auto description =
        [NSString stringWithFormat:@"Failed to store the value: %@ for key: %@", value, key];
    *error = [NSError lt_errorWithCode:BZRErrorCodeStoringDataToStorageFailed
                       underlyingError:storageError description:@"%@", description];
  }

  return success;
}

#pragma mark -
#pragma mark Loading receipt validation status
#pragma mark -

- (nullable BZRReceiptValidationStatusCacheEntry *)loadCacheEntry:
    (NSError * __autoreleasing *)error {
  NSError *underlyingError;
  NSDictionary<NSString *, id> * _Nullable cachedReceiptValidationStatus =
      [self.keychainStorage valueOfClass:[NSDictionary class]
                                  forKey:kCachedReceiptValidationStatusStorageKey
                                   error:&underlyingError];
  if (!cachedReceiptValidationStatus) {
    if (error && underlyingError) {
      auto description = [NSString stringWithFormat:@"Failed to load value for key: %@",
                          kCachedReceiptValidationStatusStorageKey];
      *error = [NSError lt_errorWithCode:BZRErrorCodeLoadingDataFromStorageFailed
                         underlyingError:underlyingError description:@"%@", description];
    }
    return nil;
  }
  return [[BZRReceiptValidationStatusCacheEntry alloc]
          initWithReceiptValidationStatus:cachedReceiptValidationStatus[kValidationStatusKey]
          cachingDateTime:cachedReceiptValidationStatus[kValidationDateKey]];
}

@end

NS_ASSUME_NONNULL_END

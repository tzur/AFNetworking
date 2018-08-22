// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRReceiptValidationStatusCache.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRKeychainStorageMigrator.h"
#import "BZRKeychainStorageRoute.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRValidatricksReceiptModelDeprecated.h"
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

/// Storage key to which the cache entry is written to. The cached entry is stored as an
/// \c NSDictionary with two entries, one is the receipt validation status and the other is a
/// timestamp.
NSString * const kCachedReceiptValidationStatusStorageKey = @"receiptValidationStatus";

/// Key to a \c BZRReceiptValidationStatus in the cached entry.
NSString * const kValidationStatusKey = @"validationStatus";

/// Key to an \c NSDate in the cached entry specifying the time and date of the cached receipt
/// validation status.
NSString * const kValidationDateKey = @"validationDate";

NSString * const kBZRCachedReceiptValidationStatusFirstErrorDateTime =
    @"receiptValidationFirstErrorDateTime";

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

- (BOOL)storeCacheEntry:(nullable BZRReceiptValidationStatusCacheEntry *)cacheEntry
    applicationBundleID:(NSString *)applicationBundleID error:(NSError * __autoreleasing *)error {
  NSDictionary<NSString *, id> * _Nullable receiptValidationStatusForCaching;

  if (cacheEntry) {
    receiptValidationStatusForCaching = @{
      kValidationStatusKey: cacheEntry.receiptValidationStatus,
      kValidationDateKey: cacheEntry.cachingDateTime
    };
  }

  return [self.keychainStorageRoute setValue:receiptValidationStatusForCaching
                                      forKey:kCachedReceiptValidationStatusStorageKey
                                 serviceName:applicationBundleID error:error];
}

- (nullable NSDate *)firstErrorDateTimeForApplicationBundleID:(NSString *)applicationBundleID {
  return (NSDate *)
      [self.keychainStorageRoute valueForKey:kBZRCachedReceiptValidationStatusFirstErrorDateTime
                                 serviceName:applicationBundleID error:nil];
}

- (void)storeFirstErrorDateTime:(nullable NSDate *)firstErrorDateTime
            applicationBundleID:(NSString *)applicationBundleID {
  [self.keychainStorageRoute setValue:firstErrorDateTime
                               forKey:kBZRCachedReceiptValidationStatusFirstErrorDateTime
                          serviceName:applicationBundleID error:nil];
}

#pragma mark -
#pragma mark Loading receipt validation status
#pragma mark -

- (nullable BZRReceiptValidationStatusCacheEntry *)loadCacheEntryOfApplicationWithBundleID:
    (NSString *)applicationBundleID error:(NSError * __autoreleasing *)error {
  NSDictionary<NSString *, id> * _Nullable receiptValidationStatusDictionary =
      (NSDictionary *)[self.keychainStorageRoute
                       valueForKey:kCachedReceiptValidationStatusStorageKey
                       serviceName:applicationBundleID error:error];
  auto _Nullable cacheEntry =
      [self cacheEntryFromCachedDictionary:receiptValidationStatusDictionary error:error];

  if ([receiptValidationStatusDictionary[kValidationStatusKey] isKindOfClass:
       BZRValidatricksReceiptValidationStatus.class]) {
    [self storeCacheEntry:cacheEntry applicationBundleID:applicationBundleID error:nil];
  }

  return cacheEntry;
}

- (nullable BZRReceiptValidationStatusCacheEntry *)cacheEntryFromCachedDictionary:
    (nullable NSDictionary<NSString *, id> *)cachedDictionary
    error:(NSError * __autoreleasing *)error {
  if (!cachedDictionary) {
    return nil;
  }

  BZRReceiptValidationStatus * _Nullable receiptValidationStatus;
  if ([cachedDictionary[kValidationStatusKey] isKindOfClass:
      BZRValidatricksReceiptValidationStatus.class]) {
    receiptValidationStatus =
        [self validatricksReceiptValidationStatusToBaseClass:cachedDictionary[kValidationStatusKey]
                                                       error:error];

    if (!receiptValidationStatus) {
      return nil;
    }
  } else {
    receiptValidationStatus = cachedDictionary[kValidationStatusKey];
  }

  return [[BZRReceiptValidationStatusCacheEntry alloc]
          initWithReceiptValidationStatus:lt::nn(receiptValidationStatus)
          cachingDateTime:cachedDictionary[kValidationDateKey]];
}

- (nullable BZRReceiptValidationStatus *)validatricksReceiptValidationStatusToBaseClass:
    (BZRValidatricksReceiptValidationStatus *)validatricksReceiptValidationStatus
    error:(NSError * __autoreleasing *)error {
  auto _Nullable receiptValidationStatusJSON =
      [MTLJSONAdapter JSONDictionaryFromModel:validatricksReceiptValidationStatus];
  if (!receiptValidationStatusJSON) {
    if (error) {
      *error = [NSError lt_errorWithCode:BZRErrorCodeModelJSONSerializationFailed
                             description:@"Failed to serialize model of class %@ into JSON. Model "
                                         "is: %@", validatricksReceiptValidationStatus.class,
                                         validatricksReceiptValidationStatus];
    }
    return nil;
  }

  NSError *serializationError;
  BZRReceiptValidationStatus * _Nullable receiptValidationStatus =
      [MTLJSONAdapter modelOfClass:BZRReceiptValidationStatus.class
                fromJSONDictionary:receiptValidationStatusJSON error:&serializationError];
  if (!receiptValidationStatus) {
    if (error) {
      *error = [NSError lt_errorWithCode:BZRErrorCodeModelJSONDeserializationFailed
                         underlyingError:serializationError
                             description:@"Failed to deserialize JSON into model of class %@. JSON "
                                         "is: %@", BZRReceiptValidationStatus.class,
                                         receiptValidationStatusJSON];
    }
  }

  return receiptValidationStatus;
}

@end

#pragma mark -
#pragma mark BZRReceiptValidationStatusCache+MultiApp
#pragma mark -

@implementation BZRReceiptValidationStatusCache (MultiApp)

- (NSDictionary<NSString *, BZRReceiptValidationStatusCacheEntry *> *)
    loadReceiptValidationStatusCacheEntries:(NSSet<NSString *> *)bundledApplicationsIDs {
  return [bundledApplicationsIDs.allObjects lt_reduce:
       ^NSDictionary<NSString *, BZRReceiptValidationStatusCacheEntry *> *
       (NSDictionary<NSString *, BZRReceiptValidationStatusCacheEntry *> *dictionarySoFar,
        NSString *bundleID) {
         auto _Nullable cacheEntry =
             [self loadCacheEntryOfApplicationWithBundleID:bundleID error:nil];
         if (!cacheEntry) {
           return dictionarySoFar;
         }

         return [dictionarySoFar mtl_dictionaryByAddingEntriesFromDictionary:@{
           bundleID: cacheEntry
         }];
       } initial:@{}];
}

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "BZRKeychainStorage.h"

#import <UICKeyChainStore/UICKeyChainStore.h>

#import "BZREvent.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRKeychainStorage ()

/// Store used to read and write to the keychain.
@property (readonly, nonatomic) UICKeyChainStore *keychainStore;

/// Subject used to send events when errors occur.
@property (readonly, nonatomic) RACSubject *storageErrorsSubject;

@end

@implementation BZRKeychainStorage

@synthesize eventsSignal = _eventsSignal;

- (instancetype)initWithAccessGroup:(nullable NSString *)accessGroup {
  return [self initWithAccessGroup:accessGroup service:[UICKeyChainStore defaultService]];
}

- (instancetype)initWithAccessGroup:(nullable NSString *)accessGroup
                            service:(NSString *)service {
  auto keychainStore = [UICKeyChainStore keyChainStoreWithService:service accessGroup:accessGroup];

  return [self initWithKeychainStore:keychainStore];
}

- (instancetype)initWithKeychainStore:(UICKeyChainStore *)keychainStore {
  if (self = [super init]) {
    _keychainStore = keychainStore;
    _storageErrorsSubject = [RACSubject subject];
    _eventsSignal = [self.storageErrorsSubject takeUntil:[self rac_willDeallocSignal]];
  }
  return self;
}

- (nullable id<NSSecureCoding>)valueForKey:(NSString *)key
                                     error:(NSError * __autoreleasing *)error {
  NSError *underlyingError;
  NSData *data = [self.keychainStore dataForKey:key error:&underlyingError];
  if (!data) {
    if (underlyingError) {
      NSString *description =
          [NSString stringWithFormat:@"Failed to load value for key \"%@\". Reason: %@.", key,
           [BZRKeychainStorage descriptionForKeychainStoreError:underlyingError]];
      auto storageError =
          [NSError bzr_storageErrorWithCode:BZRErrorCodeLoadingFromKeychainStorageFailed
                            underlyingError:underlyingError description:description
                 keychainStorageServiceName:self.service keychainStorageKey:key
                       keychainStorageValue:nil];
      [self.storageErrorsSubject sendNext:
       [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:storageError]];

      if (error) {
        *error = storageError;
      }
    }
    return nil;
  }

  id<NSSecureCoding> value;
  try {
    value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (!value) {
      NSString *description =
          [NSString stringWithFormat:@"Failed to load value for key \"%@\" during unarchiving. "
           "Reason: %@.", key,
           [BZRKeychainStorage descriptionForKeychainStoreError:underlyingError]];
      auto storageError =
          [NSError bzr_storageErrorWithCode:BZRErrorCodeKeychainStorageArchivingError
                            underlyingError:nil description:description
                 keychainStorageServiceName:self.service keychainStorageKey:key
                       keychainStorageValue:nil];
      [self.storageErrorsSubject sendNext:
       [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:storageError]];

      if (error) {
        *error = storageError;
      }
    }
  } catch (NSException *exception) {
    NSString *description =
        [NSString stringWithFormat:@"Exception %@ raised while loading value for key \"%@\" "
         "during unarchiving. Reason: %@.", exception.name, key, exception.reason];
    auto storageError =
        [NSError bzr_storageErrorWithCode:BZRErrorCodeKeychainStorageArchivingError
                          underlyingError:nil description:description
               keychainStorageServiceName:self.service keychainStorageKey:key
                     keychainStorageValue:nil];
    [self.storageErrorsSubject sendNext:
     [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:storageError]];

    if (error) {
      *error = storageError;
    }
  }
  return value;
}

- (BOOL)setValue:(nullable id<NSSecureCoding>)value forKey:(NSString *)key
           error:(NSError * __autoreleasing *)error {
  NSData *data = nil;
  if (value) {
    data = [NSKeyedArchiver archivedDataWithRootObject:value];
    LTParameterAssert(data, @"Value is not serializable.");
  }

  NSError *underlyingError;
  BOOL success = [self.keychainStore setData:data forKey:key error:&underlyingError];
  if (!success) {
      NSString *description =
          [NSString stringWithFormat:@"Failed to store value \"%@\" for key \"%@\". Reason: %@.",
           value, key, [BZRKeychainStorage descriptionForKeychainStoreError:underlyingError]];
      auto storageError =
          [NSError bzr_storageErrorWithCode:BZRErrorCodeStoringToKeychainStorageFailed
                            underlyingError:underlyingError description:description
                 keychainStorageServiceName:self.service keychainStorageKey:key
                       keychainStorageValue:value];

    [self.storageErrorsSubject sendNext:
     [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:storageError]];

    if (error) {
      *error = storageError;
    }
  }
  return success;
}

+ (NSString *)descriptionForKeychainStoreError:(NSError *)keychainStoreError {
  const NSInteger kUICKeyChainStoreConversionErrorCode = -67594;
  const NSInteger kUICKeyChainStoreUnexpectedErrorCode = -99999;

  switch (keychainStoreError.code) {
    case UICKeyChainStoreErrorInvalidArguments:
      return @"Invalid arguments";
    case kUICKeyChainStoreConversionErrorCode:
      return @"Conversion failed";
    case kUICKeyChainStoreUnexpectedErrorCode:
      return @"Unexpected failure";
  }

  return @"Access denied";
}

+ (NSString *)defaultService {
  return [UICKeyChainStore defaultService];
}

- (nullable NSString *)service {
  return self.keychainStore.service;
}

@end

@implementation BZRKeychainStorage (SharedKeychain)

+ (NSString *)defaultSharedAccessGroup {
  NSString *sharedAccessGroup = [self accessGroupWithAppIdentifierPrefix:@"com.lightricks.shared"];
  LTAssert(sharedAccessGroup, @"Can not initialize the default shared keychain access group. Make "
           "sure AppIdentifierPrefix is correctly defined in the application's main bundle plist");
  return sharedAccessGroup;
}

+ (nullable NSString *)accessGroupWithAppIdentifierPrefix:(NSString *)accessGroup {
  /// Key in the application's main bundle plist file, mapping to the application identifier prefix,
  /// which is actually the Apple developer team ID.
  static NSString * const kAppIdentifierPrefixKey = @"AppIdentifierPrefix";

  NSString *appIdentifierPrefix =
      [[NSBundle mainBundle] objectForInfoDictionaryKey:kAppIdentifierPrefixKey];
  return [appIdentifierPrefix stringByAppendingString:accessGroup];
}

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "BZRKeychainStorage.h"

#import "BZRKeychainHandler.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"
#import "UICKeyChainStore+SecureStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRKeychainStorage ()

/// Internal \c BZRKeychainHandler conforming class used to read and write to the keychain.
@property (readonly, nonatomic) id<BZRKeychainHandler> keychainHandler;

@end

@implementation BZRKeychainStorage

- (instancetype)initWithAccessGroup:(nullable NSString *)accessGroup {
  return [self initWithAccessGroup:accessGroup service:[UICKeyChainStore defaultService]];
}

- (instancetype)initWithAccessGroup:(nullable NSString *)accessGroup
                            service:(NSString *)service {
  UICKeyChainStore *keychainStore =
      [[UICKeyChainStore alloc] initWithService:service accessGroup:accessGroup];

  return [self initWithKeychainHandler:keychainStore];
}

- (instancetype)initWithKeychainHandler:(id<BZRKeychainHandler>)keychainHandler {
  if (self = [super init]) {
    _keychainHandler = keychainHandler;
  }
  return self;
}

- (nullable id<NSSecureCoding>)valueForKey:(NSString *)key
                                     error:(NSError * __autoreleasing *)error {
  NSError *underlyingError;
  NSData *data = [self.keychainHandler dataForKey:key error:&underlyingError];
  if (!data) {
    if (underlyingError && error) {
      *error = [self.keychainHandler.class errorForUnderlyingError:underlyingError];
    }
    return nil;
  }

  id<NSSecureCoding> value;
  try {
    value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (!value && error) {
      *error = [NSError lt_errorWithCode:BZRErrorCodeKeychainStorageArchivingError];
    }
  } catch (NSException *exception) {
    if (error) {
      *error = [NSError bzr_errorWithCode:BZRErrorCodeKeychainStorageArchivingError
                                exception:exception];
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
  BOOL success = [self.keychainHandler setData:data forKey:key error:&underlyingError];
  if (!success) {
    if (error) {
      *error = underlyingError ?
          [self.keychainHandler.class errorForUnderlyingError:underlyingError] :
          [NSError lt_errorWithCode:BZRErrorCodeKeychainStorageUnexpectedFailure];
    }
  }
  return success;
}

@end

NS_ASSUME_NONNULL_END

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
  UICKeyChainStore *keychainStore =
      [[UICKeyChainStore alloc] initWithService:[UICKeyChainStore defaultService]
                                    accessGroup:accessGroup];
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
  
  if (!data ||  underlyingError) {
    if (error) {
      *error = [self.keychainHandler errorForUnderlyingError:underlyingError];
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

- (void)setValue:(nullable id<NSSecureCoding>)value forKey:(NSString *)key
           error:(NSError * __autoreleasing *)error {
  NSData *data = nil;
  if (value) {
    LTParameterAssert([self isObjectValidForArchiving:value], @"Value is not serializable.");
    data = [NSKeyedArchiver archivedDataWithRootObject:value];
  }
  NSError *underlyingError;
  [self.keychainHandler setData:data forKey:key error:&underlyingError];
  if (error) {
    *error = [self.keychainHandler errorForUnderlyingError:underlyingError];
  }
}

- (BOOL)isObjectValidForArchiving:(id)object {
    return [NSPropertyListSerialization propertyList:object
                                    isValidForFormat:NSPropertyListBinaryFormat_v1_0];
}

@end

NS_ASSUME_NONNULL_END

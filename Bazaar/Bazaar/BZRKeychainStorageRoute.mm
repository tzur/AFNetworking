// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRKeychainStorageRoute.h"

#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSSet+Functional.h>

#import "BZRKeychainStorage.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRKeychainStorageRoute ()

/// A dictionary mapping service names to keychain storage, used to store and retrieve from multiple
/// storage locations.
@property (readonly, nonatomic) NSDictionary<NSString *, BZRKeychainStorage *> *
    serviceNameToKeychainStorage;

@end

@implementation BZRKeychainStorageRoute

- (instancetype)initWithMultiKeychainStorage:(NSArray<BZRKeychainStorage *> *)multiKeychainStorage {
  if (self = [super init]) {
    NSArray<NSString *> *services =
        [multiKeychainStorage lt_map:^NSString *(BZRKeychainStorage *keychainStorage) {
          return keychainStorage.service ?: [BZRKeychainStorage defaultService];
        }];
    _serviceNameToKeychainStorage =
        [NSDictionary dictionaryWithObjects:multiKeychainStorage forKeys:services];
  }
  return self;
}

- (nullable id<NSSecureCoding>)valueForKey:(NSString *)key
                               serviceName:(nullable NSString *)serviceName
                                     error:(NSError * __autoreleasing *)error {
  auto _Nullable keychainStorage = [self keychainStorageForServiceName:serviceName];

  if (!keychainStorage) {
    if (error) {
      *error = [NSError lt_errorWithCode:BZRErrorCodeServiceNameNotFound];
    }
    return nil;
  }

  return [keychainStorage valueForKey:key error:error];
}

- (BOOL)setValue:(nullable id<NSSecureCoding>)value forKey:(NSString *)key
     serviceName:(nullable NSString *)serviceName error:(NSError * __autoreleasing *)error {
  auto _Nullable keychainStorage = [self keychainStorageForServiceName:serviceName];

  if (!keychainStorage) {
    if (error) {
      *error = [NSError lt_errorWithCode:BZRErrorCodeServiceNameNotFound];
    }
    return NO;
  }

  return [keychainStorage setValue:value forKey:key error:error];
}

- (nullable BZRKeychainStorage *)keychainStorageForServiceName:(nullable NSString *)serviceName {
  return serviceName ? self.serviceNameToKeychainStorage[serviceName] :
      self.serviceNameToKeychainStorage[[BZRKeychainStorage defaultService]];
}

@end

@implementation BZRKeychainStorageRoute (MultiplePartitions)

- (instancetype)initWithAccessGroup:(nullable NSString *)accessGroup
                       serviceNames:(NSSet<NSString *> *)serviceNames {
  auto multiKeychainStorage = [serviceNames lt_map:^BZRKeychainStorage *(NSString *serviceName) {
    if ([serviceName isEqual:[NSNull null]]) {
      return [[BZRKeychainStorage alloc] initWithAccessGroup:accessGroup];
    }

    return [[BZRKeychainStorage alloc] initWithAccessGroup:accessGroup service:serviceName];
  }];

  return [self initWithMultiKeychainStorage:multiKeychainStorage.allObjects];
}

@end

NS_ASSUME_NONNULL_END

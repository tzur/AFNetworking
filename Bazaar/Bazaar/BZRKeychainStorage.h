// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

@protocol BZRKeychainHandler;

NS_ASSUME_NONNULL_BEGIN

/// Wrapper class for \c BZRKeychainHandler conforming classes that allows the storage of values
/// that conform to \c NSSecureCoding.
@interface BZRKeychainStorage : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with new underlying \c BZRKeychainHandler with the specified \c accessGroup,
/// a key used to share access to the same storage through different applications, and \c service
/// initialized to the default service.
- (instancetype)initWithAccessGroup:(nullable NSString *)accessGroup;

/// Initializes with new underlying \c BZRKeychainHandler with the specified \c accessGroup,
/// a key used to share access to the same storage through different applications, and with
/// \c service, used to access an application's partition in the keychain storage.
- (instancetype)initWithAccessGroup:(nullable NSString *)accessGroup service:(NSString *)service;

/// Initializes with a \c BZRKeychainHandler conforming class to be used for keychain storage.
- (instancetype)initWithKeychainHandler:(id<BZRKeychainHandler>)keychainHandler
      NS_DESIGNATED_INITIALIZER;

/// Value for the given \c key if it exists or \c nil otherwise. \c error is set with an appropriate
/// error on failure.
- (nullable id<NSSecureCoding>)valueForKey:(NSString *)key error:(NSError **)error;

/// Set the value of \c key to be \c value. If \c value is \c nil, \c key will be removed from the
/// receiver. On success returns \c YES, on failure returns \c NO and \c error is set with an
/// appropriate error.
- (BOOL)setValue:(nullable id<NSSecureCoding>)value forKey:(NSString *)key error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

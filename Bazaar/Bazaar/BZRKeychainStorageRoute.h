// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorage;

/// Keychain storage that can store and retrieve data from multiple storage locations.
@interface BZRKeychainStorageRoute : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c multiKeychainStorage, from which the receiver can store and retrieve data.
- (instancetype)initWithMultiKeychainStorage:(NSArray<BZRKeychainStorage *> *)multiKeychainStorage
    NS_DESIGNATED_INITIALIZER;

/// Returns the value for the given \c key if it exists in partition \c serviceName, or \c nil
/// otherwise. \c error is set with an appropriate error on failure.
- (nullable id<NSSecureCoding>)valueForKey:(NSString *)key
                               serviceName:(nullable NSString *)serviceName
                                     error:(NSError **)error;

/// Sets the value of \c key to be \c value in partition \c serviceName. If \c value is \c nil,
/// \c key will be removed from partition \c serviceName. On success returns \c YES, on failure
/// returns \c NO and \c error is set with an appropriate error.
- (BOOL)setValue:(nullable id<NSSecureCoding>)value forKey:(NSString *)key
     serviceName:(nullable NSString *)serviceName error:(NSError **)error;

@end

/// Adds convenience initializer used to create a \c BZRKeychainStorageRoute with the same access
/// group and multiple partitions.
@interface BZRKeychainStorageRoute (MultiplePartitions)

/// Initializes with \c accessGroup, used to access a particular group in keychain storage.
/// \c serviceNames specify the partitions that will be available for storing and retrieving data.
- (instancetype)initWithAccessGroup:(nullable NSString *)accessGroup
                       serviceNames:(NSSet<NSString *> *)serviceNames;

@end

NS_ASSUME_NONNULL_END

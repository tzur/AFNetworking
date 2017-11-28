// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for classes that store and retrieve data from the keychain.
@protocol BZRKeychainHandler <NSObject>

/// Data for the given \c key if it exists or \c nil otherwise. \c error is set with an appropriate
/// error on failure.
- (nullable NSData *)dataForKey:(NSString *)key error:(NSError **)error;

/// Set the value of \c key to be \c data. If \c data is \c nil, \c key will be removed from the
/// receiver's keychain storage. On success returns \c YES, on failure returns \c NO and \c error is
/// set with an appropriate error.
- (BOOL)setData:(nullable NSData *)data forKey:(NSString *)key error:(NSError **)error;

/// Bazaar namespace error for the given underlying class error.
+ (NSError *)errorForUnderlyingError:(NSError *)underlyingError;

/// Name of the service that is used to access a partition in the keychain storage.
@property (readonly, nonatomic, nullable) NSString *service;

@end

NS_ASSUME_NONNULL_END

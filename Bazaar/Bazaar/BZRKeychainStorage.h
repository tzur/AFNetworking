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

/// The name of the partition that \c BZRKeychainStorage initialized without \c service stores and
/// retrieves values from.
+ (NSString *)defaultService;

/// Name of the partition that the receiver stores and retrieves values from. \c nil if the receiver
/// accesses the default partition.
@property (readonly, nonatomic, nullable) NSString *service;

@end

/// Category for assisting with creation of shared keychain storage. In order for an application to
/// share a keychain with another application they both need to meet these terms:
///
/// * Signed with the same team identifier.
///
/// * KeyChain Sharing capability must be enabled.
///
/// * Add a common shared access group to the list of shared keychain groups.
///
/// Only keychains with access group that was added to the shared access groups list can be shared.
@interface BZRKeychainStorage (SharedKeychain)

/// Returns Lightricks' default shared keychain access group prepended with the application
/// identifier prefix.
///
/// If failed to initialize the shared access group with the AppIdentifierPrefix an
/// \c NSInternalInconsistencyException is raised.
+ (NSString *)defaultSharedAccessGroup;

/// Prepends the given \c accessGroup with the application identifier prefix, which is actually the
/// Team ID of the application vendor. This method will read the \c AppIdentifierPrefix from the
/// application's main bundle file. If this method fails to read the prefix from the application's
/// main bundle \c nil is returned.
///
/// @note When adding a shared access group an item is added to the application's entitlement file
/// under the key \c keychain-access-groups specifying the shared keychain access group. However the
/// access group added in the Capabilities section is not complete, the one that is added to the
/// entitlements file is prefixed with "$(AppIdentifierPrefix)". \c AppIdentifierPrefix is a
/// variable defined by Xcode and availabe at build time, it contains the Team ID used by Xcode to
/// sign the product.
+ (nullable NSString *)accessGroupWithAppIdentifierPrefix:(NSString *)accessGroup;

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorageRoute;

/// Object that provides the App Store locale of multiple applications and can store the App Store
/// locale of the current application.
///
/// @note This cache will be able to access only partitions of applications that store information
/// in the same shared access group as the currently running application.
/// @see BZRKeychainStorage for more information.
@interface BZRAppStoreLocaleCache : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c keychainStorageRoute, used to store and retrieve the App Store locale of
/// multiple applications.
- (instancetype)initWithKeychainStorageRoute:(BZRKeychainStorageRoute *)keychainStorageRoute
    NS_DESIGNATED_INITIALIZER;

/// Stores the given App Store locale to the partition of the application specified by \c bundleID
/// and returns \c YES on success. If an error occurred while storing to the cache \c error is
/// populated with error information and \c NO is returned.
- (BOOL)storeAppStoreLocale:(nullable NSLocale *)appStoreLocale bundleID:(NSString *)bundleID
                      error:(NSError **)error;

/// Returns the App Store locale of the application with \c bundleID. If the App Store locale was
/// not found \c nil will be returned. If there was an error \c nil will be returned and \c error
/// will be populated with an appropriate error.
- (nullable NSLocale *)appStoreLocaleForBundleID:(NSString *)bundleID error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

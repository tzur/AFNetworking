// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorageRoute;

/// Provides receipt data of multiple applications and caches the receipt data of the current
/// application when it changes.
@interface BZRReceiptDataCache : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c keychainStorageRoute, used to store and retrieve the receipt data of
/// multiple applications. \c currentApplicationBundleID is the bundle ID of the current
/// application.
- (instancetype)initWithKeychainStorageRoute:(BZRKeychainStorageRoute *)keychainStorageRoute
                  currentApplicationBundleID:(NSString *)currentApplicationBundleID
    NS_DESIGNATED_INITIALIZER;

/// Stores the receipt data of the current application to the partition of the current application.
/// If the receipt data is \c nil, it will not be stored.
- (void)storeReceiptData;

/// Returns the receipt data of the application with \c bundleID. If the receipt data was not found
/// \c nil will be returned. If there was an error \c nil will be returned and \c error will be
/// popuplated with an appropriate error.
- (nullable NSData *)receiptDataForBundleID:(NSString *)bundleID error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

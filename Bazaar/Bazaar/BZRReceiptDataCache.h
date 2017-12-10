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
    NS_DESIGNATED_INITIALIZER;

/// Stores the \c receiptData of the application with the bundle ID specified by
/// \c applicationBundleID, and returns \c YES on success. If there was an error \c NO will be
/// returned and \c error will be populated with an appropriate error.
- (BOOL)storeReceiptData:(nullable NSData *)receiptData
     applicationBundleID:(NSString *)applicationBundleID error:(NSError **)error;

/// Loads and returns the receipt data of the application with \c applicationBundleID. If there was
/// an error \c nil will be returned and \c error will be populated with an appropriate error.
///
/// @note If the value doesn't exist in the storage, a \c nil value will be returned, thus \c nil
/// might be returned even if there was no error.
- (nullable NSData *)receiptDataForApplicationBundleID:(NSString *)applicationBundleID
                                                 error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

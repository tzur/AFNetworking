// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Value object representing the set of parameters required by \c BZRReceiptValidator in order
/// to validate a receipt.
@interface BZRReceiptValidationParameters : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the request parameters with the specified \c currentApplicationBundleID,
///  \c applicationBundleID, \c receiptsData, \c deviceID, \c appStoreLocale and \c userID.
- (instancetype)initWithCurrentApplicationBundleID:(NSString *)currentApplicationBundleID
    applicationBundleID:(NSString *)applicationBundleID receiptData:(nullable NSData *)receiptData
    deviceID:(nullable NSUUID *)deviceID appStoreLocale:(nullable NSLocale *)appStoreLocale
    userID:(nullable NSString *)userID NS_DESIGNATED_INITIALIZER;

/// Current application's bundle ID.
@property (readonly, nonatomic) NSString *currentApplicationBundleID;

/// Bundle identification of the application for which validation is desired.
@property (readonly, nonatomic) NSString *applicationBundleID;

/// Receipt data of the application for which validation is desired.
@property (readonly, nonatomic, nullable) NSData *receiptData;

/// Expected device identifier that the receipt was issued for.
@property (readonly, nonatomic, nullable) NSUUID *deviceID;

/// App Store locale of the application for which validation is desired.
@property (readonly, nonatomic, nullable) NSLocale *appStoreLocale;

/// Unique identifier of the user.
@property (readonly, nonatomic, nullable) NSString *userID;

@end

NS_ASSUME_NONNULL_END

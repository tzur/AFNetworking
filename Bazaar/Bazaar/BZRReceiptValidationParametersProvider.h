// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRAppStoreLocaleCache, BZRReceiptDataCache, BZRReceiptValidationParameters;

/// Protocol for providing \c BZRReceiptValidationParameters.
@protocol BZRReceiptValidationParametersProvider

/// Returns receipt validation parameters for validating the receipt of application with
/// \c applicationBundleID. An additional identifier of the user may be provided via
/// \c userID.
- (nullable BZRReceiptValidationParameters *)receiptValidationParametersForApplication:
    (NSString *)applicationBundleID userID:(nullable NSString *)userID;

/// App Store locale. KVO-compliant.
@property (strong, atomic, nullable) NSLocale *appStoreLocale;

@end

/// Default implementation of \c BZRReceiptValidationParametersProvider.
@interface BZRReceiptValidationParametersProvider :
    NSObject <BZRReceiptValidationParametersProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c appStoreLocaleCache, used to load App Store locale of multiple applications
/// from cache. \c receiptDataCache is used to load receipt data of multiple applications from
/// cache. \c currentApplicationBundleID is the bundle ID of the current application.
- (instancetype)initWithAppStoreLocaleCache:(BZRAppStoreLocaleCache *)appStoreLocaleCache
                           receiptDataCache:(BZRReceiptDataCache *)receiptDataCache
                 currentApplicationBundleID:(NSString *)currentApplicationBundleID;

@end

NS_ASSUME_NONNULL_END

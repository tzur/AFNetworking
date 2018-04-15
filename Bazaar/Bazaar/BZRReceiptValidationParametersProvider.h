// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRAppStoreLocaleProvider, BZRReceiptDataCache, BZRReceiptValidationParameters;

/// Protocol for providing \c BZRReceiptValidationParameters.
@protocol BZRReceiptValidationParametersProvider

/// Returns receipt validation parameters for validating the receipt of application with
/// \c applicationBundleID. An additional identifier of the user may be provided via
/// \c userID.
- (nullable BZRReceiptValidationParameters *)receiptValidationParametersForApplication:
    (NSString *)applicationBundleID userID:(nullable NSString *)userID;

@end

/// Default implementation of \c BZRReceiptValidationParametersProvider.
@interface BZRReceiptValidationParametersProvider :
    NSObject <BZRReceiptValidationParametersProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c appStoreLocaleProvider, used to provide App Store locale of multiple
/// applications. \c receiptDataCache is used to load receipt data of multiple applications from
/// cache. \c currentApplicationBundleID is the bundle ID of the current application.
- (instancetype)initWithAppStoreLocaleProvider:(BZRAppStoreLocaleProvider *)appStoreLocaleProvider
                              receiptDataCache:(BZRReceiptDataCache *)receiptDataCache
                    currentApplicationBundleID:(NSString *)currentApplicationBundleID;

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

@class BZRAppStoreLocaleCache, BZRStoreKitMetadataFetcher;

@protocol BZRProductsProvider;

NS_ASSUME_NONNULL_BEGIN

/// Provider used to provide the current user's App Store locale.
@interface BZRAppStoreLocaleProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c appStoreLocaleCache used store and retrieve the App Store locale from
/// cache, \c productsProvider used to provide the list of products, \c metadataFetcher
/// used to fetch the App Store locale from a list of products and with
/// \c currentApplicationBundleID the bundle ID of the current application.
- (instancetype)initWithCache:(BZRAppStoreLocaleCache *)appStoreLocaleCache
             productsProvider:(id<BZRProductsProvider>)productsProvider
              metadataFetcher:(BZRStoreKitMetadataFetcher *)metadataFetcher
   currentApplicationBundleID:(NSString *)currentApplicationBundleID NS_DESIGNATED_INITIALIZER;

/// Stores the given App Store locale to the partition of the application specified by \c bundleID
/// and returns \c YES on success. If an error occurred while storing to the cache \c error is
/// populated with error information and \c NO is returned.
- (BOOL)storeAppStoreLocale:(nullable NSLocale *)appStoreLocale bundleID:(NSString *)bundleID
                      error:(NSError **)error;

/// Returns the App Store locale of the application with \c bundleID. If the App Store locale was
/// not found \c nil will be returned. If there was an error \c nil will be returned and \c error
/// will be populated with an appropriate error.
- (nullable NSLocale *)appStoreLocaleForBundleID:(NSString *)bundleID error:(NSError **)error;

/// App Store locale of the currently running application. KVO-compliant.
@property (readonly, atomic, nullable) NSLocale *appStoreLocale;

/// Flag indicating whether \c appStoreLocale was already fetched using StoreKit for this run.
@property (readonly, atomic) BOOL localeFetchedFromProductList;

@end

NS_ASSUME_NONNULL_END

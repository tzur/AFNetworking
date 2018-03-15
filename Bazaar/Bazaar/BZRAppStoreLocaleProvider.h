// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

@class BZRStoreKitMetadataFetcher;

@protocol BZRProductsProvider;

NS_ASSUME_NONNULL_BEGIN

/// Provider used to provide the current user's App Store locale.
@interface BZRAppStoreLocaleProvider : NSObject

/// Initializes with \c productsProvider used to provide the list of products and with
/// \c metadataFetcher used to fetch the App Store locale from a list of products.
- (instancetype)initWithProductsProvider:(id<BZRProductsProvider>)productsProvider
                         metadataFetcher:(BZRStoreKitMetadataFetcher *)metadataFetcher;

/// App Store locale. KVO-compliant.
@property (readonly, atomic, nullable) NSLocale *appStoreLocale;

@end

NS_ASSUME_NONNULL_END

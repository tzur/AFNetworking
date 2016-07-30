// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRProduct, BZRProductBundleManager, BZRProductContentFetcher, BZRProductEligibilityVerifier,
    LTPath;

@protocol BZRProductsProvider, BZRReceiptValidator;

/// Object used to provide configuration objects for \c BZRInAppStoreManager.
@interface BZRInAppStoreManagerConfiguration : NSObject

/// Initializes the in-app store configuration with default parameters.
///
/// \c productsProvider will be the initialized with \c BZRLocalJSONProductsProvider, which will be
/// initialized with the given \c productsListJSONFilePath.
///
/// \c bundleManager will be initialized with the default parameters as provided by
/// \c -[BZRProductsBundleManager init].
///
/// \c eligibilityVerifier will be initialized with the default initializer
/// \c -[BZRProductEligibilityVerifier init].
///
/// \c contentFetcher will be initialized with \c bundleManager and with the
/// \c BZRProductContentProviderFactory as provided by
/// \c -[BZRInAppProductPurchaser initWithBundleManager:].
///
/// \c receiptValidator will be initialized with the default initializer of
/// \c BZRValidatricksReceiptValidator as provided by \c -[BZRValidatricksReceiptValidator init].
- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath;

/// Provider used to fetch product list.
@property (strong, nonatomic) id<BZRProductsProvider> productsProvider;

/// Manager used to extract, delete and find content directory with.
@property (strong, nonatomic) BZRProductsBundleManager *bundleManager;

/// Verifier used to verify that a user is allowed to use a certain product.
@property (strong, nonatomic) BZRProductEligibilityVerifier *eligibilityVerifier;

/// Fetcher used to fetch a product's content.
@property (strong, nonatomic) BZRProductContentFetcher *contentFetcher;

/// Validator used to validate a user's receipt.
@property (strong, nonatomic) BZRReceiptValidator *receiptValidator;

@end

NS_ASSUME_NONNULL_END

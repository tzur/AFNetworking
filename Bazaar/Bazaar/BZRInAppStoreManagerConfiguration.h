// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorage, BZRProduct, BZRProductBundleManager, BZRProductContentProvider,
    BZRProductEligibilityVerifier, BZRReceiptValidationStatusProvider, LTPath;

@protocol BZRProductsProvider, BZRReceiptValidator;

/// Object used to provide configuration objects for \c BZRInAppStoreManager.
@interface BZRInAppStoreManagerConfiguration : NSObject

/// Initializes the in-app store configuration with default parameters.
///
/// \c productsProvider will be initialized with \c BZRLocalProductsProvider, given
/// \c productsListJSONFilePath.
///
/// \c bundleManager will be initialized with the default parameters as provided by
/// \c -[BZRProductBundleManager init].
///
/// \c validationStatusProvider will be initialized with the default initializer of
/// \c BZRReceiptValidationStatusProvider as provided by
/// \c -[BZRReceiptValidationStatusProvider initWithKeychainStorage:] with \c keychainStorage.
///
/// \c eligibilityVerifier will be initialized using
/// \c -[initWithReceiptValidationStatusProvider:timeProvider:expiredSubscriptionGracePeriod], with
/// \c validationStatusProvider, with a new instance of \c BZRTimeProvider, and with
/// \c expiredSubscriptionGracePeriod set to \c 7.
///
/// \c contentProvider will be initialized using
/// \c -[initWithEligibilityVerifier:contentFetcher:contentManager], with \c eligibilityVerifier,
/// with a new instance of \c BZRMultiContentFetcher, and with \c bundleManager.
- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath;

/// Provider used to fetch product list.
@property (strong, nonatomic) id<BZRProductsProvider> productsProvider;

/// Manager used to extract, delete and find content directory with.
@property (strong, nonatomic) BZRProductBundleManager *bundleManager;

/// Storage used to provide secure store/load of data.
@property (strong, nonatomic) BZRKeychainStorage *keychainStorage;

/// Provider used to provide \c BZRReceiptValidationStatus.
@property (strong, nonatomic) BZRReceiptValidationStatusProvider *validationStatusProvider;

/// Verifier used to verify that a user is allowed to use a certain product.
@property (strong, nonatomic) BZRProductEligibilityVerifier *eligibilityVerifier;

/// Provider used to provide a product's content.
@property (strong, nonatomic) BZRProductContentProvider *contentProvider;

@end

NS_ASSUME_NONNULL_END

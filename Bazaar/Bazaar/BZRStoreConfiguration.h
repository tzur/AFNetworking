// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRAcquiredViaSubscriptionProvider, BZRAggregatedReceiptValidationStatusProvider,
    BZRAllowedProductsProvider, BZRAppStoreLocaleProvider, BZRKeychainStorage,
    BZRPeriodicReceiptValidatorActivator, BZRProductContentManager,
    BZRStoreKitCachedMetadataFetcher, BZRStoreKitFacade, BZRValidatricksClient, LTPath;

@protocol BZRMultiAppSubscriptionClassifier, BZRProductsProvider, BZRProductContentFetcher,
    BZRProductsVariantSelectorFactory, BZRReceiptValidationParametersProvider, BZRUserIDProvider;

/// Object used to provide configuration objects for \c BZRStore.
@interface BZRStoreConfiguration : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the configuration with a single-app mode.
///
/// Initializes the in-app store configuration with Lightricks' default shared keychain access group
/// as provided by \c + [BZRKeychainStorage defaultSharedAccessGroup].
/// \c expiredSubscriptionGracePeriod is set to \c 7. \c applicationUserID is set to \c nil.
/// \c applicationBundleID is set to application's bundle identifier. \c bundledApplicationsIDs and
/// \c multiAppSubscriptionMarker are both set to \c nil.
///
/// @note In order to use the default shared keychain access group AppIdentifierPrefix has to be
/// defined in the application's main bundle plist, if it is not defined an
/// \c NSInternalInconsistencyException is raised.
- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                        productListDecryptionKey:(nullable NSString *)productListDecryptionKey
                                 useiCloudUserID:(BOOL)useiCloudUserID;

/// Initializes the configuration with a multi-app mode.
///
/// Initializes the in-app store configuration with Lightricks' default shared keychain access group
/// as provided by \c + [BZRKeychainStorage defaultSharedAccessGroup].
/// \c expiredSubscriptionGracePeriod is set to \c 7. \c applicationUserID is set to \c nil.
/// \c applicationBundleID is set to application's bundle identifier. The \c bundledApplicationsIDs
/// set is used to define applications that may provide multi-app subscription that enables features
/// in this application. The current application bundle ID is automatically added to this set if
/// it does not contain it already. The \c multiAppSubscriptionMarker will be used by the default
/// \c BZRMultiAppSubscriptionClassifier to identify multi-app subscription products.
///
/// @note In order to use the default shared keychain access group AppIdentifierPrefix has to be
/// defined in the application's main bundle plist, if it is not defined an
/// \c NSInternalInconsistencyException is raised.
- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                        productListDecryptionKey:(nullable NSString *)productListDecryptionKey
                          bundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs
                      multiAppSubscriptionMarker:(NSString *)multiAppSubscriptionMarker
                                 useiCloudUserID:(BOOL)useiCloudUserID;

/// Initializes the in-app store configuration with default parameters.
///
/// \c productsListJSONFilePath is used to load products information from.
///
/// \c productListDecryptionKey is the key used to decrypt the products JSON file. The key size must
/// be 32. If \c productListDecryptionKey is set to \c nil, the file is read without decryption.
///
/// \c keychainAccessGroup is the access group of the keychain storage used for storing sensitive
/// user data. If \c nil is provided the access group will default to the application's main bundle
/// identifier prefixed with the team ID.
///
/// \c expiredSubscriptionGracePeriod defines the number of days the user is allowed to use products
/// acquired via subscription after its subscription has expired.
///
/// \c applicationUserID is an optional unique identifier for the user's account, used for making
/// purchases and restoring transactions.
///
/// \c useiCloudUserID is a flag indicating whether Bazaar should fetch the unique identifier of
/// the user from iCloud. Passing \c YES in this flag without the appropriate entitlements will
/// result in an exception being raised.
///
/// \c productsProvider will be initialized with \c BZRCachedProductsProvider with the
/// given \c productsListJSONFilePath and \c fileManager.
///
/// \c contentManager will be initialized with the default parameters as provided by
/// \c -[BZRProductContentManager initWithFileManager:].
///
/// \c contentFetcher will be initialized with the default initializer.
///
/// \c BZRCachedReceiptValidationStatusProvider as provided by
/// \c -[BZRReceiptValidationStatusProvider initWithKeychainStorage:underlyingProvider:]
/// with a newly created \c BZRKeychainStorage and a newly created
/// \c BZRModifiedExpiryReceiptValidationStatusProvider.
///
/// \c acquiredViaSubscriptionProvider will be initialized with the default initializer of
/// \c BZRProductsAcquiredViaSubscriptionProvider as provided by
/// \c -[BZRProductsAcquiredViaSubscriptionProvider initWithKeychainStorage:] with the given
/// \c keychainStorage.
///
/// \c variantSelectorFactory is initialized with \c BZRDefaultVariantSelectorFactory.
///
/// \c storeKitFacade will be initialized using \c -[BZRStoreKitFacade initApplicationUseID:].
///
/// \c periodicValidatorActivator will be initialized with the default initializer of
/// \c BZRPeriodicReceiptValidatorActivator.
- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
    productListDecryptionKey:(nullable NSString *)productListDecryptionKey
    keychainAccessGroup:(nullable NSString *)keychainAccessGroup
    expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod
    applicationUserID:(nullable NSString *)applicationUserID
    applicationBundleID:(NSString *)applicationBundleID
    bundledApplicationsIDs:(nullable NSSet<NSString *> *)bundledApplicationsIDs
    multiAppSubscriptionClassifier:
    (nullable id<BZRMultiAppSubscriptionClassifier>)multiAppSubscriptionClassifier
    useiCloudUserID:(BOOL)useiCloudUserID NS_DESIGNATED_INITIALIZER;

/// Provider used to provide the list of products.
@property (strong, nonatomic) id<BZRProductsProvider> productsProvider;

/// Manager used to extract, delete and find content directory with.
@property (strong, nonatomic) BZRProductContentManager *contentManager;

/// Fetcher used to provide a product's content.
@property (strong, nonatomic) id<BZRProductContentFetcher> contentFetcher;

/// Provider used to provide the aggregated \c BZRReceiptValidationStatus.
@property (strong, nonatomic) BZRAggregatedReceiptValidationStatusProvider *
    validationStatusProvider;

/// Provider used to provide list of acquired via subsription products.
@property (strong, nonatomic) BZRAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;

/// Facade used to interact with Apple StoreKit.
@property (strong, nonatomic) BZRStoreKitFacade *storeKitFacade;

/// Fetcher used to fetch products metadata.
@property (strong, nonatomic) BZRStoreKitCachedMetadataFetcher *storeKitMetadataFetcher;

/// Provider used to provide the current user's App Store locale.
@property (strong, nonatomic) BZRAppStoreLocaleProvider *appStoreLocaleProvider;

/// Activator used to control the periodic receipt validation.
@property (strong, nonatomic) BZRPeriodicReceiptValidatorActivator *periodicValidatorActivator;

/// Factory used to create \c BZRProductsVariantSelector.
@property (strong, nonatomic) id<BZRProductsVariantSelectorFactory> variantSelectorFactory;

/// Provider used to provide products the user is allowed to use. By default it is initialized
/// with the nethermost \c productsProvider, with \c self.validationStatusProvider and with
/// \c self.acquiredViaSubscriptionProvider.
@property (strong, nonatomic) BZRAllowedProductsProvider *allowedProductsProvider;

/// Provider used to provide product list before getting their metadata from StoreKit.
@property (strong, nonatomic) id<BZRProductsProvider> netherProductsProvider;

/// Storage used to store and retrieve values from keychain storage.
@property (strong, nonatomic) BZRKeychainStorage *keychainStorage;

/// Client used to make HTTP requests to Validatricks.
@property (strong, nonatomic) BZRValidatricksClient *validatricksClient;

/// Provider used to provide a unique identifier of the user.
@property (strong, nonatomic) id<BZRUserIDProvider> userIDProvider;

/// An object used to identify multi-app subscription products.
@property (strong, nonatomic, nullable) id<BZRMultiAppSubscriptionClassifier>
    multiAppSubscriptionClassifier;

@end

NS_ASSUME_NONNULL_END

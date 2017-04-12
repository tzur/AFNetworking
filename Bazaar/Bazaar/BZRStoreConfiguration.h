// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRAcquiredViaSubscriptionProvider, BZRAllowedProductsProvider,
    BZRCachedReceiptValidationStatusProvider, BZRPeriodicReceiptValidatorActivator,
    BZRProductContentManager, BZRProductContentProvider, BZRStoreKitFacade, LTPath;

@protocol BZRProductsProvider, BZRProductsVariantSelectorFactory,
    BZRReceiptValidationParametersProvider;

/// Object used to provide configuration objects for \c BZRStore.
@interface BZRStoreConfiguration : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the in-app store configuration with a new instance of \c BZRKeychainStorage with
/// accessGroup set to \c nil. \c expiredSubscriptionGracePeriod is set to \c 7.
/// \c applicationUserID is set to \c nil. \c notValidatedReceiptGracePeriod is set to \c 5.
- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                     countryToTierDictionaryPath:(LTPath *)countryToTierDictionaryPath;

/// Initializes the in-app store configuration with default parameters. \c productsListJSONFilePath
/// is used to load products information from. \c countryToTierDictionaryPath is used to load
/// country to tier dictionary that is used to select products variants. \c keychainAccessGroup is a
/// key to storing/loading of data of a specific group from storage.
/// \c expiredSubscriptionGracePeriod defines the number of days the user is allowed to use products
/// acquired via subscription after its subscription has expired. \c applicationUserID is an
/// optional unique identifer for the user's account, used for making purchases and restoring
/// transactions. \c notValidatedReceiptGracePeriod determines the number of days the receipt can
/// remain not validated until subscription marked as expired.
///
/// \c productsProvider will be initialized with \c BZRCachedProductsProvider with the
/// given \c productsListJSONFilePath and \c fileManager.
///
/// \c contentManager will be initialized with the default parameters as provided by
/// \c -[BZRProductContentManager initWithFileManager:].
///
/// \c contentProvider will be initialized with
/// \c -[initWithContentFetcher:contentManager], with a new instance of \c BZRMultiContentFetcher
/// and with \c contentManager.
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
/// \c storeKitFacade will be initialized using \c -[BZRStoreKitFacade initApplicationUseID:].
///
/// \c periodicValidatorActivator will be initialized with the default initializer of
/// \c BZRPeriodicReceiptValidatorActivator.
- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                     countryToTierDictionaryPath:(LTPath *)countryToTierDictionaryPath
                             keychainAccessGroup:(nullable NSString *)keychainAccessGroup
                  expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod
                               applicationUserID:(nullable NSString *)applicationUserID
                  notValidatedReceiptGracePeriod:(NSUInteger)notValidatedReceiptGracePeriod
    NS_DESIGNATED_INITIALIZER;

/// Provider used to provide the list of products.
@property (strong, nonatomic) id<BZRProductsProvider> productsProvider;

/// Manager used to extract, delete and find content directory with.
@property (strong, nonatomic) BZRProductContentManager *contentManager;

/// Provider used to provide a product's content.
@property (strong, nonatomic) BZRProductContentProvider *contentProvider;

/// Provider used to provide \c BZRReceiptValidationStatus.
@property (strong, nonatomic) BZRCachedReceiptValidationStatusProvider *validationStatusProvider;

/// Provider used to provide list of acquired via subsription products.
@property (strong, nonatomic) BZRAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;

/// Facade used to interact with Apple StoreKit.
@property (strong, nonatomic) BZRStoreKitFacade *storeKitFacade;

/// Activator used to control the periodic receipt validation.
@property (strong, nonatomic) BZRPeriodicReceiptValidatorActivator *periodicValidatorActivator;

/// Factory used to create \c BZRProductsVariantSelector.
@property (strong, nonatomic) id<BZRProductsVariantSelectorFactory> variantSelectorFactory;

/// Provider used to provide validation parameters sent to the receipt validator.
@property (strong, nonatomic) id<BZRReceiptValidationParametersProvider>
    validationParametersProvider;

/// Provider used to provide products the user is allowed to use. By default it is initialized
/// with the nethermost \c productsProvider, with \c self.validationStatusProvider and with
/// \c self.acquiredViaSubscriptionProvider.
@property (strong, nonatomic) BZRAllowedProductsProvider *allowedProductsProvider;

@end

NS_ASSUME_NONNULL_END

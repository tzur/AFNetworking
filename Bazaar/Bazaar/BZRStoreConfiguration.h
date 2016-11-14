// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRAcquiredViaSubscriptionProvider, BZRCachedReceiptValidationStatusProvider,
    BZRPeriodicReceiptValidatorActivator, BZRProductContentManager, BZRProductContentProvider,
    BZRProductsProviderFactory, BZRStoreKitFacadeFactory, LTPath;

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
/// \c productsProviderFactory will be initialized with \c BZRLocalProductsProviderFactory with the
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
/// \c applicationReceiptBundle will be initialized with \c +[NSBunsdle mainBundle].
///
/// \c fileManager will be initialized with \c +[NSFileManager defaultManager].
///
/// \c storeKitFacadeFactory will be initialized using \c -[BZRStoreKitFacadeFactory init].
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

/// Factory used to create a concrete instance of \c BZRProductsProvider.
@property (strong, nonatomic) BZRProductsProviderFactory *productsProviderFactory;

/// Manager used to extract, delete and find content directory with.
@property (strong, nonatomic) BZRProductContentManager *contentManager;

/// Provider used to provide a product's content.
@property (strong, nonatomic) BZRProductContentProvider *contentProvider;

/// Provider used to provide \c BZRReceiptValidationStatus.
@property (strong, nonatomic) BZRCachedReceiptValidationStatusProvider *validationStatusProvider;

/// Provider used to provide list of acquired via subsription products.
@property (strong, nonatomic) BZRAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;

/// Bundle used to get the URL to the receipt.
@property (strong, nonatomic) NSBundle *applicationReceiptBundle;

/// Manager used to check if the URL to the receipt exists.
@property (strong, nonatomic) NSFileManager *fileManager;

/// Factory used to create \c BZRStoreKitFacade.
@property (strong, nonatomic) BZRStoreKitFacadeFactory *storeKitFacadeFactory;

/// Activator used to control the periodic receipt validation.
@property (strong, nonatomic) BZRPeriodicReceiptValidatorActivator *periodicValidatorActivator;

/// Factory used to create \c BZRProductsVariantSelector.
@property (strong, nonatomic) id<BZRProductsVariantSelectorFactory> variantSelectorFactory;

/// Provider used to provide validation parameters sent to the receipt validator.
@property (strong, nonatomic) id<BZRReceiptValidationParametersProvider>
    validationParametersProvider;

@end

NS_ASSUME_NONNULL_END

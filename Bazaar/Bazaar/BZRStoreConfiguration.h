// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRAcquiredViaSubscriptionProvider, BZRCachedReceiptValidationStatusProvider,
    BZRPeriodicReceiptValidatorActivator, BZRProductContentManager, BZRProductContentProvider,
    BZRStoreKitFacadeFactory, LTPath;

@protocol BZRProductsProvider;

/// Object used to provide configuration objects for \c BZRStore.
@interface BZRStoreConfiguration : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the in-app store configuration with a new instance of \c BZRKeychainStorage with
/// accessGroup set to \c nil. \c expiredSubscriptionGracePeriod is set to \c 7.
/// \c applicationUserID is set to \c nil. \c notValidatedReceiptGracePeriod is set to \c 5.
- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath;

/// Initializes the in-app store configuration with default parameters. \c productsListJSONFilePath
/// is used to load products information with. \c keychainAccessGroup is a key to storing/loading
/// of data of a specific group from storage. \c expiredSubscriptionGracePeriod defines the number
/// of days the user is allowed to use products acquired via subscription after its subscription has
/// expired. \c applicationUserID is an optional unique identifer for the user's account, used for
/// making purchases and restoring transactions. \c notValidatedReceiptGracePeriod determines the
/// number of days the receipt can remain not validated until subscription marked as expired.
///
/// \c productsProvider will be initialized with \c BZRLocalProductsProvider with the given
/// \c productsListJSONFilePath.
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
                             keychainAccessGroup:(nullable NSString *)keychainAccessGroup
                  expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod
                               applicationUserID:(nullable NSString *)applicationUserID
                  notValidatedReceiptGracePeriod:(NSUInteger)notValidatedReceiptGracePeriod
    NS_DESIGNATED_INITIALIZER;

/// Provider used to fetch product list.
@property (strong, nonatomic) id<BZRProductsProvider> productsProvider;

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

@end

NS_ASSUME_NONNULL_END

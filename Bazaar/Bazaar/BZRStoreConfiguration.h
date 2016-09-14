// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRAcquiredViaSubscriptionProvider, BZRProductContentManager, BZRProductContentProvider,
    BZRReceiptValidationStatusProvider, BZRStoreKitFacadeFactory, LTPath;

@protocol BZRProductsProvider;

/// Object used to provide configuration objects for \c BZRStore.
@interface BZRStoreConfiguration : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the in-app store configuration with a new instance of \c BZRKeychainStorage with
/// accessGroup set to \c nil, with \c expiredSubscriptionGracePeriod set to \c 7.
- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath;

/// Initializes the in-app store configuration with default parameters. \c productsListJSONFilePath
/// is used to load products information with. \c keychainAccessGroup is a key to storing/loading
/// of data of a specific group from storage. \c expiredSubscriptionGracePeriod defines the number
/// of days the user is allowed to use products acquired via subscription after its subscription has
/// expired.
///
/// \c productsProvider will be initialized with \c BZRLocalProductsProvider with the given
/// \c productsListJSONFilePath.
///
/// \c contentManager will be initialized with the default parameters as provided by
/// \c -[BZRProductContentManager init].
///
/// \c validationStatusProvider will be initialized with the default initializer of
/// \c BZRReceiptValidationStatusProvider as provided by
/// \c -[BZRReceiptValidationStatusProvider
/// initWithKeychainStorage:expiredSubscriptionGracePeriod:timeProvider]
/// with the given \c keychainStorage, \c expiredSubscriptionGracePeriod and a new instance of \c
/// BZRTimeProvider.
///
/// \c contentProvider will be initialized with
/// \c -[initWithContentFetcher:contentManager], with a new instance of \c BZRMultiContentFetcher
/// and with \c contentManager.
///
/// \c acquiredViaSubscriptionProvider will be initialized with the default initializer of
/// \c BZRProductsAcquiredViaSubscriptionProvider as provided by
/// \c -[BZRProductsAcquiredViaSubscriptionProvider initWithKeychainStorage:] with the given
/// \c keychainStorage.
///
/// \c storeKitFacadeFactory will be initialized using \c -[BZRStoreKitFacadeFactory init].
- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                             keychainAccessGroup:(nullable NSString *)keychainAccessGroup
                  expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod
    NS_DESIGNATED_INITIALIZER;

/// Provider used to fetch product list.
@property (strong, nonatomic) id<BZRProductsProvider> productsProvider;

/// Manager used to extract, delete and find content directory with.
@property (strong, nonatomic) BZRProductContentManager *contentManager;

/// Provider used to provide \c BZRReceiptValidationStatus.
@property (strong, nonatomic) BZRReceiptValidationStatusProvider *validationStatusProvider;

/// Provider used to provide a product's content.
@property (strong, nonatomic) BZRProductContentProvider *contentProvider;

/// Provider used to provide list of acquired via subsription products.
@property (strong, nonatomic) BZRAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;

/// Factory used to create \c BZRStoreKitFacade.
@property (strong, nonatomic) BZRStoreKitFacadeFactory *storeKitFacadeFactory;

@end

NS_ASSUME_NONNULL_END

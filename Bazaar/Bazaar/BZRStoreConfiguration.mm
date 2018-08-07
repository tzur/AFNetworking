// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreConfiguration.h"

#import <Fiber/FBRHTTPClient.h>
#import <LTKit/LTPath.h>

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRAggregatedReceiptValidationStatusProvider.h"
#import "BZRAllowedProductsProvider.h"
#import "BZRAppStoreLocaleCache.h"
#import "BZRAppStoreLocaleProvider.h"
#import "BZRCachedContentFetcher.h"
#import "BZRCachedProductsProvider.h"
#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRCloudKitAccountInfoProvider.h"
#import "BZRDeviceUserIDProvider.h"
#import "BZRKeychainStorage.h"
#import "BZRKeychainStorageRoute.h"
#import "BZRLocalProductsProvider.h"
#import "BZRLocaleBasedVariantSelectorFactory.h"
#import "BZRModifiedExpiryReceiptValidationStatusProvider.h"
#import "BZRMultiAppSubscriptionClassifier.h"
#import "BZRPeriodicReceiptValidatorActivator.h"
#import "BZRProductContentFetcher.h"
#import "BZRProductContentManager.h"
#import "BZRProductsVariantSelectorFactory.h"
#import "BZRProductsWithDiscountsProvider.h"
#import "BZRProductsWithPriceInfoProvider.h"
#import "BZRProductsWithVariantsProvider.h"
#import "BZRPurchaseHelper.h"
#import "BZRReceiptDataCache.h"
#import "BZRReceiptValidationDateProvider.h"
#import "BZRReceiptValidationParametersProvider.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRReceiptValidationStatusProvider.h"
#import "BZRStoreKitCachedMetadataFetcher.h"
#import "BZRStoreKitFacade.h"
#import "BZRStoreKitMetadataFetcher.h"
#import "BZRTimeProvider.h"
#import "BZRValidatedReceiptValidationStatusProvider.h"
#import "BZRValidatricksRobustClient.h"
#import "BZRValidatricksSessionConfigurationProvider.h"
#import "BZRiCloudUserIDProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRStoreConfiguration ()

/// Manager used to read and write files from the file system.
@property (strong, nonatomic) NSFileManager *fileManager;

/// Underlying fetcher used to fetch products metadata.
@property (readonly, nonatomic) BZRStoreKitMetadataFetcher *storeKitMetadataUnderlyingFetcher;

@end

@implementation BZRStoreConfiguration

/// Number of days the user is allowed to use products acquired via subscription after its
/// subscription has expired.
static const NSUInteger kExpiredSubscriptionGracePeriod = 7;

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                        productListDecryptionKey:(nullable NSString *)productListDecryptionKey
                                 useiCloudUserID:(BOOL)useiCloudUserID {
  return [self initWithProductsListJSONFilePath:productsListJSONFilePath
                       productListDecryptionKey:productListDecryptionKey
                            keychainAccessGroup:[BZRKeychainStorage defaultSharedAccessGroup]
                 expiredSubscriptionGracePeriod:kExpiredSubscriptionGracePeriod
                              applicationUserID:nil
                            applicationBundleID:[[NSBundle mainBundle] bundleIdentifier]
                         bundledApplicationsIDs:nil multiAppSubscriptionClassifier:nil
                                useiCloudUserID:useiCloudUserID];
}

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                        productListDecryptionKey:(nullable NSString *)productListDecryptionKey
                          bundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs
                      multiAppSubscriptionMarker:(NSString *)multiAppSubscriptionMarker
                                 useiCloudUserID:(BOOL)useiCloudUserID {
  auto applicationBundleID = [[NSBundle mainBundle] bundleIdentifier];
  auto multiAppSubscriptionClassifier =
      [[BZRMultiAppSubscriptionClassifier alloc]
       initWithMultiAppServiceLevelMarker:multiAppSubscriptionMarker];

  return [self initWithProductsListJSONFilePath:productsListJSONFilePath
                       productListDecryptionKey:productListDecryptionKey
                            keychainAccessGroup:[BZRKeychainStorage defaultSharedAccessGroup]
                 expiredSubscriptionGracePeriod:kExpiredSubscriptionGracePeriod
                              applicationUserID:nil
                            applicationBundleID:applicationBundleID
                         bundledApplicationsIDs:bundledApplicationsIDs
                 multiAppSubscriptionClassifier:multiAppSubscriptionClassifier
                                useiCloudUserID:useiCloudUserID];
}

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
    productListDecryptionKey:(nullable NSString *)productListDecryptionKey
    keychainAccessGroup:(nullable NSString *)keychainAccessGroup
    expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod
    applicationUserID:(nullable NSString *)applicationUserID
    applicationBundleID:(NSString *)applicationBundleID
    bundledApplicationsIDs:(nullable NSSet<NSString *> *)bundledApplicationsIDs
    multiAppSubscriptionClassifier:
    (nullable id<BZRMultiAppSubscriptionClassifier>)multiAppSubscriptionClassifier
    useiCloudUserID:(BOOL)useiCloudUserID {
  if (self = [super init]) {
    _fileManager = [NSFileManager defaultManager];
    _contentFetcher = [[BZRCachedContentFetcher alloc] init];
    _keychainStorage = [[BZRKeychainStorage alloc] initWithAccessGroup:keychainAccessGroup];
    _multiAppSubscriptionClassifier = multiAppSubscriptionClassifier;
    _variantSelectorFactory = [[BZRProductsVariantSelectorFactory alloc] init];
    _userIDProvider = useiCloudUserID ? [[BZRiCloudUserIDProvider alloc] init] :
        [[BZRDeviceUserIDProvider alloc] init];
    _validatricksClient = [[BZRValidatricksRobustClient alloc] init];

    auto relevantApplicationsBundleIDs = bundledApplicationsIDs ?
        [bundledApplicationsIDs setByAddingObject:applicationBundleID] :
        [NSSet setWithObject:applicationBundleID];
    auto purchaseHelper = [[BZRPurchaseHelper alloc] init];
    auto timeProvider = [[BZRTimeProvider alloc] init];

    auto keychainStorageRoute =
        [[BZRKeychainStorageRoute alloc] initWithAccessGroup:keychainAccessGroup
                                                serviceNames:relevantApplicationsBundleIDs];
    _storeKitFacade = [[BZRStoreKitFacade alloc] initWithApplicationUserID:applicationUserID
                                                            purchaseHelper:purchaseHelper];
    _contentManager = [[BZRProductContentManager alloc] initWithFileManager:self.fileManager];
    _acquiredViaSubscriptionProvider =
        [[BZRAcquiredViaSubscriptionProvider alloc] initWithKeychainStorage:self.keychainStorage];

    _storeKitMetadataUnderlyingFetcher =
        [[BZRStoreKitMetadataFetcher alloc] initWithStoreKitFacade:self.storeKitFacade];
    auto receiptDataCache =
        [[BZRReceiptDataCache alloc] initWithKeychainStorageRoute:keychainStorageRoute];
    auto receiptValidationStatusCache =
        [[BZRReceiptValidationStatusCache alloc] initWithKeychainStorage:keychainStorageRoute];
    auto appStoreLocaleCache =
        [[BZRAppStoreLocaleCache alloc] initWithKeychainStorageRoute:keychainStorageRoute];

    _storeKitMetadataFetcher =
        [[BZRStoreKitCachedMetadataFetcher alloc]
         initWithUnderlyingFetcher:self.storeKitMetadataUnderlyingFetcher];
    _productsProvider = [self productsProviderWithJSONFilePath:productsListJSONFilePath
                                                 decryptionKey:productListDecryptionKey];

    _appStoreLocaleProvider = [[BZRAppStoreLocaleProvider alloc]
                               initWithCache:appStoreLocaleCache
                               productsProvider:self.netherProductsProvider
                               metadataFetcher:self.storeKitMetadataUnderlyingFetcher
                               currentApplicationBundleID:applicationBundleID];

    auto validationParametersProvider =
        [[BZRReceiptValidationParametersProvider alloc]
         initWithAppStoreLocaleProvider:self.appStoreLocaleProvider
         receiptDataCache:receiptDataCache currentApplicationBundleID:applicationBundleID];

    auto validatorProvider =
        [[BZRValidatedReceiptValidationStatusProvider alloc]
         initWithValidatricksClient:self.validatricksClient
         validationParametersProvider:validationParametersProvider
         receiptDataCache:receiptDataCache
         userIDProvider:self.userIDProvider];

    auto modifiedExpiryProvider =
        [[BZRModifiedExpiryReceiptValidationStatusProvider alloc] initWithTimeProvider:timeProvider
         expiredSubscriptionGracePeriod:expiredSubscriptionGracePeriod
         underlyingProvider:validatorProvider];

    auto cachedReceiptValidationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:modifiedExpiryProvider
                                                  cachedEntryDaysToLive:60];

    // TODO: This code reverts invalidations that happened with previous time to live so that only
    // the latest time to live will take place. This code should run before loading from cache the
    // receipt validation status, therefore it is placed before the creation of \c
    // \c validationStatusProvider. In addition it should be removed in the future when most of the
    // invalidations with the previous time to live were reverted.
    for (NSString *relevantApplicationBundleID in relevantApplicationsBundleIDs) {
      [cachedReceiptValidationStatusProvider
       revertPrematureInvalidationOfReceiptValidationStatus:relevantApplicationBundleID];
    }

    _validationStatusProvider =
        [[BZRAggregatedReceiptValidationStatusProvider alloc]
         initWithUnderlyingProvider:cachedReceiptValidationStatusProvider
         currentApplicationBundleID:applicationBundleID
         bundleIDsForValidation:relevantApplicationsBundleIDs
         multiAppSubscriptionClassifier:multiAppSubscriptionClassifier];

    auto validationDateProvider =
        [[BZRReceiptValidationDateProvider alloc]
         initWithReceiptValidationStatusCache:receiptValidationStatusCache
         receiptValidationStatusProvider:self.validationStatusProvider
         bundledApplicationsIDs:relevantApplicationsBundleIDs validationIntervalDays:14];
    _periodicValidatorActivator =
        [[BZRPeriodicReceiptValidatorActivator alloc]
         initWithAggregatedValidationStatusProvider:self.validationStatusProvider
                             validationDateProvider:validationDateProvider
                                       timeProvider:timeProvider];

    _allowedProductsProvider =
        [[BZRAllowedProductsProvider alloc] initWithProductsProvider:self.netherProductsProvider
         validationStatusProvider:self.validationStatusProvider
         acquiredViaSubscriptionProvider:self.acquiredViaSubscriptionProvider];

    purchaseHelper.aggregatedReceiptProvider = self.validationStatusProvider;
  }
  return self;
}

- (id<BZRProductsProvider>)productsProviderWithJSONFilePath:(LTPath *)productsListJSONFilePath
                                              decryptionKey:(nullable NSString *)decryptionKey {
  auto localProductsProvider = [[BZRLocalProductsProvider alloc]
                                initWithPath:productsListJSONFilePath decryptionKey:decryptionKey
                                fileManager:self.fileManager];
  auto productsWithDiscountsProvider = [[BZRProductsWithDiscountsProvider alloc]
                                        initWithUnderlyingProvider:localProductsProvider];
  _netherProductsProvider = [[BZRProductsWithVariantsProvider alloc]
                             initWithUnderlyingProvider:productsWithDiscountsProvider];
  auto productsWithPriceInfoProvider =
      [[BZRProductsWithPriceInfoProvider alloc]
       initWithUnderlyingProvider:self.netherProductsProvider
       storeKitMetadataFetcher:self.storeKitMetadataUnderlyingFetcher];
  return [[BZRCachedProductsProvider alloc]
          initWithUnderlyingProvider:productsWithPriceInfoProvider];
}

@end

NS_ASSUME_NONNULL_END

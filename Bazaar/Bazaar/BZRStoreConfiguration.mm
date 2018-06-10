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
#import "BZRReceiptValidationParametersProvider.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRReceiptValidationStatusProvider.h"
#import "BZRStoreKitCachedMetadataFetcher.h"
#import "BZRStoreKitFacade.h"
#import "BZRStoreKitMetadataFetcher.h"
#import "BZRTimeProvider.h"
#import "BZRValidatedReceiptValidationStatusProvider.h"
#import "BZRValidatricksClient.h"
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
                        productListDecryptionKey:(nullable NSString *)productListDecryptionKey {
  return [self initWithProductsListJSONFilePath:productsListJSONFilePath
                       productListDecryptionKey:productListDecryptionKey
                            keychainAccessGroup:[BZRKeychainStorage defaultSharedAccessGroup]
                 expiredSubscriptionGracePeriod:kExpiredSubscriptionGracePeriod
                              applicationUserID:nil
                            applicationBundleID:[[NSBundle mainBundle] bundleIdentifier]
                         bundledApplicationsIDs:nil multiAppSubscriptionClassifier:nil];
}

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                        productListDecryptionKey:(nullable NSString *)productListDecryptionKey
                          bundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs
                      multiAppSubscriptionMarker:(NSString *)multiAppSubscriptionMarker {
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
                 multiAppSubscriptionClassifier:multiAppSubscriptionClassifier];
}

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
    productListDecryptionKey:(nullable NSString *)productListDecryptionKey
    keychainAccessGroup:(nullable NSString *)keychainAccessGroup
    expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod
    applicationUserID:(nullable NSString *)applicationUserID
    applicationBundleID:(NSString *)applicationBundleID
    bundledApplicationsIDs:(nullable NSSet<NSString *> *)bundledApplicationsIDs
    multiAppSubscriptionClassifier:
    (nullable id<BZRMultiAppSubscriptionClassifier>)multiAppSubscriptionClassifier {
  if (self = [super init]) {
    _fileManager = [NSFileManager defaultManager];
    _contentFetcher = [[BZRCachedContentFetcher alloc] init];
    _keychainStorage = [[BZRKeychainStorage alloc] initWithAccessGroup:keychainAccessGroup];
    _multiAppSubscriptionClassifier = multiAppSubscriptionClassifier;
    _variantSelectorFactory = [[BZRProductsVariantSelectorFactory alloc] init];
    _userIDProvider = [[BZRiCloudUserIDProvider alloc] init];

    auto validatricksBaseURL = [NSURL URLWithString:@"https://api.lightricks.com/store/v1/"];
    auto sessionConfigurationProvider = [[BZRValidatricksSessionConfigurationProvider alloc] init];
    auto HTTPClient = [FBRHTTPClient
        clientWithSessionConfiguration:[sessionConfigurationProvider HTTPSessionConfiguration]
                               baseURL:validatricksBaseURL];
    _validatricksClient = [[BZRValidatricksClient alloc] initWithHTTPClient:HTTPClient];

    auto relevantApplicationsBundleIDs = bundledApplicationsIDs ?
        [bundledApplicationsIDs setByAddingObject:applicationBundleID] :
        [NSSet setWithObject:applicationBundleID];
    auto purchaseHelper = [[BZRPurchaseHelper alloc] init];
    auto timeProvider = [[BZRTimeProvider alloc] init];

    BZRKeychainStorageRoute *keychainStorageRoute =
        [[BZRKeychainStorageRoute alloc] initWithAccessGroup:keychainAccessGroup
                                                serviceNames:relevantApplicationsBundleIDs];
    _storeKitFacade = [[BZRStoreKitFacade alloc] initWithApplicationUserID:applicationUserID
                                                            purchaseHelper:purchaseHelper];
    _contentManager = [[BZRProductContentManager alloc] initWithFileManager:self.fileManager];
    _acquiredViaSubscriptionProvider =
        [[BZRAcquiredViaSubscriptionProvider alloc] initWithKeychainStorage:self.keychainStorage];

    _storeKitMetadataUnderlyingFetcher =
        [[BZRStoreKitMetadataFetcher alloc] initWithStoreKitFacade:self.storeKitFacade];
    BZRReceiptDataCache *receiptDataCache =
        [[BZRReceiptDataCache alloc] initWithKeychainStorageRoute:keychainStorageRoute];
    BZRReceiptValidationStatusCache *receiptValidationStatusCache =
        [[BZRReceiptValidationStatusCache alloc] initWithKeychainStorage:keychainStorageRoute];
    BZRAppStoreLocaleCache *appStoreLocaleCache =
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

    BZRValidatedReceiptValidationStatusProvider *validatorProvider =
        [[BZRValidatedReceiptValidationStatusProvider alloc]
         initWithValidationParametersProvider:validationParametersProvider
         receiptDataCache:receiptDataCache userIDProvider:self.userIDProvider];

    BZRModifiedExpiryReceiptValidationStatusProvider *modifiedExpiryProvider =
        [[BZRModifiedExpiryReceiptValidationStatusProvider alloc] initWithTimeProvider:timeProvider
         expiredSubscriptionGracePeriod:expiredSubscriptionGracePeriod
         underlyingProvider:validatorProvider];

    auto cachedReceiptValidationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:modifiedExpiryProvider];

    _validationStatusProvider =
        [[BZRAggregatedReceiptValidationStatusProvider alloc]
         initWithUnderlyingProvider:cachedReceiptValidationStatusProvider
         currentApplicationBundleID:applicationBundleID
         bundleIDsForValidation:relevantApplicationsBundleIDs
         multiAppSubscriptionClassifier:multiAppSubscriptionClassifier];

    _periodicValidatorActivator =
        [[BZRPeriodicReceiptValidatorActivator alloc]
         initWithReceiptValidationStatusCache:receiptValidationStatusCache
         timeProvider:timeProvider bundledApplicationsIDs:relevantApplicationsBundleIDs
         aggregatedValidationStatusProvider:self.validationStatusProvider];
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

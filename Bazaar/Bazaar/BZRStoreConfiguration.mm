// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreConfiguration.h"

#import <LTKit/LTPath.h>

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRAggregatedReceiptValidationStatusProvider.h"
#import "BZRAllowedProductsProvider.h"
#import "BZRAppStoreLocaleCache.h"
#import "BZRCachedContentFetcher.h"
#import "BZRCachedProductsProvider.h"
#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRKeychainStorage.h"
#import "BZRKeychainStorageRoute.h"
#import "BZRLocalProductsProvider.h"
#import "BZRLocaleBasedVariantSelectorFactory.h"
#import "BZRModifiedExpiryReceiptValidationStatusProvider.h"
#import "BZRMultiAppConfiguration.h"
#import "BZRPeriodicReceiptValidatorActivator.h"
#import "BZRProductContentFetcher.h"
#import "BZRProductContentManager.h"
#import "BZRProductsPriceInfoFetcher.h"
#import "BZRProductsVariantSelectorFactory.h"
#import "BZRProductsWithDiscountsProvider.h"
#import "BZRProductsWithPriceInfoProvider.h"
#import "BZRProductsWithVariantsProvider.h"
#import "BZRReceiptDataCache.h"
#import "BZRReceiptValidationParametersProvider.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRReceiptValidationStatusProvider.h"
#import "BZRStoreKitFacade.h"
#import "BZRTimeProvider.h"
#import "BZRValidatedReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRStoreConfiguration ()

/// Manager used to read and write files from the file system.
@property (strong, nonatomic) NSFileManager *fileManager;

@end

@implementation BZRStoreConfiguration

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                        productListDecryptionKey:(nullable NSString *)productListDecryptionKey {
  /// Number of days the user is allowed to use products acquired via subscription after its
  /// subscription has expired.
  static const NSUInteger kExpiredSubscriptionGracePeriod = 7;

  return [self initWithProductsListJSONFilePath:productsListJSONFilePath
                       productListDecryptionKey:productListDecryptionKey
                            keychainAccessGroup:[BZRKeychainStorage defaultSharedAccessGroup]
                 expiredSubscriptionGracePeriod:kExpiredSubscriptionGracePeriod
                              applicationUserID:nil
                            applicationBundleID:[[NSBundle mainBundle] bundleIdentifier]
                          multiAppConfiguration:nil];
}

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                        productListDecryptionKey:(nullable NSString *)productListDecryptionKey
                          bundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs
                      multiAppSubscriptionMarker:(NSString *)multiAppSubscriptionMarker {
  /// Number of days the user is allowed to use products acquired via subscription after its
  /// subscription has expired.
  static const NSUInteger kExpiredSubscriptionGracePeriod = 7;

  auto applicationBundleID = [[NSBundle mainBundle] bundleIdentifier];
  auto multiAppConfiguration =
      [[BZRMultiAppConfiguration alloc]
       initWithBundledApplicationsIDs:[bundledApplicationsIDs setByAddingObject:applicationBundleID]
       multiAppSubscriptionIdentifierMarker:multiAppSubscriptionMarker];
  return [self initWithProductsListJSONFilePath:productsListJSONFilePath
                       productListDecryptionKey:productListDecryptionKey
                            keychainAccessGroup:[BZRKeychainStorage defaultSharedAccessGroup]
                 expiredSubscriptionGracePeriod:kExpiredSubscriptionGracePeriod
                              applicationUserID:nil
                            applicationBundleID:applicationBundleID
                          multiAppConfiguration:multiAppConfiguration];
}

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
    productListDecryptionKey:(nullable NSString *)productListDecryptionKey
    keychainAccessGroup:(nullable NSString *)keychainAccessGroup
    expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod
    applicationUserID:(nullable NSString *)applicationUserID
    applicationBundleID:(NSString *)applicationBundleID
    multiAppConfiguration:(nullable BZRMultiAppConfiguration *)multiAppConfiguration {
  if (self = [super init]) {
    _fileManager = [NSFileManager defaultManager];

    _contentManager = [[BZRProductContentManager alloc] initWithFileManager:self.fileManager];
    _contentFetcher = [[BZRCachedContentFetcher alloc] init];

    _keychainStorage =
        [[BZRKeychainStorage alloc] initWithAccessGroup:keychainAccessGroup];
    BZRTimeProvider *timeProvider = [[BZRTimeProvider alloc] init];

    auto bundledApplicationsID = multiAppConfiguration.bundledApplicationsIDs ?
        multiAppConfiguration.bundledApplicationsIDs : [NSSet setWithObject:applicationBundleID];
    BZRKeychainStorageRoute *keychainStorageRoute =
        [[BZRKeychainStorageRoute alloc] initWithAccessGroup:keychainAccessGroup
                                                serviceNames:bundledApplicationsID];
    BZRReceiptDataCache *receiptDataCache =
        [[BZRReceiptDataCache alloc] initWithKeychainStorageRoute:keychainStorageRoute];

    BZRAppStoreLocaleCache *appStoreLocaleCache =
        [[BZRAppStoreLocaleCache alloc] initWithKeychainStorageRoute:keychainStorageRoute];
    _validationParametersProvider =
        [[BZRReceiptValidationParametersProvider alloc]
         initWithAppStoreLocaleCache:appStoreLocaleCache receiptDataCache:receiptDataCache
         currentApplicationBundleID:applicationBundleID];

    BZRValidatedReceiptValidationStatusProvider *validatorProvider =
        [[BZRValidatedReceiptValidationStatusProvider alloc]
         initWithValidationParametersProvider:self.validationParametersProvider
         receiptDataCache:receiptDataCache];

    BZRModifiedExpiryReceiptValidationStatusProvider *modifiedExpiryProvider =
        [[BZRModifiedExpiryReceiptValidationStatusProvider alloc] initWithTimeProvider:timeProvider
         expiredSubscriptionGracePeriod:expiredSubscriptionGracePeriod
         underlyingProvider:validatorProvider];

    BZRReceiptValidationStatusCache *receiptValidationStatusCache =
        [[BZRReceiptValidationStatusCache alloc] initWithKeychainStorage:keychainStorageRoute];

     auto cacheReceiptValidationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:modifiedExpiryProvider];
    _acquiredViaSubscriptionProvider =
        [[BZRAcquiredViaSubscriptionProvider alloc] initWithKeychainStorage:self.keychainStorage];

    _storeKitFacade = [[BZRStoreKitFacade alloc] initWithApplicationUserID:applicationUserID];
    _priceInfoFetcher =
        [[BZRProductsPriceInfoFetcher alloc] initWithStoreKitFacade:self.storeKitFacade];
    _productsProvider = [self productsProviderWithJSONFilePath:productsListJSONFilePath
                                                 decryptionKey:productListDecryptionKey];

    auto multiAppConfigurationWithCurrentApplication =
        [[BZRMultiAppConfiguration alloc] initWithBundledApplicationsIDs:bundledApplicationsID
         multiAppSubscriptionIdentifierMarker:
         multiAppConfiguration.multiAppSubscriptionIdentifierMarker];
    _validationStatusProvider =
        [[BZRAggregatedReceiptValidationStatusProvider alloc]
         initWithUnderlyingProvider:cacheReceiptValidationStatusProvider
         currentApplicationBundleID:applicationBundleID
         multiAppConfiguration:multiAppConfigurationWithCurrentApplication];

    _periodicValidatorActivator =
        [[BZRPeriodicReceiptValidatorActivator alloc]
         initWithValidationStatusProvider:cacheReceiptValidationStatusProvider
         timeProvider:timeProvider bundledApplicationsIDs:bundledApplicationsID
         aggregatedValidationStatusProvider:self.validationStatusProvider];

    _variantSelectorFactory = [[BZRProductsVariantSelectorFactory alloc] init];

    _allowedProductsProvider =
        [[BZRAllowedProductsProvider alloc] initWithProductsProvider:self.netherProductsProvider
         validationStatusProvider:self.validationStatusProvider
         acquiredViaSubscriptionProvider:self.acquiredViaSubscriptionProvider];
  }
  return self;
}

- (id<BZRProductsProvider>)productsProviderWithJSONFilePath:(LTPath *)productsListJSONFilePath
                                              decryptionKey:(nullable NSString *)decryptionKey {
    BZRLocalProductsProvider *localProductsProvider =
        [[BZRLocalProductsProvider alloc] initWithPath:productsListJSONFilePath
                                         decryptionKey:decryptionKey
                                           fileManager:self.fileManager];
    BZRProductsWithDiscountsProvider *productsWithDiscountsProvider =
        [[BZRProductsWithDiscountsProvider alloc]
         initWithUnderlyingProvider:localProductsProvider];
    _netherProductsProvider =
        [[BZRProductsWithVariantsProvider alloc]
         initWithUnderlyingProvider:productsWithDiscountsProvider];
    BZRProductsWithPriceInfoProvider *productsWithPriceInfoProvider =
        [[BZRProductsWithPriceInfoProvider alloc]
         initWithUnderlyingProvider:self.netherProductsProvider
         priceInfoFetcher:self.priceInfoFetcher];
    return [[BZRCachedProductsProvider alloc]
            initWithUnderlyingProvider:productsWithPriceInfoProvider];
}

@end

NS_ASSUME_NONNULL_END

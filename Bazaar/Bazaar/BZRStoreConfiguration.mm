// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreConfiguration.h"

#import <LTKit/LTPath.h>

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRAllowedProductsProvider.h"
#import "BZRCachedContentFetcher.h"
#import "BZRCachedProductsProvider.h"
#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRKeychainStorage.h"
#import "BZRKeychainStorageRoute.h"
#import "BZRLocalProductsProvider.h"
#import "BZRLocaleBasedVariantSelectorFactory.h"
#import "BZRModifiedExpiryReceiptValidationStatusProvider.h"
#import "BZRPeriodicReceiptValidatorActivator.h"
#import "BZRProductContentFetcher.h"
#import "BZRProductContentManager.h"
#import "BZRProductsVariantSelectorFactory.h"
#import "BZRProductsWithDiscountsProvider.h"
#import "BZRProductsWithPriceInfoProvider.h"
#import "BZRProductsWithVariantsProvider.h"
#import "BZRReceiptValidationParametersProvider.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRReceiptValidationStatusProvider.h"
#import "BZRStoreKitFacade.h"
#import "BZRStoreKitMetadataFetcher.h"
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

  /// Number of days the receipt can remain not validated until subscription marked as expired.
  static const NSUInteger kNotValidatedGracePeriod = 5;

  return [self initWithProductsListJSONFilePath:productsListJSONFilePath
                       productListDecryptionKey:productListDecryptionKey
                            keychainAccessGroup:[BZRKeychainStorage defaultSharedAccessGroup]
                 expiredSubscriptionGracePeriod:kExpiredSubscriptionGracePeriod
                              applicationUserID:nil
                 notValidatedReceiptGracePeriod:kNotValidatedGracePeriod
                            applicationBundleID:[[NSBundle mainBundle] bundleIdentifier]];
}

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                        productListDecryptionKey:(nullable NSString *)productListDecryptionKey
                             keychainAccessGroup:(nullable NSString *)keychainAccessGroup
                  expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod
                               applicationUserID:(nullable NSString *)applicationUserID
                  notValidatedReceiptGracePeriod:(NSUInteger)notValidatedReceiptGracePeriod
                             applicationBundleID:(NSString *)applicationBundleID {
  if (self = [super init]) {
    _fileManager = [NSFileManager defaultManager];

    _contentManager = [[BZRProductContentManager alloc] initWithFileManager:self.fileManager];
    _contentFetcher = [[BZRCachedContentFetcher alloc] init];

    BZRKeychainStorage *keychainStorage =
        [[BZRKeychainStorage alloc] initWithAccessGroup:keychainAccessGroup];
    _validationParametersProvider =
        [[BZRReceiptValidationParametersProvider alloc]
         initWithKeychainStorage:keychainStorage];
    BZRTimeProvider *timeProvider = [[BZRTimeProvider alloc] init];
    BZRValidatedReceiptValidationStatusProvider *validatorProvider =
        [[BZRValidatedReceiptValidationStatusProvider alloc]
         initWithValidationParametersProvider:self.validationParametersProvider];
    BZRModifiedExpiryReceiptValidationStatusProvider *modifiedExpiryProvider =
        [[BZRModifiedExpiryReceiptValidationStatusProvider alloc] initWithTimeProvider:timeProvider
         expiredSubscriptionGracePeriod:expiredSubscriptionGracePeriod
         underlyingProvider:validatorProvider];

    BZRKeychainStorageRoute *keychainStorageRoute =
        [[BZRKeychainStorageRoute alloc] initWithAccessGroup:keychainAccessGroup
                                                serviceNames:@[applicationBundleID].lt_set];

    BZRReceiptValidationStatusCache *receiptValidationStatusCache =
        [[BZRReceiptValidationStatusCache alloc] initWithKeychainStorage:keychainStorageRoute];

    _validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:modifiedExpiryProvider
                                                    applicationBundleID:applicationBundleID];
    _acquiredViaSubscriptionProvider =
        [[BZRAcquiredViaSubscriptionProvider alloc] initWithKeychainStorage:keychainStorage];

    _storeKitFacade = [[BZRStoreKitFacade alloc] initWithApplicationUserID:applicationUserID];
    _storeKitMetadataFetcher =
        [[BZRStoreKitMetadataFetcher alloc] initWithStoreKitFacade:self.storeKitFacade];
    _productsProvider = [self productsProviderWithJSONFilePath:productsListJSONFilePath
                                                 decryptionKey:productListDecryptionKey];

    _periodicValidatorActivator =
        [[BZRPeriodicReceiptValidatorActivator alloc]
         initWithValidationStatusProvider:self.validationStatusProvider timeProvider:timeProvider
         gracePeriod:notValidatedReceiptGracePeriod];

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
    auto localProductsProvider = [[BZRLocalProductsProvider alloc]
                                  initWithPath:productsListJSONFilePath decryptionKey:decryptionKey
                                  fileManager:self.fileManager];
    auto productsWithDiscountsProvider = [[BZRProductsWithDiscountsProvider alloc]
                                          initWithUnderlyingProvider:localProductsProvider];
    _netherProductsProvider = [[BZRProductsWithVariantsProvider alloc]
                               initWithUnderlyingProvider:productsWithDiscountsProvider];
    auto productsWithPriceInfoProvider = [[BZRProductsWithPriceInfoProvider alloc]
                                          initWithUnderlyingProvider:self.netherProductsProvider
                                          storeKitMetadataFetcher:self.storeKitMetadataFetcher];
    return [[BZRCachedProductsProvider alloc]
            initWithUnderlyingProvider:productsWithPriceInfoProvider];
}

@end

NS_ASSUME_NONNULL_END

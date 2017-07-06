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
#import "BZRLocalProductsProvider.h"
#import "BZRLocaleBasedVariantSelectorFactory.h"
#import "BZRModifiedExpiryReceiptValidationStatusProvider.h"
#import "BZRPeriodicReceiptValidatorActivator.h"
#import "BZRProductContentFetcher.h"
#import "BZRProductContentManager.h"
#import "BZRProductsWithDiscountsProvider.h"
#import "BZRProductsWithPriceInfoProvider.h"
#import "BZRProductsWithVariantsProvider.h"
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
                     countryToTierDictionaryPath:(LTPath *)countryToTierDictionaryPath {
  /// Number of days the user is allowed to use products acquired via subscription after its
  /// subscription has expired.
  static const NSUInteger kExpiredSubscriptionGracePeriod = 7;

  /// Number of days the receipt can remain not validated until subscription marked as expired.
  static const NSUInteger kNotValidatedGracePeriod = 5;

  return [self initWithProductsListJSONFilePath:productsListJSONFilePath
                    countryToTierDictionaryPath:countryToTierDictionaryPath
                            keychainAccessGroup:[BZRKeychainStorage defaultSharedAccessGroup]
                 expiredSubscriptionGracePeriod:kExpiredSubscriptionGracePeriod
                              applicationUserID:nil
                 notValidatedReceiptGracePeriod:kNotValidatedGracePeriod];
}

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                     countryToTierDictionaryPath:(LTPath *)countryToTierDictionaryPath
                             keychainAccessGroup:(nullable NSString *)keychainAccessGroup
                  expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod
                               applicationUserID:(nullable NSString *)applicationUserID
                  notValidatedReceiptGracePeriod:(NSUInteger)notValidatedReceiptGracePeriod {
  if (self = [super init]) {
    _fileManager = [NSFileManager defaultManager];

    _contentManager = [[BZRProductContentManager alloc] initWithFileManager:self.fileManager];
    _contentFetcher = [[BZRCachedContentFetcher alloc] init];

    _validationParametersProvider = [[BZRReceiptValidationParametersProvider alloc] init];
    BZRTimeProvider *timeProvider = [[BZRTimeProvider alloc] init];
    BZRValidatedReceiptValidationStatusProvider *validatorProvider =
        [[BZRValidatedReceiptValidationStatusProvider alloc]
         initWithValidationParametersProvider:self.validationParametersProvider];
    BZRModifiedExpiryReceiptValidationStatusProvider *modifiedExpiryProvider =
        [[BZRModifiedExpiryReceiptValidationStatusProvider alloc] initWithTimeProvider:timeProvider
         expiredSubscriptionGracePeriod:expiredSubscriptionGracePeriod
         underlyingProvider:validatorProvider];

    BZRKeychainStorage *keychainStorage =
        [[BZRKeychainStorage alloc] initWithAccessGroup:keychainAccessGroup];
    BZRReceiptValidationStatusCache *receiptValidationStatusCache =
        [[BZRReceiptValidationStatusCache alloc] initWithKeychainStorage:keychainStorage];

    _validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:modifiedExpiryProvider];
    _acquiredViaSubscriptionProvider =
        [[BZRAcquiredViaSubscriptionProvider alloc] initWithKeychainStorage:keychainStorage];

    _storeKitFacade = [[BZRStoreKitFacade alloc] initWithApplicationUserID:applicationUserID];
    _productsProvider = [self productsProviderWithJSONFilePath:productsListJSONFilePath];

    _periodicValidatorActivator =
        [[BZRPeriodicReceiptValidatorActivator alloc]
         initWithValidationStatusProvider:self.validationStatusProvider timeProvider:timeProvider
         gracePeriod:notValidatedReceiptGracePeriod];

    _variantSelectorFactory =
        [[BZRLocaleBasedVariantSelectorFactory alloc] initWithFileManager:self.fileManager
         countryToTierPath:countryToTierDictionaryPath];

    _allowedProductsProvider =
        [[BZRAllowedProductsProvider alloc] initWithProductsProvider:self.netherProductsProvider
         validationStatusProvider:self.validationStatusProvider
         acquiredViaSubscriptionProvider:self.acquiredViaSubscriptionProvider];
  }
  return self;
}

- (id<BZRProductsProvider>)productsProviderWithJSONFilePath:(LTPath *)productsListJSONFilePath {
    BZRLocalProductsProvider *localProductsProvider =
        [[BZRLocalProductsProvider alloc] initWithPath:productsListJSONFilePath
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
         storeKitFacade:self.storeKitFacade];
    return [[BZRCachedProductsProvider alloc]
            initWithUnderlyingProvider:productsWithPriceInfoProvider];
}

@end

NS_ASSUME_NONNULL_END

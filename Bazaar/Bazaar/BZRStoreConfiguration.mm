// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreConfiguration.h"

#import <LTKit/LTPath.h>

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRKeychainStorage.h"
#import "BZRLocaleBasedVariantSelectorFactory.h"
#import "BZRModifiedExpiryReceiptValidationStatusProvider.h"
#import "BZRPeriodicReceiptValidator.h"
#import "BZRPeriodicReceiptValidatorActivator.h"
#import "BZRProductContentFetcher.h"
#import "BZRProductContentManager.h"
#import "BZRProductContentMultiFetcher.h"
#import "BZRProductContentProvider.h"
#import "BZRProductsProviderFactory.h"
#import "BZRProductsWithDiscountsProvider.h"
#import "BZRProductsWithVariantsProvider.h"
#import "BZRReceiptValidationParametersProvider.h"
#import "BZRReceiptValidationStatusProvider.h"
#import "BZRStoreKitFacadeFactory.h"
#import "BZRTimeProvider.h"
#import "BZRValidatedReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRStoreConfiguration

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                     countryToTierDictionaryPath:(LTPath *)countryToTierDictionaryPath {
  /// Number of days the user is allowed to use products acquired via subscription after its
  /// subscription has expired.
  static const NSUInteger kExpiredSubscriptionGracePeriod = 7;

  /// Number of days the receipt can remain not validated until subscription marked as expired.
  static const NSUInteger kNotValidatedGracePeriod = 5;

  return [self initWithProductsListJSONFilePath:productsListJSONFilePath
                    countryToTierDictionaryPath:countryToTierDictionaryPath keychainAccessGroup:nil
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

    _productsProviderFactory =
        [[BZRProductsProviderFactory alloc]
         initWithProductsListJSONFilePath:productsListJSONFilePath fileManager:self.fileManager];

    _contentManager = [[BZRProductContentManager alloc] initWithFileManager:self.fileManager];
    BZRProductContentMultiFetcher *contentFetcher = [[BZRProductContentMultiFetcher alloc] init];
    _contentProvider =
        [[BZRProductContentProvider alloc] initWithContentFetcher:contentFetcher
                                                   contentManager:self.contentManager];

    _validationParametersProvider = [[BZRReceiptValidationParametersProvider alloc] init];

    BZRKeychainStorage *keychainStorage =
        [[BZRKeychainStorage alloc] initWithAccessGroup:keychainAccessGroup];
    BZRTimeProvider *timeProvider = [[BZRTimeProvider alloc] init];
    BZRValidatedReceiptValidationStatusProvider *validatorProvider =
        [[BZRValidatedReceiptValidationStatusProvider alloc]
         initWithValidationParametersProvider:self.validationParametersProvider];
    BZRModifiedExpiryReceiptValidationStatusProvider *modifiedExpiryProvider =
        [[BZRModifiedExpiryReceiptValidationStatusProvider alloc] initWithTimeProvider:timeProvider
         expiredSubscriptionGracePeriod:expiredSubscriptionGracePeriod
         underlyingProvider:validatorProvider];
    _validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithKeychainStorage:keychainStorage
         timeProvider:timeProvider underlyingProvider:modifiedExpiryProvider];

    _acquiredViaSubscriptionProvider =
        [[BZRAcquiredViaSubscriptionProvider alloc] initWithKeychainStorage:keychainStorage];
    _applicationReceiptBundle = [NSBundle mainBundle];
    _storeKitFacadeFactory =
        [[BZRStoreKitFacadeFactory alloc] initWithApplicationUserID:applicationUserID];

    BZRPeriodicReceiptValidator *periodicReceiptValidator =
        [[BZRPeriodicReceiptValidator alloc]
         initWithReceiptValidationProvider:self.validationStatusProvider];
    _periodicValidatorActivator =
        [[BZRPeriodicReceiptValidatorActivator alloc]
         initWithPeriodicReceiptValidator:periodicReceiptValidator
         validationStatusProvider:self.validationStatusProvider timeProvider:timeProvider
         gracePeriod:notValidatedReceiptGracePeriod];

    _variantSelectorFactory =
        [[BZRLocaleBasedVariantSelectorFactory alloc] initWithFileManager:self.fileManager
         countryToTierPath:countryToTierDictionaryPath];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END

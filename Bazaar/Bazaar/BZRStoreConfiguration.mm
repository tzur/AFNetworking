// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreConfiguration.h"

#import <LTKit/LTPath.h>

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRKeychainStorage.h"
#import "BZRLocalProductsProvider.h"
#import "BZRModifiedExpiryReceiptValidationStatusProvider.h"
#import "BZRProductContentFetcher.h"
#import "BZRProductContentManager.h"
#import "BZRProductContentMultiFetcher.h"
#import "BZRProductContentProvider.h"
#import "BZRReceiptValidationStatusProvider.h"
#import "BZRStoreKitFacadeFactory.h"
#import "BZRTimeProvider.h"
#import "BZRValidatedReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRStoreConfiguration

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath {
  return [self initWithProductsListJSONFilePath:productsListJSONFilePath keychainAccessGroup:nil
                 expiredSubscriptionGracePeriod:7 applicationUserID:nil];
}

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath
                             keychainAccessGroup:(nullable NSString *)keychainAccessGroup
                  expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod
                               applicationUserID:(nullable NSString *)applicationUserID {
  if (self = [super init]) {
    _fileManager = [NSFileManager defaultManager];
    _productsProvider =
        [[BZRLocalProductsProvider alloc] initWithPath:productsListJSONFilePath
                                           fileManager:self.fileManager];
    
    _contentManager = [[BZRProductContentManager alloc] initWithFileManager:self.fileManager];
    BZRProductContentMultiFetcher *contentFetcher = [[BZRProductContentMultiFetcher alloc] init];
    _contentProvider =
        [[BZRProductContentProvider alloc] initWithContentFetcher:contentFetcher
                                                   contentManager:self.contentManager];

    BZRKeychainStorage *keychainStorage =
        [[BZRKeychainStorage alloc] initWithAccessGroup:keychainAccessGroup];
    BZRTimeProvider *timeProvider = [[BZRTimeProvider alloc] init];
    BZRValidatedReceiptValidationStatusProvider *validatorProvider =
        [[BZRValidatedReceiptValidationStatusProvider alloc] init];
    BZRModifiedExpiryReceiptValidationStatusProvider *modifiedExpiryProvider =
        [[BZRModifiedExpiryReceiptValidationStatusProvider alloc] initWithTimeProvider:timeProvider
         expiredSubscriptionGracePeriod:expiredSubscriptionGracePeriod
         underlyingProvider:validatorProvider];
    _validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithKeychainStorage:keychainStorage
         underlyingProvider:modifiedExpiryProvider];

    _acquiredViaSubscriptionProvider =
        [[BZRAcquiredViaSubscriptionProvider alloc] initWithKeychainStorage:keychainStorage];
    _applicationReceiptBundle = [NSBundle mainBundle];
    _storeKitFacadeFactory =
        [[BZRStoreKitFacadeFactory alloc] initWithApplicationUserID:applicationUserID];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END

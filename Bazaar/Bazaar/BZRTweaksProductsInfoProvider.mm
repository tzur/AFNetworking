// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweaksProductsInfoProvider.h"

#import <FBTweak/FBTweakStore.h>
#import <Milkshake/SHKTweakCategoryAdapter.h>

#import "BZRProduct.h"
#import "BZRReceiptModel+GenericSubscription.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTweaksCategory.h"
#import "BZRTweaksSubscriptionCollectionsProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// The use of this class is available only in debug mode.
#ifdef DEBUG

@interface BZRTweaksProductsInfoProvider ()

/// Underlying provider used to hold the original data from Bazaar.
@property (readonly, nonatomic) id<BZRProductsInfoProvider> originalProductInfoProvider;

/// Subscription collection provider used for creating the subscription tweaks.
@property (readonly, nonatomic) id<BZRTweakCollectionsProvider> subscriptionCollectionsProvider;

/// Provides the signal that specify which \c BZRTweaksSubscriptionSource to use, and holds a
/// overriding subscription to be used when the \c BZRTweaksSubscriptionSource sends
/// \c BZRTweaksSubscriptionSourceCustomizedSubscription.
@property (readonly, nonatomic) id<BZRTweaksOverrideSubscriptionProvider>
    overrideSubscriptionProvider;

/// Generic subscription to be used when the subscription source is
/// \c BZRTweaksSubscriptionSourceGenericActive.
@property (readonly, nonatomic) BZRReceiptSubscriptionInfo *genericActiveSubscription;

@end

@implementation BZRTweaksProductsInfoProvider

@synthesize purchasedProducts = _purchasedProducts;
@synthesize acquiredViaSubscriptionProducts = _acquiredViaSubscriptionProducts;
@synthesize acquiredProducts = _acquiredProducts;
@synthesize allowedProducts = _allowedProducts;
@synthesize subscriptionInfo = _subscriptionInfo;
@synthesize downloadedContentProducts = _downloadedContentProducts;
@synthesize receiptValidationStatus = _receiptValidationStatus;
@synthesize appStoreLocale = _appStoreLocale;
@synthesize productsJSONDictionary = _productsJSONDictionary;
@synthesize multiAppReceiptValidationStatus = _multiAppReceiptValidationStatus;

- (instancetype)initWithProductInfoProvider:(id<BZRProductsInfoProvider>)underlyingProvider
    subscriptionCollectionsProvider:(id<BZRTweakCollectionsProvider>)subscriptionCollectionsProvider
    overrideSubscriptionProvider:
    (id<BZRTweaksOverrideSubscriptionProvider>)overrideSubscriptionProvider
    genericActiveSubscription:(BZRReceiptSubscriptionInfo *)genericActiveSubscription {
  if (self = [super init]) {
    _originalProductInfoProvider = underlyingProvider;
    _subscriptionCollectionsProvider = subscriptionCollectionsProvider;
    _overrideSubscriptionProvider = overrideSubscriptionProvider;
    _genericActiveSubscription = genericActiveSubscription;

    [self bindProxiedProperties];
    [self setupTweakCategory];
  }
  return self;
}

- (instancetype)initWithProvider:(id<BZRProductsInfoProvider>)underlyingProvider {
  auto subscriptionCollectionsProvider = [[BZRTweaksSubscriptionCollectionsProvider alloc]
                                         initWithProductsInfoProvider:underlyingProvider];
  auto genericSubscription =
      [BZRReceiptSubscriptionInfo genericActiveSubscriptionWithPendingRenewalInfo];
  return [self initWithProductInfoProvider:underlyingProvider
           subscriptionCollectionsProvider:subscriptionCollectionsProvider
              overrideSubscriptionProvider:subscriptionCollectionsProvider
                 genericActiveSubscription:genericSubscription];
}

- (void)bindProxiedProperties {
  RAC(self, purchasedProducts) = RACObserve(self, originalProductInfoProvider.purchasedProducts);
  RAC(self, acquiredViaSubscriptionProducts) =
      RACObserve(self, originalProductInfoProvider.acquiredViaSubscriptionProducts);
  RAC(self, acquiredProducts) = RACObserve(self, originalProductInfoProvider.acquiredProducts);
  RAC(self, allowedProducts) = [self allowedProductsSignal];
  RAC(self, downloadedContentProducts) =
      RACObserve(self, originalProductInfoProvider.downloadedContentProducts);
  RAC(self, appStoreLocale) = RACObserve(self, originalProductInfoProvider.appStoreLocale);
  RAC(self, productsJSONDictionary) =
      RACObserve(self, originalProductInfoProvider.productsJSONDictionary);
  RAC(self, subscriptionInfo) = [self subscriptionInfoSignal];
  RAC(self, receiptValidationStatus) = [self receiptValidationStatusSignal];
  RAC(self, multiAppReceiptValidationStatus) =
      RACObserve(self, originalProductInfoProvider.multiAppReceiptValidationStatus);
}

- (RACSignal<NSSet<NSString *> *> *)allowedProductsSignal {
  auto originalAllowedProducts = RACObserve(self.originalProductInfoProvider, allowedProducts);
  auto tweaksAllowedProducts = [RACSignal
      switch:self.overrideSubscriptionProvider.subscriptionSourceSignal
       cases:@{
         @(BZRTweaksSubscriptionSourceCustomizedSubscription):
             [self allowedProductsForCustomizedSubscription],
         @(BZRTweaksSubscriptionSourceGenericActive): [self nonConsumableProductsIdentifiers],
         @(BZRTweaksSubscriptionSourceNoSubscription): [RACSignal return:[NSSet set]],
       } default:originalAllowedProducts];
  return [originalAllowedProducts takeUntilReplacement:tweaksAllowedProducts];
}

- (RACSignal<NSSet<NSString *> *> *)allowedProductsForCustomizedSubscription {
  auto overridingSubscriptionExpiry =
      RACObserve(self.overrideSubscriptionProvider, overridingSubscription.isExpired);
  return [RACSignal if:overridingSubscriptionExpiry
                  then:[RACSignal return:[NSSet set]]
                  else:[self nonConsumableProductsIdentifiers]];
}

- (RACSignal<NSSet<NSString *> *> *)nonConsumableProductsIdentifiers {
  auto productsJSONSignal = RACObserve(self.originalProductInfoProvider, productsJSONDictionary);
  return [productsJSONSignal
      map:^NSSet<NSString *> *(NSDictionary<NSString *, BZRProduct *> *productsDictionary) {
        return [self nonConsumableProductsIdentifiersFromDictionary:productsDictionary];
      }];
}

- (NSSet<NSString *> *)nonConsumableProductsIdentifiersFromDictionary:
    (NSDictionary<NSString *, BZRProduct *> *)productsDictionary {
  return [productsDictionary
      keysOfEntriesPassingTest:^BOOL(NSString *, BZRProduct *product, BOOL *) {
        return [product.productType isEqual:$(BZRProductTypeNonConsumable)];
      }];
}

- (RACSignal<BZRReceiptSubscriptionInfo *> *)subscriptionInfoSignal {
  auto originalSubscriptionInfo = RACObserve(self, originalProductInfoProvider.subscriptionInfo);
  auto overridingSubscriptionInfo =
      RACObserve(self, overrideSubscriptionProvider.overridingSubscription);
  auto switchingSubscription = [RACSignal
      switch:self.overrideSubscriptionProvider.subscriptionSourceSignal
       cases:@{
         @(BZRTweaksSubscriptionSourceOnDevice): originalSubscriptionInfo,
         @(BZRTweaksSubscriptionSourceGenericActive):
             [RACSignal return:self.genericActiveSubscription],
         @(BZRTweaksSubscriptionSourceNoSubscription): [RACSignal return:nil],
         @(BZRTweaksSubscriptionSourceCustomizedSubscription): overridingSubscriptionInfo
       } default:[RACSignal return:originalSubscriptionInfo]];
  return [originalSubscriptionInfo takeUntilReplacement:switchingSubscription];
}

- (RACSignal<BZRReceiptValidationStatus *> *)receiptValidationStatusSignal {
  return [RACObserve(self, subscriptionInfo)
      map:^BZRReceiptValidationStatus *(BZRReceiptSubscriptionInfo *subscriptionInfo) {
        return [self.originalProductInfoProvider.receiptValidationStatus
                modelByOverridingPropertyAtKeypath:
                @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription)
                withValue:subscriptionInfo];
      }];
}

- (void)setupTweakCategory {
  auto tweaksCategory = [[BZRTweaksCategory alloc]
                         initWithCollectionsProviders:@[self.subscriptionCollectionsProvider]];
  auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweaksCategory];
  [[FBTweakStore sharedInstance] addTweakCategory:adapter];
}

- (RACSignal<NSBundle *> *)contentBundleForProduct:(NSString *)productIdentifier {
  return [self.originalProductInfoProvider contentBundleForProduct:productIdentifier];
}

- (BOOL)isMultiAppSubscription:(NSString *)productIdentifier {
  return [self.originalProductInfoProvider isMultiAppSubscription:productIdentifier];
}

@end

#endif

NS_ASSUME_NONNULL_END

// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweaksProductsInfoProvider.h"

#import <FBTweak/FBTweakStore.h>
#import <Milkshake/SHKTweakCategoryAdapter.h>

#import "BZRTweaksCategory.h"
#import "BZRTweaksSubscriptionCollectionsProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// The use of this class is available only in debug mode.
#ifdef DEBUG

@interface BZRTweaksProductsInfoProvider ()

/// Underlying provider used to hold the original data from Bazaar.
@property (readonly, nonatomic) id<BZRProductsInfoProvider> underlyingProvider;

@end

@implementation BZRTweaksProductsInfoProvider

@synthesize purchasedProducts = _purchasedProducts;
@synthesize acquiredViaSubscriptionProducts = _acquiredViaSubscriptionProducts;
@synthesize acquiredProducts = _acquiredProducts;
@synthesize allowedProducts = _allowedProducts;
@synthesize downloadedContentProducts = _downloadedContentProducts;
@synthesize subscriptionInfo = _subscriptionInfo;
@synthesize receiptValidationStatus = _receiptValidationStatus;
@synthesize appStoreLocale = _appStoreLocale;
@synthesize productsJSONDictionary = _productsJSONDictionary;

- (instancetype)initWithUnderlyingProvider:(id<BZRProductsInfoProvider>)underlyingProvider {
  if (self = [super init]) {
    _underlyingProvider = underlyingProvider;
    [self bindProxiedProperties];
    [self bindSubscriptionInfo];
    [self setupTweakCategory];
  }
  return self;
}

- (void)bindProxiedProperties {
  RAC(self, purchasedProducts) = RACObserve(self.underlyingProvider, purchasedProducts);
  RAC(self, acquiredViaSubscriptionProducts) =
      RACObserve(self.underlyingProvider, acquiredViaSubscriptionProducts);
  RAC(self, acquiredProducts) = RACObserve(self.underlyingProvider, acquiredProducts);
  RAC(self, allowedProducts) = RACObserve(self.underlyingProvider, allowedProducts);
  RAC(self, downloadedContentProducts) =
      RACObserve(self.underlyingProvider, downloadedContentProducts);
  RAC(self, receiptValidationStatus) =
      RACObserve(self.underlyingProvider, receiptValidationStatus);
  RAC(self, appStoreLocale) = RACObserve(self.underlyingProvider, appStoreLocale);
  RAC(self, productsJSONDictionary) = RACObserve(self.underlyingProvider, productsJSONDictionary);
}

- (void)bindSubscriptionInfo {
  /// In the future routing by override signal should be done here.
  RAC(self, subscriptionInfo) = RACObserve(self.underlyingProvider, subscriptionInfo);
}

- (void)setupTweakCategory {
  auto subscriptionCollectionsProvider = [[BZRTweaksSubscriptionCollectionsProvider alloc]
      initWithProductsInfoProvider:self.underlyingProvider];
  auto tweaksCategory =
      [[BZRTweaksCategory alloc] initWithCollectionsProviders:@[subscriptionCollectionsProvider]];
  auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweaksCategory];
    [[FBTweakStore sharedInstance] addTweakCategory:adapter];
}

- (RACSignal<NSBundle *> *)contentBundleForProduct:(NSString *)productIdentifier {
  return [self.underlyingProvider contentBundleForProduct:productIdentifier];
}

- (BOOL)isMultiAppSubscription:(NSString *)productIdentifier {
  return [self.underlyingProvider isMultiAppSubscription:productIdentifier];
}

@end

#endif

NS_ASSUME_NONNULL_END

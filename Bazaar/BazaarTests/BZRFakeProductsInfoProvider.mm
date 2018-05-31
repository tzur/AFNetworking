// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRFakeProductsInfoProvider.h"

#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRFakeProductsInfoProvider

- (instancetype)init {
  if (self = [super init]){
    _contentBundleForProductSubject = [[RACSubject alloc] init];
  }
  return self;
}

- (RACSignal<NSBundle *> *)contentBundleForProduct:(NSString __unused *)productIdentifier {
  return self.contentBundleForProductSubject;
}

- (BOOL)isMultiAppSubscription:(NSString __unused *)productIdentifier {
  return self.valueToReturnFromIsMultiAppSubscription;
}

- (void)fillWithArbitraryData {
  self.purchasedProducts = [NSSet setWithArray:@[@"foo", @"bar"]];
  self.acquiredViaSubscriptionProducts = [NSSet setWithArray:@[@"foo", @"baz"]];
  self.acquiredProducts = [NSSet setWithArray:@[@"baz", @"bar"]];
  self.allowedProducts = [NSSet setWithArray:@[@"fo",@"baz"]] ;
  self.downloadedContentProducts = [NSSet setWithArray:@[@"bza",@"baz"]] ;
  self.subscriptionInfo =
      BZRReceiptValidationStatusWithSubscriptionIdentifier(@"foo.bar").receipt.subscription;
  self.receiptValidationStatus =
      BZRReceiptValidationStatusWithSubscriptionIdentifier(@"foo.bar");
  self.appStoreLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
  self.productsJSONDictionary =  @{@"foo":@"bar"};
  self.valueToReturnFromIsMultiAppSubscription = YES;
  self.subscriptionInfo =  [self.subscriptionInfo
      modelByOverridingPropertyAtKeypath:@keypath(self.subscriptionInfo, pendingRenewalInfo)
      withValue:[self createArbitraryPendingRenewalInfo]];
}

- (BZRSubscriptionPendingRenewalInfo *)createArbitraryPendingRenewalInfo {
  return [[BZRSubscriptionPendingRenewalInfo alloc] initWithDictionary:@{
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, willAutoRenew): @(YES),
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, expectedRenewalProductId): @"barf",
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, isPendingPriceIncreaseConsent): @(YES),
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, isInBillingRetryPeriod): @(YES),
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, expirationReason):
        @(BZRSubscriptionExpirationReasonPriceChangeNotAgreed)
  } error:nil];
}

@end

NS_ASSUME_NONNULL_END

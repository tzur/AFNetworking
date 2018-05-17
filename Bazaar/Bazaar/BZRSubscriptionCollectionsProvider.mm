// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRSubscriptionCollectionsProvider.h"

#import <FBTweak/FBTweak.h>
#import <FBTweak/FBTweakCollection.h>

#import "BZRProductsInfoProvider.h"
#import "BZRReceiptModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRSubscriptionCollectionsProvider()

/// Underlying provider used to provide the original subscription info.
@property (readonly, nonatomic) id<BZRProductsInfoProvider> productInfoProvider;

@end

@implementation BZRSubscriptionCollectionsProvider

@synthesize collections = _collections;

- (instancetype)initWithProductInfoProvider:(id<BZRProductsInfoProvider>)productInfoProvider {
  if (self = [super init]) {
    _productInfoProvider = productInfoProvider;
    [self bindCollections];
  }
  return self;
}

- (void)bindCollections {
  RAC(self, collections) = [[self createOriginalSubscriptionInfoCollection]
      map:^NSArray<FBTweakCollection *> *(FBTweakCollection *originalSubscriptionCollection) {
        return @[originalSubscriptionCollection];
      }];
}

- (RACSignal<FBTweakCollection *> *)createOriginalSubscriptionInfoCollection {
  return [[RACObserve(self.productInfoProvider, subscriptionInfo)
      map:^NSArray<FBTweak *> *(BZRReceiptSubscriptionInfo *info) {
        return @[
          [self productIdTweak:info],
          [self isExpiredTweak:info],
          [self originalTransactionIdTweak:info],
          [self originalPurchaseDateTimeTweak:info],
          [self lastPurchaseDateTime:info],
          [self expirationDateTime:info],
          [self cancellationDateTime:info],
          [self pendingWillAutoRenew:info],
          [self pendingExpectedRenewalProductId:info],
          [self pendingIsPendingPriceIncreaseConsent:info],
          [self pendingExpirationReason:info],
          [self pendinIsInBillingRetryPeriod:info]
        ];
      }]
      map:^FBTweakCollection *(NSArray<FBTweak *> *tweaks) {
        return [[FBTweakCollection alloc] initWithName:@"Subscription info"
                                                tweaks:tweaks];
      }];
}

- (FBTweak *)productIdTweak:(BZRReceiptSubscriptionInfo *)info {
  auto tweakIdentifier =[self subscriptionInfoTweakIdentifierFormKeypath:
      @instanceKeypath(BZRReceiptSubscriptionInfo, productId)];
  return [[FBTweak alloc]
      initWithIdentifier:tweakIdentifier
                    name:@"Product ID"
            currentValue:info.productId];
}

- (FBTweak *)isExpiredTweak:(BZRReceiptSubscriptionInfo *)info {
  auto tweakIdentifier =[self subscriptionInfoTweakIdentifierFormKeypath:
      @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired)];
  return [[FBTweak alloc]
      initWithIdentifier:tweakIdentifier
                    name:@"Is expired?"
            currentValue:info.isExpired ? @"Yes" : @"No"];
}

- (FBTweak *)originalTransactionIdTweak:(BZRReceiptSubscriptionInfo *)info {
  auto tweakIdentifier =[self subscriptionInfoTweakIdentifierFormKeypath:
      @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId)];
  return [[FBTweak alloc]
      initWithIdentifier:tweakIdentifier
                    name:@"Original transaction ID"
            currentValue:info.originalTransactionId];
}

- (FBTweak *)originalPurchaseDateTimeTweak:(BZRReceiptSubscriptionInfo *)info {
  auto tweakIdentifier = [self subscriptionInfoTweakIdentifierFormKeypath:
      @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime)];
  return [[FBTweak alloc]
      initWithIdentifier:tweakIdentifier
                    name:@"Original purchase date"
            currentValue:info.originalPurchaseDateTime];
}

- (FBTweak *)lastPurchaseDateTime:(BZRReceiptSubscriptionInfo *)info {
  auto tweakIdentifier = [self subscriptionInfoTweakIdentifierFormKeypath:
      @instanceKeypath(BZRReceiptSubscriptionInfo, lastPurchaseDateTime)];
  return [[FBTweak alloc]
      initWithIdentifier:tweakIdentifier
                    name:@"Last purchase date"
            currentValue:info.lastPurchaseDateTime];
}

- (FBTweak *)expirationDateTime:(BZRReceiptSubscriptionInfo *)info {
  auto tweakIdentifier = [self subscriptionInfoTweakIdentifierFormKeypath:
      @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime)];
  return [[FBTweak alloc]
      initWithIdentifier:tweakIdentifier
                    name:@"Expiration date"
            currentValue:info.expirationDateTime];
}

- (FBTweak *)cancellationDateTime:(BZRReceiptSubscriptionInfo *)info {
  auto tweakIdentifier = [self subscriptionInfoTweakIdentifierFormKeypath:
      @instanceKeypath(BZRReceiptSubscriptionInfo, cancellationDateTime)];
  return [[FBTweak alloc]
      initWithIdentifier:tweakIdentifier
                    name:@"Cancellation date"
            currentValue:info.cancellationDateTime];
}

- (FBTweak *)pendingWillAutoRenew:(BZRReceiptSubscriptionInfo *)info {
  auto tweakIdentifier = [self subscriptionInfoTweakIdentifierFormKeypath:
      @instanceKeypath(BZRReceiptSubscriptionInfo, pendingRenewalInfo.willAutoRenew)];
  return [[FBTweak alloc]
      initWithIdentifier:tweakIdentifier
                    name:@"Pending: Will auto renew"
            currentValue:info.pendingRenewalInfo.willAutoRenew? @"Yes" : @"No"];
}

- (FBTweak *)pendingExpectedRenewalProductId:(BZRReceiptSubscriptionInfo *)info {
  auto tweakIdentifier = [self subscriptionInfoTweakIdentifierFormKeypath:
      @instanceKeypath(BZRReceiptSubscriptionInfo, pendingRenewalInfo.expectedRenewalProductId)];
  return [[FBTweak alloc]
      initWithIdentifier:tweakIdentifier
                    name:@"Pending: Auto renew product ID"
            currentValue:info.pendingRenewalInfo.expectedRenewalProductId];
}

- (FBTweak *)pendingIsPendingPriceIncreaseConsent:(BZRReceiptSubscriptionInfo *)info {
  auto tweakIdentifier = [self subscriptionInfoTweakIdentifierFormKeypath:
      @instanceKeypath(BZRReceiptSubscriptionInfo,
      pendingRenewalInfo.isPendingPriceIncreaseConsent)];
  return [[FBTweak alloc]
      initWithIdentifier:tweakIdentifier
                    name:@"Pending: Consents to pending increase"
            currentValue:info.pendingRenewalInfo.isPendingPriceIncreaseConsent ? @"Yes" : @"No"];
}

- (FBTweak *)pendingExpirationReason:(BZRReceiptSubscriptionInfo *)info {
  auto tweakIdentifier = [self subscriptionInfoTweakIdentifierFormKeypath:
      @instanceKeypath(BZRReceiptSubscriptionInfo, pendingRenewalInfo.expirationReason)];
  return [[FBTweak alloc]
      initWithIdentifier:tweakIdentifier
                    name:@"Pending: Expiration reason"
            currentValue:[info.pendingRenewalInfo.expirationReason name]];
}

- (FBTweak *)pendinIsInBillingRetryPeriod:(BZRReceiptSubscriptionInfo *)info {
  auto tweakIdentifier = [self subscriptionInfoTweakIdentifierFormKeypath:
      @instanceKeypath(BZRReceiptSubscriptionInfo, pendingRenewalInfo.isInBillingRetryPeriod)];
  return [[FBTweak alloc]
      initWithIdentifier:tweakIdentifier
                    name:@"Pending: is in billing retry period"
            currentValue:info.pendingRenewalInfo.isInBillingRetryPeriod ? @"Yes" : @"No"];
}

- (NSString *)subscriptionInfoTweakIdentifierFormKeypath:(NSString *)keypath {
  return [self tweakIdentifierFromKeypath:
      [NSString stringWithFormat:@"subscriptionInfo.%@", keypath]];
}

- (NSString *)tweakIdentifierFromKeypath:(NSString *)keypath {
  return [NSString stringWithFormat:@"com.lightricks.bazaar.%@", keypath];
}

@end

NS_ASSUME_NONNULL_END

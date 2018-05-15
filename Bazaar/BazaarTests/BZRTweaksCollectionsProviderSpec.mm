// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import <FBTweak/FBTweak.h>
#import <FBTweak/FBTweakCollection.h>

#import "BZRFakeProductsInfoProvider.h"
#import "BZRReceiptModel.h"
#import "BZRSubscriptionCollectionsProvider.h"

SpecBegin(BZRSubscriptionCollectionsProvider)

__block BZRSubscriptionCollectionsProvider *collectionProvider;
__block BZRFakeProductsInfoProvider * provider;

beforeEach(^{
  provider = [[BZRFakeProductsInfoProvider alloc] init];
  [provider fillWithArbitraryData];

  collectionProvider =
      [[BZRSubscriptionCollectionsProvider alloc] initWithProductInfoProvider:provider];
});

it(@"should create the correct tweak collection", ^{
  auto firstCollection = collectionProvider.collections[0];
  auto tweaks = firstCollection.tweaks;

  expect(firstCollection.tweaks.count).to.equal(12);
  expect(tweaks[0].currentValue).to.equal(provider.subscriptionInfo.productId);
  expect(tweaks[1].currentValue).to
      .equal(provider.subscriptionInfo.isExpired ? @"Yes" : @"No");
  expect(tweaks[2].currentValue).to.equal(provider.subscriptionInfo.originalTransactionId);
  expect(tweaks[3].currentValue).to.equal(provider.subscriptionInfo.originalPurchaseDateTime);
  expect(tweaks[4].currentValue).to.equal(provider.subscriptionInfo.lastPurchaseDateTime);
  expect(tweaks[5].currentValue).to.equal(provider.subscriptionInfo.expirationDateTime);
  expect(tweaks[6].currentValue).to.equal(provider.subscriptionInfo.cancellationDateTime);
  expect(tweaks[7].currentValue).to
      .equal(provider.subscriptionInfo.pendingRenewalInfo.willAutoRenew ? @"Yes" : @"No");
  expect(tweaks[8].currentValue).to
      .equal(provider.subscriptionInfo.pendingRenewalInfo.expectedRenewalProductId);
  expect(tweaks[9].currentValue).to
      .equal(provider.subscriptionInfo.pendingRenewalInfo.isPendingPriceIncreaseConsent ?
          @"Yes" : @"No");
  expect(tweaks[10].currentValue).to
      .equal(provider.subscriptionInfo.pendingRenewalInfo.expirationReason);
  expect(tweaks[11].currentValue).to
      .equal(provider.subscriptionInfo.pendingRenewalInfo.isInBillingRetryPeriod ?
          @"Yes" : @"No");
});

it(@"should be KVO compliant", ^{
  auto recorder = [RACObserve(collectionProvider, collections) testRecorder];
  auto originalProductId = provider.subscriptionInfo.productId;
  provider.subscriptionInfo = nil;

  auto firstSentCollection = (FBTweakCollection *)((recorder.values[0])[0]);
  expect(firstSentCollection.tweaks[0].currentValue).to.equal(originalProductId);

  auto secondSentCollection = (FBTweakCollection *)((recorder.values[1])[0]);
  expect(secondSentCollection.tweaks[0].currentValue).to.beNil();
});

SpecEnd

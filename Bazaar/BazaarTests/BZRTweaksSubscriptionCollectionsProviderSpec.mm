// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweaksSubscriptionCollectionsProvider.h"

#import <FBTweak/FBTweak.h>
#import <FBTweak/FBTweakCollection.h>

#import "BZRFakeProductsInfoProvider.h"
#import "BZRReceiptModel.h"

SpecBegin(BZRTweaksSubscriptionCollectionsProvider)

__block BZRTweaksSubscriptionCollectionsProvider *collectionProvider;
__block BZRFakeProductsInfoProvider * provider;

beforeEach(^{
  provider = [[BZRFakeProductsInfoProvider alloc] init];
  [provider fillWithArbitraryData];

  collectionProvider =
      [[BZRTweaksSubscriptionCollectionsProvider alloc] initWithProductsInfoProvider:provider];
});

it(@"should on first run, create a data source control tweak collection and an info tweak "
   "collection", ^{
  auto dataSourceTweakCollection = collectionProvider.collections[0];
  auto infoTweakCollection = collectionProvider.collections[1];
  auto tweaks = infoTweakCollection.tweaks;

  expect(dataSourceTweakCollection.tweaks.count).to.equal(1);
  expect(dataSourceTweakCollection.tweaks[0].identifier).to.endWith(@"dataSourceChoose");
  expect(((FBPersistentTweak *)(dataSourceTweakCollection.tweaks[0])).defaultValue)
      .to.equal(BZRTweaksSubscriptionDataSourceTypeOnDevice);
  expect(infoTweakCollection.tweaks.count).to.equal(12);
  expect(tweaks[0].currentValue).to.equal(provider.subscriptionInfo.productId);
  expect(tweaks[2].currentValue).to.equal(provider.subscriptionInfo.originalTransactionId);
  expect(tweaks[3].currentValue).to.equal(provider.subscriptionInfo.originalPurchaseDateTime);
  expect(tweaks[4].currentValue).to.equal(provider.subscriptionInfo.lastPurchaseDateTime);
  expect(tweaks[5].currentValue).to.equal(provider.subscriptionInfo.expirationDateTime);
  expect(tweaks[6].currentValue).to.equal(provider.subscriptionInfo.cancellationDateTime);
  expect(tweaks[10].currentValue).to
      .equal(provider.subscriptionInfo.pendingRenewalInfo.expirationReason);
  // In 32 bit, booleans can't be distinguished from integers. and the following tests will fail
  // due to wrong tweak data type.
#ifdef __LP64__
  expect(tweaks[1].currentValue).to
       .equal(provider.subscriptionInfo.isExpired ? @"Yes" : @"No");
  expect(tweaks[7].currentValue).to
      .equal(provider.subscriptionInfo.pendingRenewalInfo.willAutoRenew ? @"Yes" : @"No");
  expect(tweaks[8].currentValue).to
      .equal(provider.subscriptionInfo.pendingRenewalInfo.expectedRenewalProductId);
  expect(tweaks[9].currentValue).to
      .equal(provider.subscriptionInfo.pendingRenewalInfo.isPendingPriceIncreaseConsent ?
      @"Yes" : @"No");
  expect(tweaks[11].currentValue).to
      .equal(provider.subscriptionInfo.pendingRenewalInfo.isInBillingRetryPeriod ?
          @"Yes" : @"No");
#endif
});

it(@"should be KVO compliant", ^{
  auto recorder = [RACObserve(collectionProvider, collections) testRecorder];
  auto originalProductId = provider.subscriptionInfo.productId;
  provider.subscriptionInfo = nil;

  auto firstSentInfoCollection = (FBTweakCollection *)((recorder.values[0])[1]);
  expect(firstSentInfoCollection.tweaks[0].currentValue).to.equal(originalProductId);

  auto secondSentInfoCollection = (FBTweakCollection *)((recorder.values[1])[1]);
  expect(secondSentInfoCollection.tweaks[0].currentValue).to.beNil();
});

SpecEnd

// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweaksSubscriptionCollectionsProvider.h"

#import <FBTweak/FBTweak.h>
#import <FBTweak/FBTweakCollection.h>

#import "BZRFakeProductsInfoProvider.h"
#import "BZRReceiptModel+GenericSubscription.h"

static NSString *const kBZRSubscriptionSourceTweakID = @"subscriptionSourceChoose";

SpecBegin(BZRTweaksSubscriptionCollectionsProvider)

__block BZRTweaksSubscriptionCollectionsProvider *collectionProvider;
__block BZRFakeProductsInfoProvider *provider;
__block FBTweakCollection *subscriptionSourceTweakCollection;

beforeEach(^{
  provider = [[BZRFakeProductsInfoProvider alloc] init];
  [provider fillWithArbitraryData];

  collectionProvider =
      [[BZRTweaksSubscriptionCollectionsProvider alloc] initWithProductsInfoProvider:provider];
  subscriptionSourceTweakCollection = collectionProvider.collections[0];
});

it(@"should be KVO compliant", ^{
  ((FBPersistentTweak *)subscriptionSourceTweakCollection.tweaks[0]).currentValue =
      @(BZRTweaksSubscriptionSourceOnDevice);

  auto recorder = [RACObserve(collectionProvider, collections) testRecorder];
  auto originalProductId = provider.subscriptionInfo.productId;
  provider.subscriptionInfo = nil;

  auto firstSentInfoCollection = (FBTweakCollection *)((recorder.values[0])[1]);
  expect(firstSentInfoCollection.tweaks[0].currentValue).to.equal(originalProductId);

  auto secondSentInfoCollection = (FBTweakCollection *)((recorder.values[1])[1]);
  expect(secondSentInfoCollection.tweaks[0].currentValue).to.beNil();
});

it(@"should on first run, create a subscription source control tweak collection and an info tweak "
   "collection", ^{
  ((FBPersistentTweak *)subscriptionSourceTweakCollection.tweaks[0]).currentValue =
      @(BZRTweaksSubscriptionSourceOnDevice);

  auto infoTweakCollection = collectionProvider.collections[1];
  auto tweaks = infoTweakCollection.tweaks;

  expect(subscriptionSourceTweakCollection.tweaks.count).to.equal(1);
  expect(subscriptionSourceTweakCollection.tweaks[0].identifier).
      to.endWith(kBZRSubscriptionSourceTweakID);
  expect(((FBPersistentTweak *)(subscriptionSourceTweakCollection.tweaks[0])).defaultValue)
      .to.equal(BZRTweaksSubscriptionSourceOnDevice);
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

it(@"should send only the subscription source tweak collection when the selected source is "
   "'GenericActive'", ^{
  ((FBPersistentTweak *)subscriptionSourceTweakCollection.tweaks[0]).currentValue =
      @(BZRTweaksSubscriptionSourceGenericActive);

  subscriptionSourceTweakCollection = collectionProvider.collections[0];
  expect(subscriptionSourceTweakCollection.tweaks[0].identifier).
      to.endWith(kBZRSubscriptionSourceTweakID);
  expect(collectionProvider.collections[1].tweaks).to.beEmpty();
});

it(@"should send only the subscription source tweak collection when selected source is "
   "'NoSubscription'", ^{
  ((FBPersistentTweak *)subscriptionSourceTweakCollection.tweaks[0]).currentValue =
      @(BZRTweaksSubscriptionSourceNoSubscription);

  subscriptionSourceTweakCollection = collectionProvider.collections[0];
  expect(subscriptionSourceTweakCollection.tweaks[0].identifier).
      to.endWith(kBZRSubscriptionSourceTweakID);
  expect(collectionProvider.collections[1].tweaks).to.beEmpty();
});

context(@"source is 'CustomizedSubscription'", ^{
  __block id userDefaultsMock;
  __block FBTweakCollection *subscriptionOverrideTweakCollection;

  beforeEach(^{
    userDefaultsMock = OCMPartialMock([NSUserDefaults standardUserDefaults]);
    OCMStub([userDefaultsMock objectForKey:[OCMArg checkWithBlock:^BOOL(NSString *identifier) {
      return [identifier containsString:kBZRTweakIdentifierPrefix];
    }]]);

    collectionProvider =
        [[BZRTweaksSubscriptionCollectionsProvider alloc] initWithProductsInfoProvider:provider];
    ((FBPersistentTweak *)collectionProvider.collections[0].tweaks[0]).currentValue =
        @(BZRTweaksSubscriptionSourceCustomizedSubscription);
    subscriptionSourceTweakCollection = collectionProvider.collections[0];
    subscriptionOverrideTweakCollection = collectionProvider.collections[1];
  });

  afterEach(^{
    userDefaultsMock = nil;
  });

  it(@"should initially send the subscription override collection with generic subscription", ^{
    expect(subscriptionOverrideTweakCollection.tweaks.count).to.equal(12);
    auto genericSubscriptionId =
        [BZRReceiptSubscriptionInfo genericActiveSubscriptionWithPendingRenewalInfo].productId;
    expect(subscriptionOverrideTweakCollection.tweaks[0].currentValue)
        .to.equal(genericSubscriptionId);
  });

  it(@"should send the subscription override collection with the subscription from "
     "device if reload has been pressed", ^{
    auto reloadSubscriptionFromDeviceBlock =
        ((FBActionTweak *)subscriptionSourceTweakCollection.tweaks[1]).currentValue;
    reloadSubscriptionFromDeviceBlock();

    /// update variable after reload.
    subscriptionOverrideTweakCollection = collectionProvider.collections[1];

    expect(subscriptionOverrideTweakCollection.tweaks.count).to.equal(12);
    expect(subscriptionOverrideTweakCollection.tweaks[0].currentValue)
        .to.equal(provider.subscriptionInfo.productId);
  });
});

SpecEnd

// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweaksProductsInfoProvider.h"

#import "BZRFakeProductsInfoProvider.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"

SpecBegin(BZRTweaksProductsInfoProvider)

  __block BZRFakeProductsInfoProvider *provider;
  __block BZRTweaksProductsInfoProvider *tweaksProductInfoProvider;

  beforeEach(^{
    provider = [[BZRFakeProductsInfoProvider alloc] init];
    [provider fillWithArbitraryData];
    tweaksProductInfoProvider =
        [[BZRTweaksProductsInfoProvider alloc] initWithUnderlyingProvider:provider];
  });

  it(@"should proxy all the underlying product info provider properties", ^{
    expect(tweaksProductInfoProvider.purchasedProducts).to.equal(provider.purchasedProducts);
    expect(tweaksProductInfoProvider.acquiredViaSubscriptionProducts).to
        .equal(provider.acquiredViaSubscriptionProducts);
    expect(tweaksProductInfoProvider.acquiredProducts).to.equal(provider.acquiredProducts);
    expect(tweaksProductInfoProvider.allowedProducts).to.equal(provider.allowedProducts);
    expect(tweaksProductInfoProvider.downloadedContentProducts)
        .to.equal(provider.downloadedContentProducts);
    expect(tweaksProductInfoProvider.subscriptionInfo).to.equal(provider.subscriptionInfo);
    expect(tweaksProductInfoProvider.receiptValidationStatus)
        .to.equal(provider.receiptValidationStatus);
    expect(tweaksProductInfoProvider.appStoreLocale).to.equal(provider.appStoreLocale);
    expect(tweaksProductInfoProvider.productsJSONDictionary)
        .to.equal(provider.productsJSONDictionary);
    expect(tweaksProductInfoProvider.productsJSONDictionary)
        .to.equal(provider.productsJSONDictionary);
  });

  it(@"should proxy the isMultiAppSubscription method", ^{
    id<BZRProductsInfoProvider> partialMockedProvider = OCMPartialMock(provider);
    OCMExpect([partialMockedProvider isMultiAppSubscription:@"foo"]).andReturn(YES);

    expect([tweaksProductInfoProvider isMultiAppSubscription:@"foo"]).to.equal(YES);
    OCMVerifyAll((id)partialMockedProvider);
  });

  it(@"should proxy the contentBundleForProduct method", ^{
    id<BZRProductsInfoProvider> partialMockedProvider = OCMPartialMock(provider);
    OCMExpect([partialMockedProvider contentBundleForProduct:@"foo"])
        .andReturn([RACSignal return:[NSBundle mainBundle]]);

    auto bundleRecorder = [[tweaksProductInfoProvider contentBundleForProduct:@"foo"] testRecorder];

    expect(bundleRecorder).to.sendValues(@[[NSBundle mainBundle]]);
    OCMVerifyAll((id)partialMockedProvider);
  });

SpecEnd

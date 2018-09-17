// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionDescriptor.h"

#import <Bazaar/BZRProductPriceInfo.h>
#import <Bazaar/BZRProductsInfoProvider.h>
#import <Bazaar/BZRSubscriptionIntroductoryDiscount.h>
#import <LTKit/NSArray+Functional.h>

SpecBegin(SPXSubscriptionDescriptor)

__block id<BZRProductsInfoProvider> productsInfoProvider;

it(@"should raise if the discount percentage is equal to 100", ^{
  productsInfoProvider = OCMProtocolMock(@protocol(BZRProductsInfoProvider));
  expect(^{
    auto __unused descriptor = [[SPXSubscriptionDescriptor alloc]
                                initWithProductIdentifier:@"foo" discountPercentage:100
                                productsInfoProvider:productsInfoProvider];
  }).to.raise(NSInvalidArgumentException);

});

it(@"should raise if the discount percentage greater than 100", ^{
  expect(^{
    auto __unused descriptor =[[SPXSubscriptionDescriptor alloc]
                               initWithProductIdentifier:@"foo" discountPercentage:101
                               productsInfoProvider:productsInfoProvider];
  }).to.raise(NSInvalidArgumentException);
});

context(@"price information", ^{
  it(@"should be KVO-compliant", ^{
    auto descriptor = [[SPXSubscriptionDescriptor alloc]
                       initWithProductIdentifier:@"foo" discountPercentage:0
                       productsInfoProvider:productsInfoProvider];
    auto testRecorder = [RACObserve(descriptor, priceInfo) testRecorder];
    BZRProductPriceInfo *priceInfo = OCMClassMock([BZRProductPriceInfo class]);

    descriptor.priceInfo = priceInfo;

    expect(testRecorder).to.sendValues(@[
      [NSNull null],
      priceInfo
    ]);
  });
});

context(@"introductory discount", ^{
  it(@"should be KVO-compliant", ^{
    auto descriptor = [[SPXSubscriptionDescriptor alloc]
                       initWithProductIdentifier:@"foo" discountPercentage:0
                       productsInfoProvider:productsInfoProvider];
    auto testRecorder = [RACObserve(descriptor, introductoryDiscount) testRecorder];
    BZRSubscriptionIntroductoryDiscount *introductoryDiscount =
        OCMClassMock([BZRSubscriptionIntroductoryDiscount class]);

    descriptor.introductoryDiscount = introductoryDiscount;

    expect(testRecorder).to.sendValues(@[
      [NSNull null],
      introductoryDiscount
    ]);
  });
});

SpecEnd

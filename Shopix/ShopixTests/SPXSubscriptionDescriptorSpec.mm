// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionDescriptor.h"

#import <Bazaar/BZRProductPriceInfo.h>

SpecBegin(SPXSubscriptionDescriptor)

it(@"should raise if the discount percentage is equal to 100", ^{
  expect(^{
    auto __unused descriptor = [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo"
                                                                         discountPercentage:100];
  }).to.raise(NSInvalidArgumentException);

});

it(@"should raise if the discount percentage greater than 100", ^{
  expect(^{
    auto __unused descriptor =[[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo"
                                                                        discountPercentage:101];
  }).to.raise(NSInvalidArgumentException);
});

context(@"price information", ^{
  it(@"should be KVO-compliant", ^{
    auto descriptor =[[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:@"foo"];
    auto testRecorder = [RACObserve(descriptor, priceInfo) testRecorder];
    BZRProductPriceInfo *priceInfo = OCMClassMock([BZRProductPriceInfo class]);

    descriptor.priceInfo = priceInfo;

    expect(testRecorder).to.sendValues(@[
      [NSNull null],
      priceInfo
    ]);
  });
});

SpecEnd

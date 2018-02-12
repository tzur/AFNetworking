// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionDescriptor+PriceString.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProductPriceInfo.h>
#import <Bazaar/BZRProductsInfoProvider.h>

SpecBegin(SPXSubscriptionDescriptor_PriceString)

__block id<BZRProductsInfoProvider> productsInfoProvider;
__block BZRProductPriceInfo *priceInfo;
__block SPXSubscriptionDescriptor *descriptor;

beforeEach(^{
  productsInfoProvider = OCMProtocolMock(@protocol(BZRProductsInfoProvider));
});

context(@"price string", ^{
  beforeEach(^{
    priceInfo = [[BZRProductPriceInfo alloc] initWithDictionary:@{
      @instanceKeypath(BZRProductPriceInfo, price): [[NSDecimalNumber alloc] initWithString:@"20"],
      @instanceKeypath(BZRProductPriceInfo, localeIdentifier): @"en_US"
    } error:nil];
  });

  it(@"should return nil if the subscription descriptor's price information is nil", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.foo"
                  discountPercentage:0 productsInfoProvider:productsInfoProvider];
    expect([descriptor priceString:YES]).to.beNil();
  });

  it(@"should raise if the product period is unsupported and monthly format is YES", ^{
    descriptor = OCMPartialMock([[SPXSubscriptionDescriptor alloc]
                                 initWithProductIdentifier:@"com.lightricks.Shopix.foo"
                                 discountPercentage:0 productsInfoProvider:productsInfoProvider]);
    descriptor.priceInfo = priceInfo;
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @instanceKeypath(BZRBillingPeriod, unit): $(BZRBillingPeriodUnitDays),
      @instanceKeypath(BZRBillingPeriod, unitCount): @1
    } error:nil];
    OCMStub([descriptor billingPeriod]).andReturn(billingPeriod);

    expect(^{
      [descriptor priceString:YES];
    }).to.raise(NSInvalidArgumentException);
  });

  context(@"monthly subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.Monthly"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should not divide the price if monthly format is YES", ^{
      expect([descriptor priceString:YES]).to.equal(@"$20.00");
    });
  });

  context(@"yearly subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.Yearly"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should divide the price by 12 if monthly format is YES", ^{
      expect([descriptor priceString:YES]).to.equal(@"$1.66");
    });

    it(@"should not divide the price if monthly format is NO", ^{
      expect([descriptor priceString:NO]).to.equal(@"$20.00");
    });
  });

  context(@"one-time-payment subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.OneTimePayment"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should not divide the price if monthly format is YES", ^{
      expect([descriptor priceString:YES]).to.equal(@"$20.00");
    });

    it(@"should not divide the price if monthly format is NO", ^{
      expect([descriptor priceString:NO]).to.equal(@"$20.00");
    });
  });
});

context(@"full price string", ^{
  beforeEach(^{
    priceInfo = [[BZRProductPriceInfo alloc] initWithDictionary:@{
      @instanceKeypath(BZRProductPriceInfo, price): [[NSDecimalNumber alloc] initWithString:@"10"],
      @instanceKeypath(BZRProductPriceInfo, fullPrice): [[NSDecimalNumber alloc]
                                                         initWithString:@"50"],
      @instanceKeypath(BZRProductPriceInfo, localeIdentifier): @"en_US"
    } error:nil];
  });

  it(@"should raise if the subscription descriptor's price information is nil", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.foo"
                  discountPercentage:0 productsInfoProvider:productsInfoProvider];
    expect([descriptor fullPriceString:YES]).to.beNil();
  });

  it(@"should raise if the product period is unsupported and monthly format is YES", ^{
    descriptor = OCMPartialMock([[SPXSubscriptionDescriptor alloc]
                                 initWithProductIdentifier:@"com.lightricks.Shopix.foo"
                                 discountPercentage:0 productsInfoProvider:productsInfoProvider]);
    descriptor.priceInfo = priceInfo;
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @instanceKeypath(BZRBillingPeriod, unit): $(BZRBillingPeriodUnitDays),
      @instanceKeypath(BZRBillingPeriod, unitCount): @1
    } error:nil];
    OCMStub([descriptor billingPeriod]).andReturn(billingPeriod);

    expect(^{
      [descriptor fullPriceString:YES];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should prefer full price from priceInfo over a custom discount percentage", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.Monthly"
                  discountPercentage:0.5 productsInfoProvider:productsInfoProvider];
    descriptor.priceInfo = priceInfo;

    expect([descriptor fullPriceString:NO]).to.equal(@"$50.00");
  });

  context(@"monthly subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.Monthly"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should not divide the price if monthly format is YES", ^{
      expect([descriptor fullPriceString:YES]).to.equal(@"$50.00");
    });
  });

  context(@"yearly subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.Yearly"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should divide the price by 12 if monthly format is YES", ^{
      expect([descriptor fullPriceString:YES]).to.equal(@"$4.16");
    });

    it(@"should not divide the price if monthly format is NO", ^{
      expect([descriptor fullPriceString:NO]).to.equal(@"$50.00");
    });
  });

  context(@"one-time-payment subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.OneTimePayment"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should not divide the price if monthly format is YES", ^{
      expect([descriptor fullPriceString:YES]).to.equal(@"$50.00");
    });

    it(@"should not divide the price if monthly format is NO", ^{
      expect([descriptor fullPriceString:NO]).to.equal(@"$50.00");
    });
  });
});

context(@"full price string from custom discount", ^{
  beforeEach(^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.Yearly"
                  discountPercentage:10 productsInfoProvider:productsInfoProvider];
    descriptor.priceInfo = [[BZRProductPriceInfo alloc] initWithDictionary:@{
      @instanceKeypath(BZRProductPriceInfo, price): [[NSDecimalNumber alloc] initWithString:@"10"],
      @instanceKeypath(BZRProductPriceInfo, localeIdentifier): @"en_US"
    } error:nil];
  });

  it(@"should divide the price by 12 if monthly format is YES", ^{
    expect([descriptor fullPriceString:YES]).to.equal(@"$0.99");
  });

  it(@"should not divide the price if monthly format is NO", ^{
    expect([descriptor fullPriceString:NO]).to.equal(@"$11.99");
  });
});

SpecEnd

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionButtonFormatter.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProductPriceInfo.h>
#import <Bazaar/BZRProductsInfoProvider.h>

#import "SPXSubscriptionDescriptor.h"

SpecBegin(SPXSubscriptionButtonFormatter)

__block id<BZRProductsInfoProvider> productsInfoProvider;
__block SPXSubscriptionButtonFormatter *formatter;
__block BZRProductPriceInfo *priceInfo;
__block SPXSubscriptionDescriptor *descriptor;

beforeEach(^{
  productsInfoProvider = OCMProtocolMock(@protocol(BZRProductsInfoProvider));
  formatter = [[SPXSubscriptionButtonFormatter alloc] initWithPeriodTextColor:[UIColor redColor]
                                                               priceTextColor:[UIColor blueColor]
                                                           fullPriceTextColor:[UIColor whiteColor]];
});

context(@"period text", ^{
  it(@"should raise if the subscription product billing period is unsupported", ^{
    descriptor = OCMPartialMock([[SPXSubscriptionDescriptor alloc]
                                 initWithProductIdentifier:@"com.lightricks.Shopix.UnknownPeriod"
                                 discountPercentage:0 productsInfoProvider:productsInfoProvider]);
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitDays),
      @"unitCount": @1
    } error:nil];
    OCMStub([descriptor billingPeriod]).andReturn(billingPeriod);

    expect(^{
      [formatter billingPeriodTextForSubscription:descriptor monthlyFormat:NO];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should be colored by the given period text color", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.Monthly"
                  discountPercentage:0 productsInfoProvider:productsInfoProvider];
    auto periodText = [formatter billingPeriodTextForSubscription:descriptor monthlyFormat:NO];
    UIColor *periodTextColor = [periodText attribute:NSForegroundColorAttributeName atIndex:0
                               longestEffectiveRange:nil inRange:NSMakeRange(0, periodText.length)];

    expect(periodTextColor).to.equal([UIColor redColor]);
  });

  it(@"should always display monthly period text in months", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.Monthly"
                  discountPercentage:0 productsInfoProvider:productsInfoProvider];
    auto periodText = [formatter billingPeriodTextForSubscription:descriptor monthlyFormat:NO];
    auto periodTextMonthly = [formatter billingPeriodTextForSubscription:descriptor
                                                           monthlyFormat:YES];

    expect([periodText string]).to.equal(@"1\nMonth");
    expect([periodTextMonthly string]).to.equal(@"1\nMonth");
  });

  it(@"should always display bi-yearly period in months", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.BiYearly"
                  discountPercentage:0 productsInfoProvider:productsInfoProvider];
    auto periodText = [formatter billingPeriodTextForSubscription:descriptor monthlyFormat:NO];
    auto periodTextMonthly = [formatter billingPeriodTextForSubscription:descriptor
                                                           monthlyFormat:YES];

    expect([periodText string]).to.equal(@"6\nMonths");
    expect([periodTextMonthly string]).to.equal(@"6\nMonths");
  });

  it(@"should display the period in years if monthly format is NO and the period is yearly", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.Yearly"
                  discountPercentage:0 productsInfoProvider:productsInfoProvider];
    auto periodText = [formatter billingPeriodTextForSubscription:descriptor monthlyFormat:NO];

    expect([periodText string]).to.equal(@"1\nYear");
  });

  it(@"should display the period in months if monthly format is YES and the period is yearly", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.Yearly"
                  discountPercentage:0 productsInfoProvider:productsInfoProvider];
    auto periodText = [formatter billingPeriodTextForSubscription:descriptor monthlyFormat:YES];

    expect([periodText string]).to.equal(@"12\nMonths");
  });

  it(@"should always display one-time-purchase text if the period is one-time-payment", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.OneTimePayment"
                  discountPercentage:0 productsInfoProvider:productsInfoProvider];
    auto periodText = [formatter billingPeriodTextForSubscription:descriptor monthlyFormat:NO];
    auto periodTextMonthly = [formatter billingPeriodTextForSubscription:descriptor
                                                           monthlyFormat:YES];

    expect([periodText string]).to.equal(@"One-Time\nPurchase");
    expect([periodTextMonthly string]).to.equal(@"One-Time\nPurchase");
  });
});

context(@"price text", ^{
  beforeEach(^{
    priceInfo = [[BZRProductPriceInfo alloc] initWithDictionary:@{
      @"price": [[NSDecimalNumber alloc] initWithString:@"20"],
      @"localeIdentifier": @"en_US"
    } error:nil];
  });

  it(@"should raise if the subscription descriptor's price information is nil", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.UnknownPeriod"
                  discountPercentage:0 productsInfoProvider:productsInfoProvider];
    expect(^{
      [formatter priceTextForSubscription:descriptor monthlyFormat:YES];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if the product period is unsupported and monthly format is YES", ^{
    descriptor = OCMPartialMock([[SPXSubscriptionDescriptor alloc]
                                 initWithProductIdentifier:@"com.lightricks.Shopix.UnknownPeriod"
                                 discountPercentage:0 productsInfoProvider:productsInfoProvider]);
    descriptor.priceInfo = priceInfo;
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitDays),
      @"unitCount": @1
    } error:nil];
    OCMStub([descriptor billingPeriod]).andReturn(billingPeriod);

    expect(^{
      [formatter priceTextForSubscription:descriptor monthlyFormat:YES];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should be colored by the given price text color", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.Monthly"
                  discountPercentage:0 productsInfoProvider:productsInfoProvider];
    descriptor.priceInfo = priceInfo;
    auto priceText = [formatter priceTextForSubscription:descriptor monthlyFormat:NO];
    UIColor *priceTextColor = [priceText attribute:NSForegroundColorAttributeName atIndex:0
                               longestEffectiveRange:nil inRange:NSMakeRange(0, priceText.length)];

    expect(priceTextColor).to.equal([UIColor blueColor]);
  });

  context(@"monthly subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.Monthly"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should not divide the price and contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter priceTextForSubscription:descriptor monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$20.00/mo");
    });

    it(@"should not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter priceTextForSubscription:descriptor monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$20.00");
    });
  });

  context(@"bi-yearly subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.BiYearly"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should divide the price by 6 and contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter priceTextForSubscription:descriptor monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$3.33/mo");
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter priceTextForSubscription:descriptor monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$20.00");
    });
  });

  context(@"yearly subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.Yearly"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should divide the price by 12 and contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter priceTextForSubscription:descriptor monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$1.66/mo");
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter priceTextForSubscription:descriptor monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$20.00");
    });
  });

  context(@"one-time-payment subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.OneTimePayment"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter priceTextForSubscription:descriptor monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$20.00");
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter priceTextForSubscription:descriptor monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$20.00");
    });
  });
});

context(@"full price text", ^{
  beforeEach(^{
    priceInfo = [[BZRProductPriceInfo alloc] initWithDictionary:@{
      @"price": [[NSDecimalNumber alloc] initWithString:@"10"],
      @"fullPrice": [[NSDecimalNumber alloc] initWithString:@"50"],
      @"localeIdentifier": @"en_US"
    } error:nil];
  });

  it(@"should raise if the subscription descriptor's price information is nil", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.UnknownPeriod"
                  discountPercentage:0 productsInfoProvider:productsInfoProvider];
    expect(^{
      [formatter fullPriceTextForSubscription:descriptor monthlyFormat:YES];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if the product period is unsupported and monthly format is YES", ^{
    descriptor = OCMPartialMock([[SPXSubscriptionDescriptor alloc]
                                 initWithProductIdentifier:@"com.lightricks.Shopix.UnknownPeriod"
                                 discountPercentage:0 productsInfoProvider:productsInfoProvider]);
    descriptor.priceInfo = priceInfo;
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitDays),
      @"unitCount": @1
    } error:nil];
    OCMStub([descriptor billingPeriod]).andReturn(billingPeriod);

    expect(^{
      [formatter fullPriceTextForSubscription:descriptor monthlyFormat:YES];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should prefer full price from priceInfo over a custom discount percentage", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.Monthly"
                  discountPercentage:0.5 productsInfoProvider:productsInfoProvider];
    descriptor.priceInfo = priceInfo;
    auto priceText = [formatter fullPriceTextForSubscription:descriptor monthlyFormat:NO];

    expect([priceText string]).to.equal(@"$50.00");
  });

  it(@"should be colored by the given full price text color", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.Monthly"
                  discountPercentage:0 productsInfoProvider:productsInfoProvider];
    descriptor.priceInfo = priceInfo;
    auto fullPriceText = [formatter fullPriceTextForSubscription:descriptor monthlyFormat:NO];
    UIColor *fullPriceTextColor = [fullPriceText attribute:NSForegroundColorAttributeName
                                                   atIndex:0 longestEffectiveRange:nil
                                                   inRange:NSMakeRange(0, fullPriceText.length)];

    expect(fullPriceTextColor).to.equal([UIColor whiteColor]);
  });

  it(@"should the text be strike-through", ^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.Monthly"
                  discountPercentage:0 productsInfoProvider:productsInfoProvider];
    descriptor.priceInfo = priceInfo;
    auto fullPriceText = [formatter fullPriceTextForSubscription:descriptor monthlyFormat:NO];
    NSNumber *isStrikeThrough =
        [fullPriceText attribute:NSStrikethroughStyleAttributeName atIndex:0
           longestEffectiveRange:nil inRange:NSMakeRange(0, fullPriceText.length)];

    expect(isStrikeThrough.boolValue).to.beTruthy();
  });

  context(@"monthly subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.Monthly"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should not divide the price and contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter fullPriceTextForSubscription:descriptor monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$50.00/mo");
    });

    it(@"should not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter fullPriceTextForSubscription:descriptor monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$50.00");
    });
  });

  context(@"bi-yearly subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.BiYearly"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should divide the price by 6 and contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter fullPriceTextForSubscription:descriptor monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$8.33/mo");
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter fullPriceTextForSubscription:descriptor monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$50.00");
    });
  });

  context(@"yearly subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.Yearly"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should divide the price by 12 and contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter fullPriceTextForSubscription:descriptor monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$4.16/mo");
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter fullPriceTextForSubscription:descriptor monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$50.00");
    });
  });

  context(@"one-time-payment subscription", ^{
    beforeEach(^{
      descriptor = [[SPXSubscriptionDescriptor alloc]
                    initWithProductIdentifier:@"com.lightricks.Shopix.OneTimePayment"
                    discountPercentage:0 productsInfoProvider:productsInfoProvider];
      descriptor.priceInfo = priceInfo;
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter fullPriceTextForSubscription:descriptor monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$50.00");
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter fullPriceTextForSubscription:descriptor monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$50.00");
    });
  });
});

context(@"full price text from custom discount", ^{
  beforeEach(^{
    descriptor = [[SPXSubscriptionDescriptor alloc]
                  initWithProductIdentifier:@"com.lightricks.Shopix.Yearly"
                  discountPercentage:10 productsInfoProvider:productsInfoProvider];
    descriptor.priceInfo = [[BZRProductPriceInfo alloc] initWithDictionary:@{
      @"price": [[NSDecimalNumber alloc] initWithString:@"10"],
      @"localeIdentifier": @"en_US"
    } error:nil];
  });

  it(@"should divide the price by 12 and contain monthly suffix if monthly format is YES", ^{
    auto priceText = [formatter fullPriceTextForSubscription:descriptor monthlyFormat:YES];

    expect([priceText string]).to.equal(@"$0.99/mo");
  });

  it(@"should not divide the price and not contain monthly suffix if monthly format is NO", ^{
    auto priceText = [formatter fullPriceTextForSubscription:descriptor monthlyFormat:NO];

    expect([priceText string]).to.equal(@"$11.99");
  });
});

SpecEnd

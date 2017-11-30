// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionButtonFormatter.h"

#import <Bazaar/BZRProductPriceInfo.h>

SpecBegin(SPXSubscriptionButtonFormatter)

__block SPXSubscriptionButtonFormatter *formatter;
__block BZRProductPriceInfo *priceInfo;
__block NSString *productIdentifier;

beforeEach(^{
  formatter = [[SPXSubscriptionButtonFormatter alloc] initWithPeriodTextColor:[UIColor redColor]
                                                               priceTextColor:[UIColor blueColor]
                                                           fullPriceTextColor:[UIColor whiteColor]];
});

context(@"period text", ^{
  it(@"should raise if the product period is unknown", ^{
    productIdentifier = @"com.lightricks.Shopix.UnknownPeriod";
    expect(^{
      [formatter periodTextForSubscription:productIdentifier monthlyFormat:NO];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should be colored by the given period text color", ^{
    productIdentifier = @"com.lightricks.Shopix.Monthly";
    auto periodText = [formatter periodTextForSubscription:productIdentifier monthlyFormat:NO];
    UIColor *periodTextColor = [periodText attribute:NSForegroundColorAttributeName atIndex:0
                               longestEffectiveRange:nil inRange:NSMakeRange(0, periodText.length)];

    expect(periodTextColor).to.equal([UIColor redColor]);
  });

  it(@"should always display monthly period text in months", ^{
    productIdentifier = @"com.lightricks.Shopix.Monthly";
    auto periodText = [formatter periodTextForSubscription:productIdentifier monthlyFormat:NO];
    auto periodTextMonthly = [formatter periodTextForSubscription:productIdentifier
                                                   monthlyFormat:YES];

    expect([periodText string]).to.equal(@"1\nMonth");
    expect([periodTextMonthly string]).to.equal(@"1\nMonth");
  });

  it(@"should always display bi-yearly period in months", ^{
    productIdentifier = @"com.lightricks.Shopix.BiYearly";
    auto periodText = [formatter periodTextForSubscription:productIdentifier monthlyFormat:NO];
    auto periodTextMonthly = [formatter periodTextForSubscription:productIdentifier
                                                   monthlyFormat:YES];

    expect([periodText string]).to.equal(@"6\nMonths");
    expect([periodTextMonthly string]).to.equal(@"6\nMonths");
  });

  it(@"should display the period in years if monthly format is NO and the period is yearly", ^{
    productIdentifier = @"com.lightricks.Shopix.Yearly";
    auto periodText = [formatter periodTextForSubscription:productIdentifier monthlyFormat:NO];

    expect([periodText string]).to.equal(@"1\nYear");
  });

  it(@"should display the period in months if monthly format is YES and the period is yearly", ^{
    productIdentifier = @"com.lightricks.Shopix.Yearly";
    auto periodText = [formatter periodTextForSubscription:productIdentifier monthlyFormat:YES];

    expect([periodText string]).to.equal(@"12\nMonths");
  });

  it(@"should always display one-time-purchase text if the period is one-time-payment", ^{
    productIdentifier = @"com.lightricks.Shopix.OneTimePayment";
    auto periodText = [formatter periodTextForSubscription:productIdentifier monthlyFormat:NO];
    auto periodTextMonthly = [formatter periodTextForSubscription:productIdentifier
                                                   monthlyFormat:YES];

    expect([periodText string]).to.equal(@"One-Time\nPurchase");
    expect([periodTextMonthly string]).to.equal(@"One-Time\nPurchase");
  });
});

context(@"price text", ^{
  beforeEach(^{
    priceInfo = OCMClassMock([BZRProductPriceInfo class]);
    OCMStub([priceInfo localeIdentifier]).andReturn(@"en_US");
    OCMStub([priceInfo price]).andReturn([[NSDecimalNumber alloc] initWithString:@"20"]);
  });

  it(@"should raise if the product period is unknown and monthly format is YES", ^{
    productIdentifier = @"com.lightricks.Shopix.UnknownPeriod";
    expect(^{
      [formatter priceTextForSubscription:productIdentifier priceInfo:priceInfo
                            monthlyFormat:YES];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should be colored by the given price text color", ^{
    productIdentifier = @"com.lightricks.Shopix.Monthly";
    auto priceText = [formatter priceTextForSubscription:productIdentifier priceInfo:priceInfo
                                           monthlyFormat:NO];
    UIColor *priceTextColor = [priceText attribute:NSForegroundColorAttributeName atIndex:0
                               longestEffectiveRange:nil inRange:NSMakeRange(0, priceText.length)];

    expect(priceTextColor).to.equal([UIColor blueColor]);
  });

  context(@"monthly subscription", ^{
    beforeEach(^{
      productIdentifier = @"com.lightricks.Shopix.Monthly";
    });

    it(@"should not divide the price and contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter priceTextForSubscription:productIdentifier priceInfo:priceInfo
                                             monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$20.00/mo");
    });

    it(@"should not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter priceTextForSubscription:productIdentifier priceInfo:priceInfo
                                             monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$20.00");
    });
  });

  context(@"bi-yearly subscription", ^{
    beforeEach(^{
      productIdentifier = @"com.lightricks.Shopix.BiYearly";
    });

    it(@"should divide the price by 6 and contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter priceTextForSubscription:productIdentifier priceInfo:priceInfo
                                             monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$3.33/mo");
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter priceTextForSubscription:productIdentifier priceInfo:priceInfo
                                             monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$20.00");
    });
  });

  context(@"yearly subscription", ^{
    beforeEach(^{
      productIdentifier = @"com.lightricks.Shopix.Yearly";
    });

    it(@"should divide the price by 12 and contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter priceTextForSubscription:productIdentifier priceInfo:priceInfo
                                             monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$1.66/mo");
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter priceTextForSubscription:productIdentifier priceInfo:priceInfo
                                             monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$20.00");
    });
  });

  context(@"one-time-payment subscription", ^{
    beforeEach(^{
      productIdentifier = @"com.lightricks.Shopix.OneTimePayment";
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter priceTextForSubscription:productIdentifier priceInfo:priceInfo
                                             monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$20.00");
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter priceTextForSubscription:productIdentifier priceInfo:priceInfo
                                             monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$20.00");
    });
  });
});

context(@"full price text", ^{
  beforeEach(^{
    priceInfo = OCMClassMock([BZRProductPriceInfo class]);
    OCMStub([priceInfo localeIdentifier]).andReturn(@"en_US");
    OCMStub([priceInfo fullPrice]).andReturn([[NSDecimalNumber alloc] initWithString:@"50"]);
  });

  it(@"should raise if the product period is unknown and monthly format is YES", ^{
    productIdentifier = @"com.lightricks.Shopix.UnknownPeriod";
    expect(^{
      [formatter fullPriceTextForSubscription:productIdentifier priceInfo:priceInfo
                                monthlyFormat:YES];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should be colored by the given full price text color", ^{
    productIdentifier = @"com.lightricks.Shopix.Monthly";
    auto fullPriceText = [formatter fullPriceTextForSubscription:productIdentifier
                                                       priceInfo:priceInfo monthlyFormat:NO];
    UIColor *fullPriceTextColor = [fullPriceText attribute:NSForegroundColorAttributeName
                                                   atIndex:0 longestEffectiveRange:nil
                                                   inRange:NSMakeRange(0, fullPriceText.length)];

    expect(fullPriceTextColor).to.equal([UIColor whiteColor]);
  });

  it(@"should the text be strike-through", ^{
    productIdentifier = @"com.lightricks.Shopix.Monthly";
    auto fullPriceText = [formatter fullPriceTextForSubscription:productIdentifier
                                                       priceInfo:priceInfo monthlyFormat:NO];
    NSNumber *isStrikeThrough =
        [fullPriceText attribute:NSStrikethroughStyleAttributeName atIndex:0
           longestEffectiveRange:nil inRange:NSMakeRange(0, fullPriceText.length)];

    expect(isStrikeThrough.boolValue).to.beTruthy();
  });

  context(@"monthly subscription", ^{
    beforeEach(^{
      productIdentifier = @"com.lightricks.Shopix.Monthly";
    });

    it(@"should not divide the price and contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter fullPriceTextForSubscription:productIdentifier priceInfo:priceInfo
                                                 monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$50.00/mo");
    });

    it(@"should not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter fullPriceTextForSubscription:productIdentifier priceInfo:priceInfo
                                                 monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$50.00");
    });
  });

  context(@"bi-yearly subscription", ^{
    beforeEach(^{
      productIdentifier = @"com.lightricks.Shopix.BiYearly";
    });

    it(@"should divide the price by 6 and contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter fullPriceTextForSubscription:productIdentifier priceInfo:priceInfo
                                                 monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$8.33/mo");
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter fullPriceTextForSubscription:productIdentifier priceInfo:priceInfo
                                                 monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$50.00");
    });
  });

  context(@"yearly subscription", ^{
    beforeEach(^{
      productIdentifier = @"com.lightricks.Shopix.Yearly";
    });

    it(@"should divide the price by 12 and contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter fullPriceTextForSubscription:productIdentifier priceInfo:priceInfo
                                                 monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$4.16/mo");
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter fullPriceTextForSubscription:productIdentifier priceInfo:priceInfo
                                                 monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$50.00");
    });
  });

  context(@"one-time-payment subscription", ^{
    beforeEach(^{
      productIdentifier = @"com.lightricks.Shopix.OneTimePayment";
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is YES", ^{
      auto priceText = [formatter fullPriceTextForSubscription:productIdentifier priceInfo:priceInfo
                                                 monthlyFormat:YES];

      expect([priceText string]).to.equal(@"$50.00");
    });

    it(@"should not divide the price and not contain monthly suffix if monthly format is NO", ^{
      auto priceText = [formatter fullPriceTextForSubscription:productIdentifier priceInfo:priceInfo
                                                 monthlyFormat:NO];

      expect([priceText string]).to.equal(@"$50.00");
    });
  });
});

SpecEnd

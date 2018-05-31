// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRBillingPeriod+Shopix.h"

#import <Bazaar/BZRBillingPeriod.h>

SpecBegin(BZRBillingPeriod_Shopix)

it(@"should parse the monthly billing period from product identifier", ^{
  auto billingPeriod = [BZRBillingPeriod spx_billingPeriodWithProductIdentifier:@"com.spx.1M"];

  expect(billingPeriod.unit).to.equal($(BZRBillingPeriodUnitMonths));
  expect(billingPeriod.unitCount).to.equal(1);
});

it(@"should parse the yearly billing period from product identifier", ^{
  auto billingPeriod = [BZRBillingPeriod spx_billingPeriodWithProductIdentifier:@"com.spx.6M"];

  expect(billingPeriod.unit).to.equal($(BZRBillingPeriodUnitMonths));
  expect(billingPeriod.unitCount).to.equal(6);
});

it(@"should parse the yearly billing period from product identifier", ^{
  auto billingPeriod = [BZRBillingPeriod spx_billingPeriodWithProductIdentifier:@"com.spx.1Y"];

  expect(billingPeriod.unit).to.equal($(BZRBillingPeriodUnitYears));
  expect(billingPeriod.unitCount).to.equal(1);
});

it(@"should parse the billing period from the last group in the product identifier", ^{
  auto billingPeriod =
      [BZRBillingPeriod spx_billingPeriodWithProductIdentifier:@"com.spx.1M_1Y.foo"];

  expect(billingPeriod.unit).to.equal($(BZRBillingPeriodUnitYears));
  expect(billingPeriod.unitCount).to.equal(1);
});

it(@"should return billing period nil", ^{
  auto billingPeriod = [BZRBillingPeriod spx_billingPeriodWithProductIdentifier:@"com.spx.OTP"];

  expect(billingPeriod).to.beNil();
});

context(@"old product identifier format", ^{
  it(@"should parse the monthly billing period from product identifier", ^{
    auto billingPeriod =
        [BZRBillingPeriod spx_billingPeriodWithProductIdentifier:@"com.spx.Monthly"];

    expect(billingPeriod.unit).to.equal($(BZRBillingPeriodUnitMonths));
    expect(billingPeriod.unitCount).to.equal(1);
  });

  it(@"should parse the yearly billing period from product identifier", ^{
    auto billingPeriod =
        [BZRBillingPeriod spx_billingPeriodWithProductIdentifier:@"com.spx.BiYearly"];

    expect(billingPeriod.unit).to.equal($(BZRBillingPeriodUnitMonths));
    expect(billingPeriod.unitCount).to.equal(6);
  });

  it(@"should parse the yearly billing period from product identifier", ^{
    auto billingPeriod =
        [BZRBillingPeriod spx_billingPeriodWithProductIdentifier:@"com.spx.Yearly"];

    expect(billingPeriod.unit).to.equal($(BZRBillingPeriodUnitYears));
    expect(billingPeriod.unitCount).to.equal(1);
  });

  it(@"should return billing period nil", ^{
    auto billingPeriod =
        [BZRBillingPeriod spx_billingPeriodWithProductIdentifier:@"com.spx.OneTimePayment"];

    expect(billingPeriod).to.beNil();
  });
});

context(@"billing period string", ^{
  it(@"should return yearly period string in months if inMonths is YES", ^{
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitYears),
      @"unitCount": @1
    } error:nil];

    expect([billingPeriod spx_billingPeriodString:YES]).to.equal(@"Months");
  });

  it(@"should return yearly period string in years if inMonths is NO", ^{
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitYears),
      @"unitCount": @2
    } error:nil];

    expect([billingPeriod spx_billingPeriodString:NO]).to.equal(@"Years");
  });

  it(@"should return monthly period string in months", ^{
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitMonths),
      @"unitCount": @1
    } error:nil];

    expect([billingPeriod spx_billingPeriodString:YES]).to.equal(@"Month");
    expect([billingPeriod spx_billingPeriodString:NO]).to.equal(@"Month");
  });

  it(@"should return months period string in months", ^{
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitMonths),
      @"unitCount": @6
    } error:nil];

    expect([billingPeriod spx_billingPeriodString:YES]).to.equal(@"Months");
    expect([billingPeriod spx_billingPeriodString:NO]).to.equal(@"Months");
  });

  it(@"should return weekly period string in weeks", ^{
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitWeeks),
      @"unitCount": @1
    } error:nil];

    expect([billingPeriod spx_billingPeriodString:YES]).to.equal(@"Week");
    expect([billingPeriod spx_billingPeriodString:NO]).to.equal(@"Week");
  });

  it(@"should return weeks period string in weeks", ^{
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitWeeks),
      @"unitCount": @2
    } error:nil];

    expect([billingPeriod spx_billingPeriodString:YES]).to.equal(@"Weeks");
    expect([billingPeriod spx_billingPeriodString:NO]).to.equal(@"Weeks");
  });

  it(@"should return daily period string in days", ^{
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitDays),
      @"unitCount": @1
    } error:nil];

    expect([billingPeriod spx_billingPeriodString:YES]).to.equal(@"Day");
    expect([billingPeriod spx_billingPeriodString:NO]).to.equal(@"Day");
  });

  it(@"should return days period string in days", ^{
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitDays),
      @"unitCount": @2
    } error:nil];

    expect([billingPeriod spx_billingPeriodString:YES]).to.equal(@"Days");
    expect([billingPeriod spx_billingPeriodString:NO]).to.equal(@"Days");
  });
});

context(@"billing period count in months", ^{
  it(@"should return months period count in months", ^{
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitMonths),
      @"unitCount": @6
    } error:nil];

    expect([billingPeriod spx_numberOfMonthsInPeriod]).to.equal(6);
  });

  it(@"should return yearly period count in months", ^{
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitYears),
      @"unitCount": @2
    } error:nil];

    expect([billingPeriod spx_numberOfMonthsInPeriod]).to.equal(24);
  });

  it(@"should return zero if the period unit is smaller than month", ^{
    auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @"unit": $(BZRBillingPeriodUnitWeeks),
      @"unitCount": @1
    } error:nil];

    expect([billingPeriod spx_numberOfMonthsInPeriod]).to.equal(0);
  });
});

SpecEnd

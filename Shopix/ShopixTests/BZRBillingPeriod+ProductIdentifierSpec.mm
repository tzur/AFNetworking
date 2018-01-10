// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRBillingPeriod+ProductIdentifier.h"

#import <Bazaar/BZRBillingPeriod.h>

SpecBegin(BZRBillingPeriod_ProductIdentifier)

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

it(@"should take the last period component from the product identifier", ^{
  auto billingPeriod =
      [BZRBillingPeriod spx_billingPeriodWithProductIdentifier:@"com.spx.1M.1Y.foo"];

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

SpecEnd

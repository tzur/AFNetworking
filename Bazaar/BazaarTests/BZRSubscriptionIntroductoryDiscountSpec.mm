// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRSubscriptionIntroductoryDiscount.h"

#import "BZRBillingPeriod.h"

SpecBegin(BZRSubscriptionIntroductoryDiscount)

it(@"should correctly calculate the full duration of the introductory discount", ^{
  auto billingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
    @instanceKeypath(BZRBillingPeriod, unit): $(BZRBillingPeriodUnitMonths),
    @instanceKeypath(BZRBillingPeriod, unitCount): @2
  } error:nil];
  auto introductoryDiscount = [[BZRSubscriptionIntroductoryDiscount alloc] initWithDictionary:@{
    @instanceKeypath(BZRSubscriptionIntroductoryDiscount, discountType):
        $(BZRIntroductoryDiscountTypePayAsYouGo),
    @instanceKeypath(BZRSubscriptionIntroductoryDiscount, price): [NSDecimalNumber one],
    @instanceKeypath(BZRSubscriptionIntroductoryDiscount, billingPeriod): billingPeriod,
    @instanceKeypath(BZRSubscriptionIntroductoryDiscount, numberOfPeriods): @6
  } error:nil];

  expect(introductoryDiscount.duration.unit).to.equal($(BZRBillingPeriodUnitMonths));
  expect(introductoryDiscount.duration.unitCount).to.equal(12);
});

SpecEnd

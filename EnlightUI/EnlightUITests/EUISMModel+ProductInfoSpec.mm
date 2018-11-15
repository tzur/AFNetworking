// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMModel+ProductInfo.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProduct.h>

#import "EUISMModel+Test.h"

SpecBegin(EUISMModel_ProductInfo)

context(@"currentProductInfo", ^{
  it(@"should return the product of the current subscription if no pending subscription", ^{
    auto productID = @"product id";
    auto model = [EUISMModel modelWithCurrentProductID:productID];

    auto currentProductInfo = [model currentProductInfo];

    expect(currentProductInfo.product.identifier).to.equal(productID);
  });

  it(@"should return the product of the pending subscription if available", ^{
    auto pendingProductID = @"pending";
    auto model = [EUISMModel modelWithPendingProductID:pendingProductID];

    auto currentProductInfo = [model currentProductInfo];

    expect(currentProductInfo.product.identifier).to.equal(pendingProductID);
  });

  it(@"should return nil if the user is not subscribed", ^{
    auto model = [EUISMModel modelWithNoSubscription];

    auto currentProductInfo = [model currentProductInfo];

    expect(currentProductInfo).to.beNil();
  });
});

context(@"currentProductInfo", ^{
  it(@"should return yearly product if available and current subscription is monthly", ^{
    auto billingPeriod = [BZRBillingPeriod eui_billingPeriodMonthly];
    auto model = [EUISMModel modelWithAvailableYearlyUpradeSavePercent:50
                                                         billingPeriod:billingPeriod];

    auto currentProductInfo = [model promotedProductInfo];

    expect(currentProductInfo.product.billingPeriod.unit.value).to.equal(BZRBillingPeriodUnitYears);
  });

  it(@"should return nil if no yearly upgrade available", ^{
    auto billingPeriod = [BZRBillingPeriod eui_billingPeriodMonthly];
    auto model = [EUISMModel modelWithBillingPeriod:billingPeriod expired:NO];

    auto currentProductInfo = [model promotedProductInfo];

    expect(currentProductInfo).to.beNil();
  });

  it(@"should return nil if yearly upgrade available and current subscription is yearly", ^{
    auto billingPeriod = [BZRBillingPeriod eui_billingPeriodYearly];
    auto model = [EUISMModel modelWithAvailableYearlyUpradeSavePercent:50
                                                         billingPeriod:billingPeriod];

    auto currentProductInfo = [model promotedProductInfo];

    expect(currentProductInfo).to.beNil();
  });
});

SpecEnd

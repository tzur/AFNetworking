// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMModel+ProductInfo.h"

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

SpecEnd

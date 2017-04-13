// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct+EnablesProduct.h"

#import "BZRTestUtils.h"

SpecBegin(BZRProduct_EnablesProduct)

context(@"enables products", ^{
  it(@"should return NO if subscription product doesn't enable product", ^{
    BZRProduct *subscriptionProduct = [BZRProductWithIdentifier(@"subscriptionProduct")
        modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts) withValue:@[]];

    expect([subscriptionProduct doesProductEnablesProductWithIdentifier:@"foo"]).to.equal(NO);
  });

  it(@"should return YES if subscription product enablesProduct is nil", ^{
    BZRProduct *subscriptionProduct = BZRProductWithIdentifier(@"subscriptionProduct");

    expect([subscriptionProduct doesProductEnablesProductWithIdentifier:@"foo"]).to.equal(YES);
  });

  it(@"should return YES if subscription product enables product", ^{
    BZRProduct *subscriptionProduct = [BZRProductWithIdentifier(@"subscriptionProduct")
        modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts)
                        withValue:@[@"foo"]];

    expect([subscriptionProduct doesProductEnablesProductWithIdentifier:@"foo"]).to.equal(YES);
  });
});

SpecEnd

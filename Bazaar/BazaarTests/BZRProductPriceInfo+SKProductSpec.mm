// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductPriceInfo+SKProduct.h"

SpecBegin(BZRProductPriceInfo_SKProduct)

context(@"creating product price info from SKProduct", ^{
  it(@"should create product price info with correct price", ^{
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"fr_FR"];
    NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:@"1337.13"];
    SKProduct *product = OCMClassMock([SKProduct class]);
    OCMStub([product priceLocale]).andReturn(locale);
    OCMStub([product price]).andReturn(price);

    BZRProductPriceInfo *priceInfo = [BZRProductPriceInfo productPriceInfoWithSKProduct:product];

    expect(priceInfo.localizedPrice).to.equal(@"1 337,13 €");
    expect(priceInfo.price).to.equal(price);
    expect(priceInfo.currencyCode).to.equal(@"EUR");
  });
});

SpecEnd

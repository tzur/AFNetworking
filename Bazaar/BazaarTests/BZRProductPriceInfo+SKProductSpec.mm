// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductPriceInfo+SKProduct.h"

SpecBegin(BZRProductPriceInfo_SKProduct)

context(@"creating product price info from SKProduct", ^{
  it(@"should create product price info with correct price", ^{
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"fr_FR"];
    NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:@"1337.1337"];
    SKProduct *product = OCMClassMock([SKProduct class]);
    OCMStub([product priceLocale]).andReturn(locale);
    OCMStub([product price]).andReturn(price);

    BZRProductPriceInfo *priceInfo = [BZRProductPriceInfo productPriceInfoWithSKProduct:product];

    expect(priceInfo.price).to.equal(price);
    expect(priceInfo.localeIdentifier).to.equal(@"fr_FR");
  });
});

SpecEnd

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "NSDecimalNumber+Localization.h"

SpecBegin(NSDecimalNumber_Localization)

context(@"localized price", ^{
  it(@"should return a localized price with currency sign at the right side", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"69.99"];
    expect([decimal spx_localizedPriceForLocale:@"fr_FR"]).to.equal(@"69,99 €");
  });

  it(@"should return a localized price with currency sign at the left side", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"69.99"];
    expect([decimal spx_localizedPriceForLocale:@"en_US"]).to.equal(@"$69.99");
  });

  it(@"should return a decimal with precision of two for a given integer", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"100"];
    expect([decimal spx_localizedPriceForLocale:@"en_US"]).to.equal(@"$100.00");
  });

  it(@"should trim the third digit onwards", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"2500.102345"];
    expect([decimal spx_localizedPriceForLocale:@"en_IN"]).to.equal(@"₹ 2,500.10");
  });

  it(@"should return the price with the third decimal places onwards trimmed", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"20.998999999999999"];
    expect([decimal spx_localizedPriceForLocale:@"en_US"]).to.equal(@"$20.99");
  });
});

context(@"divided localized price", ^{
  it(@"should raise exception if the divisor is zero", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"1.00"];
    expect(^{
      [decimal spx_localizedPriceForLocale:@"de_DE" dividedBy:0];
    }).raise(NSDecimalNumberDivideByZeroException);
  });

  it(@"should return the price with the correct division result", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"12.00"];
    expect([decimal spx_localizedPriceForLocale:@"de_DE" dividedBy:3]).to.equal(@"4,00 €");
  });

  it(@"should return the price divided by large a number", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"0.3"];
    expect([decimal spx_localizedPriceForLocale:@"en_GB" dividedBy:30]).to.equal(@"£0.01");
  });

  it(@"should return the price with the third decimal places onwards trimmed", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"15.99"];
    expect([decimal spx_localizedPriceForLocale:@"de_DE" dividedBy:12]).to.equal(@"1,33 €");
  });
});

context(@"localized full price", ^{
  it(@"should raise exception if the divisor is zero", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"1.00"];
    expect(^{
      [decimal spx_localizedFullPriceForLocale:@"de_DE" discountPercentage:0 dividedBy:0];
    }).raise(NSDecimalNumberDivideByZeroException);
  });

  it(@"should raise if the discount percentage in equal to 100", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"1.00"];
    expect(^{
      [decimal spx_localizedFullPriceForLocale:@"de_DE" discountPercentage:100 dividedBy:0];
    }).raise(NSInvalidArgumentException);
  });

  it(@"should return a localized price rounded up without division if the divisor is one", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"4.5"];
    expect([decimal spx_localizedFullPriceForLocale:@"en_US" discountPercentage:0 dividedBy:1])
        .to.equal(@"$4.99");
  });

  it(@"should return a localized price without subtracting if the price in an integer", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"12.00"];
    expect([decimal spx_localizedFullPriceForLocale:@"de_DE" discountPercentage:0 dividedBy:2])
        .to.equal(@"6,00 €");
  });

  it(@"should return a localized price with the correct division result", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"7.90"];
    expect([decimal spx_localizedFullPriceForLocale:@"de_DE" discountPercentage:0 dividedBy:3])
        .to.equal(@"2,99 €");
  });

  it(@"should return a localized price with the correct discount calcuation", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"3.99"];
    expect([decimal spx_localizedFullPriceForLocale:@"de_DE" discountPercentage:50 dividedBy:1])
        .to.equal(@"7,99 €");
  });

  it(@"should return a localized price with the correct discount calcuation and division result", ^{
    auto decimal = [NSDecimalNumber decimalNumberWithString:@"3.99"];
    expect([decimal spx_localizedFullPriceForLocale:@"de_DE" discountPercentage:25 dividedBy:2])
        .to.equal(@"2,99 €");
  });
});

SpecEnd

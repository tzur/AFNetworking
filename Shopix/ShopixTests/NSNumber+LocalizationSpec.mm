// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "NSNumber+Localization.h"

SpecBegin(NSNumber_Localization)

it(@"should return a localized price with currency sign at the correct side", ^{
  expect([@(20.99) spx_localizedPriceForLocale:@"en_US"]).to.equal(@"$20.99");
  expect([@(20.00) spx_localizedPriceForLocale:@"fr_FR"]).to.equal(@"20,00 €");
});

it(@"should trim the third digit onwards", ^{
  expect([@(20.99999) spx_localizedPriceForLocale:@"en_US"]).to.equal(@"$20.99");
});

it(@"should raise exception if the divisor is zero", ^{
  expect(^{
    [@(1.00) spx_localizedPriceForLocale:@"de_DE" dividedBy:0];
  }).raise(NSInvalidArgumentException);
});

it(@"should return the calculated price devided by number of months", ^{
  expect([@(12.00) spx_localizedPriceForLocale:@"de_DE" dividedBy:3]).to.equal(@"4,00 €");
});

it(@"should return the calculated price with the third decimal places onwards trimmed", ^{
  expect([@(15.99) spx_localizedPriceForLocale:@"de_DE" dividedBy:12]).to.equal(@"1,33 €");
});

SpecEnd

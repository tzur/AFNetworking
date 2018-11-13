// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTDateProvider.h"

SpecBegin(LTTimeProvider)

it(@"should return a valid time provider", ^{
  expect([LTDateProvider dateProvider]).notTo.beNil();
});

it(@"should return a valid current time", ^{
  expect([[[LTDateProvider alloc] init] currentDate]).notTo.beNil();
});

SpecEnd

// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "UIScreen+Physical.h"

SpecBegin(UIScreen_Physical)

__block id screen;

beforeEach(^{
  screen = OCMPartialMock([UIScreen mainScreen]);
});

afterEach(^{
  screen = nil;
});

it(@"should return correct points per inch", ^{
  OCMStub([screen nativeScale]).andReturn(2);

  expect([screen lt_pointsPerInchForPixelsPerInch:200]).to.equal(100);
  expect([screen lt_pointsPerInchForPixelsPerInch:400]).to.equal(200);
});

SpecEnd

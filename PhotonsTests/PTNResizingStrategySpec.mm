// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNResizingStrategy.h"

SpecBegin(PTNIdentityResizingStrategy)

__block PTNIdentityResizingStrategy *strategy;

beforeEach(^{
  strategy = [[PTNIdentityResizingStrategy alloc] init];
});

it(@"should return correct output size", ^{
  expect([strategy sizeForInputSize:CGSizeMake(100, 100)]).to.equal(CGSizeMake(100, 100));
  expect([strategy sizeForInputSize:CGSizeMake(200, 50)]).to.equal(CGSizeMake(200, 50));
  expect([strategy sizeForInputSize:CGSizeMake(50, 200)]).to.equal(CGSizeMake(50, 200));
});

SpecEnd

SpecBegin(PTNMaxPixelsResizingStrategy)

__block PTNMaxPixelsResizingStrategy *strategy;

beforeEach(^{
  strategy = [[PTNMaxPixelsResizingStrategy alloc] initWithMaxPixels:1024 * 1024];
});

it(@"should return correct output size", ^{
  expect([strategy sizeForInputSize:CGSizeMake(1024, 1024)]).to.equal(CGSizeMake(1024, 1024));
  expect([strategy sizeForInputSize:CGSizeMake(512, 2048)]).to.equal(CGSizeMake(512, 2048));
  expect([strategy sizeForInputSize:CGSizeMake(2048, 2048)]).to.equal(CGSizeMake(1024, 1024));
  expect([strategy sizeForInputSize:CGSizeMake(1024, 4096)]).to.equal(CGSizeMake(512, 2048));
});

SpecEnd

SpecBegin(PTNAspectFitResizingStrategy)

__block PTNAspectFitResizingStrategy *strategy;

beforeEach(^{
  strategy = [[PTNAspectFitResizingStrategy alloc] initWithSize:CGSizeMake(20, 10)];
});

it(@"should return correct output size", ^{
  expect([strategy sizeForInputSize:CGSizeMake(20, 10)]).to.equal(CGSizeMake(20, 10));
  expect([strategy sizeForInputSize:CGSizeMake(5, 10)]).to.equal(CGSizeMake(5, 10));
  expect([strategy sizeForInputSize:CGSizeMake(5, 5)]).to.equal(CGSizeMake(10, 10));
  expect([strategy sizeForInputSize:CGSizeMake(40, 20)]).to.equal(CGSizeMake(20, 10));
  expect([strategy sizeForInputSize:CGSizeMake(40, 10)]).to.equal(CGSizeMake(20, 5));
});

it(@"should round output size", ^{
  expect([strategy sizeForInputSize:CGSizeMake(40.1, 10)]).to.equal(CGSizeMake(20, 5));
});

SpecEnd

SpecBegin(PTNAspectFillResizingStrategy)

__block PTNAspectFillResizingStrategy *strategy;

beforeEach(^{
  strategy = [[PTNAspectFillResizingStrategy alloc] initWithSize:CGSizeMake(20, 10)];
});

it(@"should return correct output size", ^{
  expect([strategy sizeForInputSize:CGSizeMake(20, 10)]).to.equal(CGSizeMake(20, 10));
  expect([strategy sizeForInputSize:CGSizeMake(5, 10)]).to.equal(CGSizeMake(20, 40));
  expect([strategy sizeForInputSize:CGSizeMake(5, 5)]).to.equal(CGSizeMake(20, 20));
  expect([strategy sizeForInputSize:CGSizeMake(40, 20)]).to.equal(CGSizeMake(20, 10));
  expect([strategy sizeForInputSize:CGSizeMake(40, 10)]).to.equal(CGSizeMake(40, 10));
});

it(@"should round output size", ^{
  expect([strategy sizeForInputSize:CGSizeMake(40.1, 10)]).to.equal(CGSizeMake(40, 10));
});

SpecEnd

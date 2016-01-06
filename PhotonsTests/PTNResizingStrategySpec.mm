// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNResizingStrategy.h"

SpecBegin(PTNResizingStrategy)

it(@"should return correct identity strategy", ^{
  id<PTNResizingStrategy> strategy = [PTNResizingStrategy identity];

  expect([strategy isKindOfClass:[PTNIdentityResizingStrategy class]]).to.beTruthy();
});

it(@"should return correct max pixels strategy", ^{
  id<PTNResizingStrategy> strategy = [PTNResizingStrategy maxPixels:1024 * 1024];

  expect([strategy isKindOfClass:[PTNMaxPixelsResizingStrategy class]]).to.beTruthy();
  expect([strategy sizeForInputSize:CGSizeMake(1024, 4096)]).to.equal(CGSizeMake(512, 2048));
});

it(@"should return correct aspect fit strategy", ^{
  id<PTNResizingStrategy> strategy = [PTNResizingStrategy aspectFit:CGSizeMake(20, 10)];

  expect([strategy isKindOfClass:[PTNAspectFitResizingStrategy class]]).to.beTruthy();
  expect([strategy sizeForInputSize:CGSizeMake(40, 10)]).to.equal(CGSizeMake(20, 5));
});

it(@"should return correct aspect fit strategy", ^{
  id<PTNResizingStrategy> strategy = [PTNResizingStrategy aspectFill:CGSizeMake(20, 10)];

  expect([strategy isKindOfClass:[PTNAspectFillResizingStrategy class]]).to.beTruthy();
  expect([strategy sizeForInputSize:CGSizeMake(40, 10)]).to.equal(CGSizeMake(40, 10));
});

it(@"should return correct content mode strategy", ^{
  id<PTNResizingStrategy> strategy = [PTNResizingStrategy
                                      contentMode:PTNImageContentModeAspectFill
                                      size:CGSizeMake(20, 10)];

  expect([strategy isKindOfClass:[PTNAspectFillResizingStrategy class]]).to.beTruthy();
  expect([strategy sizeForInputSize:CGSizeMake(40, 10)]).to.equal(CGSizeMake(40, 10));
});

SpecEnd

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

it(@"should not have a binding size", ^{
  expect([strategy inputSizeBoundedBySize:CGSizeMake(100, 100)]).to.beFalsy();
  expect([strategy inputSizeBoundedBySize:CGSizeMake(1024, 1024)]).to.beFalsy();
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

it(@"should be bound by sizes with both dimensions larger than max pixels", ^{
  expect([strategy inputSizeBoundedBySize:CGSizeMake(512, 512)]).to.beFalsy();
  expect([strategy inputSizeBoundedBySize:CGSizeMake(2048, 2048)]).to.beFalsy();
  expect([strategy inputSizeBoundedBySize:CGSizeMake(1024 * 1024, 1024 * 1024)]).to.beTruthy();
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

it(@"should be bound by sizes larger than strategy's size in both dimensions", ^{
  expect([strategy inputSizeBoundedBySize:CGSizeMake(10, 10)]).to.beFalsy();
  expect([strategy inputSizeBoundedBySize:CGSizeMake(19, 10)]).to.beFalsy();
  expect([strategy inputSizeBoundedBySize:CGSizeMake(20, 9)]).to.beFalsy();
  expect([strategy inputSizeBoundedBySize:CGSizeMake(20, 10)]).to.beTruthy();
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

it(@"should not have a binding size", ^{
  expect([strategy inputSizeBoundedBySize:CGSizeMake(20, 10)]).to.beFalsy();
  expect([strategy inputSizeBoundedBySize:CGSizeMake(1024, 1024)]).to.beFalsy();
});

SpecEnd

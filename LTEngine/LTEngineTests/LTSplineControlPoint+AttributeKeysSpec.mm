// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSplineControlPoint+AttributeKeys.h"

SpecBegin(LTSplineControlPoint_AttributeKeys)

it(@"should provide keys", ^{
  expect([LTSplineControlPoint keyForRadius]).toNot.beNil();
  expect([LTSplineControlPoint keyForForce]).toNot.beNil();
  expect([LTSplineControlPoint keyForSpeedInScreenCoordinates]).toNot.beNil();
});

it(@"should provide distinct keys", ^{
  NSArray<NSString *> *keys = @[
    [LTSplineControlPoint keyForRadius],
    [LTSplineControlPoint keyForForce],
    [LTSplineControlPoint keyForSpeedInScreenCoordinates]
  ];

  NSSet<NSString *> *setOfKeys = [NSSet setWithArray:keys];
  expect(setOfKeys).to.haveCountOf(keys.count);
});

SpecEnd

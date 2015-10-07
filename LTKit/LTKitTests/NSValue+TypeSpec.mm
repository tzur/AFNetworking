// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "NSValue+Type.h"

SpecBegin(NSValue_Type)

it(@"should test type accurately", ^{
  NSValue *intValue = [NSNumber numberWithInt:10];
  NSValue *doubleValue = [NSNumber numberWithDouble:10];
  NSValue *pointValue = $(CGPointZero);
  NSValue *sizeValue = $(CGSizeZero);
  NSValue *rectValue = $(CGRectZero);

  expect([intValue lt_isKindOfObjCType:@encode(int)]).to.beTruthy();
  expect([intValue lt_isKindOfObjCType:@encode(uint)]).to.beFalsy();

  expect([doubleValue lt_isKindOfObjCType:@encode(double)]).to.beTruthy();
  expect([doubleValue lt_isKindOfObjCType:@encode(float)]).to.beFalsy();

  expect([pointValue lt_isKindOfObjCType:@encode(CGPoint)]).to.beTruthy();
  expect([pointValue lt_isKindOfObjCType:@encode(CGSize)]).to.beFalsy();

  expect([sizeValue lt_isKindOfObjCType:@encode(CGSize)]).to.beTruthy();
  expect([sizeValue lt_isKindOfObjCType:@encode(CGPoint)]).to.beFalsy();

  expect([rectValue lt_isKindOfObjCType:@encode(CGRect)]).to.beTruthy();
  expect([rectValue lt_isKindOfObjCType:@encode(CGPoint)]).to.beFalsy();
});

SpecEnd

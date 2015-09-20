// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "NSValue+Type.h"

LTSpecBegin(NSValue_Type)

it(@"should test type accurately", ^{
  NSValue *intValue = [NSNumber numberWithInt:10];
  NSValue *doubleValue = [NSNumber numberWithDouble:10];
  NSValue *pointValue = $(CGPointZero);
  NSValue *sizeValue = $(CGSizeZero);
  NSValue *rectValue = $(CGRectZero);
  NSValue *vec2Value = $(LTVector2One);
  NSValue *vec3Value = $(LTVector3One);
  NSValue *vec4Value = $(LTVector4One);

  expect([intValue lt_isKindOfObjCType:NULL]).to.beFalsy();

  expect([intValue lt_isKindOfObjCType:@encode(int)]).to.beTruthy();
  expect([intValue lt_isKindOfObjCType:@encode(uint)]).to.beFalsy();

  expect([doubleValue lt_isKindOfObjCType:@encode(double)]).to.beTruthy();
  expect([doubleValue lt_isKindOfObjCType:@encode(float)]).to.beFalsy();

  expect([pointValue lt_isKindOfObjCType:@encode(CGPoint)]).to.beTruthy();
  expect([pointValue lt_isKindOfObjCType:@encode(CGSize)]).to.beFalsy();

  expect([sizeValue lt_isKindOfObjCType:@encode(CGSize)]).to.beTruthy();
  expect([sizeValue lt_isKindOfObjCType:@encode(CGPoint)]).to.beFalsy();

  expect([rectValue lt_isKindOfObjCType:@encode(CGRect)]).to.beTruthy();
  expect([rectValue lt_isKindOfObjCType:@encode(LTVector4)]).to.beFalsy();

  expect([vec2Value lt_isKindOfObjCType:@encode(LTVector2)]).to.beTruthy();
  expect([vec2Value lt_isKindOfObjCType:@encode(LTVector3)]).to.beFalsy();

  expect([vec3Value lt_isKindOfObjCType:@encode(LTVector3)]).to.beTruthy();
  expect([vec3Value lt_isKindOfObjCType:@encode(LTVector4)]).to.beFalsy();

  expect([vec4Value lt_isKindOfObjCType:@encode(LTVector4)]).to.beTruthy();
  expect([vec4Value lt_isKindOfObjCType:@encode(LTVector2)]).to.beFalsy();
});

LTSpecEnd

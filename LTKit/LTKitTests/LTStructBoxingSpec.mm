// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTStructBoxing.h"

typedef struct {
  NSUInteger a;
  CGFloat b;
  BOOL c;
} LTStructBoxingTest;

LTStructBoxingMake(LTStructBoxingTest);

SpecBegin(LTStructBoxing)

__block LTStructBoxingTest structTest;

beforeEach(^{
  structTest = {
    .a = 7,
    .b = 0.5,
    .c = YES
  };
});

it(@"should box with proper objCType", ^{
  NSValue *value = [NSValue valueWithLTStructBoxingTest:structTest];
  expect(@(value.objCType)).to.equal(@(@encode(LTStructBoxingTest)));
});

it(@"should box and unbox", ^{
  NSValue *value = [NSValue valueWithLTStructBoxingTest:structTest];
  LTStructBoxingTest unboxed = [value LTStructBoxingTestValue];

  expect(memcmp(&unboxed, &structTest, sizeof(LTStructBoxingTest))).to.equal(0);
});

it(@"should box with easy boxing", ^{
  NSValue *value = $(structTest);
  LTStructBoxingTest unboxed = [value LTStructBoxingTestValue];

  expect(memcmp(&unboxed, &structTest, sizeof(LTStructBoxingTest))).to.equal(0);
});

SpecEnd

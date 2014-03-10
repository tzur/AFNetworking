// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMathUtils.h"

SpecBegin(LTMathUtils)

context(@"power of two", ^{
  it(@"should return yes for power of two size", ^{
    expect(LTIsPowerOfTwo(CGSizeMake(64, 128))).to.beTruthy();
  });

  it(@"should return no when one of the dimensions is not a power of two", ^{
    expect(LTIsPowerOfTwo(CGSizeMake(64, 127))).to.beFalsy();
  });

  it(@"should return no when both dimensions are not a power of two", ^{
    expect(LTIsPowerOfTwo(CGSizeMake(63, 127))).to.beFalsy();
  });

  it(@"should return no when size is not integral", ^{
    expect(LTIsPowerOfTwo(CGSizeMake(63.25, 127.5))).to.beFalsy();
  });
});

SpecEnd

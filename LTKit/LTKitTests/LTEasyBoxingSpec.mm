// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEasyBoxing.h"

SpecBegin(LTEasyBoxing)

context(@"wrapping", ^{
  it(@"should box NSValueUIGeometryExtensions", ^{
    CGAffineTransform expected = CGAffineTransformMakeTranslation(1, -1);
    NSValue *value = $(expected);
    CGAffineTransform actual = [value CGAffineTransformValue];

    expect(CGAffineTransformEqualToTransform(expected, actual)).to.beTruthy();
  });

  it(@"should box CGPoint", ^{
    CGPoint expected = CGPointMake(-1, 1);
    NSValue *value = $(expected);
    CGPoint actual = [value CGPointValue];

    expect(expected).to.equal(actual);
  });

  it(@"should box CGRect", ^{
    CGRect expected = CGRectMake(5, -7, -1, 1);
    NSValue *value = $(expected);
    CGRect actual = [value CGRectValue];

    expect(expected).to.equal(actual);
  });

  it(@"should box CGSize", ^{
    CGSize expected = CGSizeMake(-1, 1);
    NSValue *value = $(expected);
    CGSize actual = [value CGSizeValue];

    expect(expected).to.equal(actual);
  });

  it(@"should box UIOffset", ^{
    UIOffset expected = UIOffsetMake(-1, 1);
    NSValue *value = $(expected);
    UIOffset actual = [value UIOffsetValue];

    expect(expected).to.equal(actual);
  });

  it(@"should box UIEdgeInsets", ^{
    UIEdgeInsets expected = UIEdgeInsetsMake(-5, 3, -1, 1);
    NSValue *value = $(expected);
    UIEdgeInsets actual = [value UIEdgeInsetsValue];

    expect(expected).to.equal(actual);
  });

  it(@"should box CATransform3D", ^{
    CATransform3D expected = CATransform3DMakeRotation(-M_PI_2, 1, 0.5, -1);
    NSValue *value = $(expected);
    CATransform3D actual = [value CATransform3DValue];

    expect(CATransform3DEqualToTransform(expected, actual)).to.beTruthy();
  });
});

SpecEnd

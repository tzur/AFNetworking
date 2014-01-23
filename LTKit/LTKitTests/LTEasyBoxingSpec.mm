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

  it(@"should box GLKVector2", ^{
    GLKVector2 expected = GLKVector2Make(1, -1);
    NSValue *value = $(expected);
    GLKVector2 actual = [value GLKVector2Value];

    expect(GLKVector2AllEqualToVector2(expected, actual)).to.beTruthy();
  });

  it(@"should box GLKVector3", ^{
    GLKVector3 expected = GLKVector3Make(1, -1, 5);
    NSValue *value = $(expected);
    GLKVector3 actual = [value GLKVector3Value];

    expect(GLKVector3AllEqualToVector3(expected, actual)).to.beTruthy();
  });

  it(@"should box GLKVector4", ^{
    GLKVector4 expected = GLKVector4Make(1, -1, 5, 3);
    NSValue *value = $(expected);
    GLKVector4 actual = [value GLKVector4Value];

    expect(GLKVector4AllEqualToVector4(expected, actual)).to.beTruthy();
  });

  it(@"should box GLKMatrix2", ^{
    GLKMatrix2 expected = {{1, -1, 5, 3}};
    NSValue *value = $(expected);
    GLKMatrix2 actual = [value GLKMatrix2Value];

    expect(expected).to.equal(actual);
  });

  it(@"should box GLKMatrix3", ^{
    GLKMatrix3 expected = GLKMatrix3Make(1, -1, 5,
                                         3, 7, 9,
                                         42, -5, 3);
    NSValue *value = $(expected);
    GLKMatrix3 actual = [value GLKMatrix3Value];

    BOOL isEqual = !memcmp(expected.m, actual.m, sizeof(expected.m));
    expect(isEqual).to.beTruthy();
  });

  it(@"should box GLKMatrix4", ^{
    GLKMatrix4 expected = GLKMatrix4Make(1, -1, 5, 3,
                                         7, 9, 42, -5,
                                         3, 5, -6, -1,
                                         -5, -3, 1, 6);
    NSValue *value = $(expected);
    GLKMatrix4 actual = [value GLKMatrix4Value];

    BOOL isEqual = !memcmp(expected.m, actual.m, sizeof(expected.m));
    expect(isEqual).to.beTruthy();
  });
});

SpecEnd

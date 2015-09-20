// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEasyBoxing+LTEngine.h"

SpecBegin(LTEasyBoxing_LTEngine)

context(@"wrapping", ^{
  it(@"should box LTVector2", ^{
    LTVector2 expected = LTVector2(1, -1);
    NSValue *value = $(expected);
    LTVector2 actual = [value LTVector2Value];

    expect(actual).to.equal(expected);
  });

  it(@"should box LTVector3", ^{
    LTVector3 expected = LTVector3(1, -1, 5);
    NSValue *value = $(expected);
    LTVector3 actual = [value LTVector3Value];

    expect(actual).to.equal(expected);
  });

  it(@"should box LTVector4", ^{
    LTVector4 expected = LTVector4(1, -1, 5, 3);
    NSValue *value = $(expected);
    LTVector4 actual = [value LTVector4Value];

    expect(actual).to.equal(expected);
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

  it(@"should box LTVector2", ^{
    LTVector2 expected(1, -1);
    NSValue *value = $(expected);

    expect([value LTVector2Value]).to.equal(expected);
  });

  it(@"should box LTVector2", ^{
    LTVector3 expected(1, -1, 2);
    NSValue *value = $(expected);

    expect([value LTVector3Value]).to.equal(expected);
  });

  it(@"should box LTVector2", ^{
    LTVector4 expected(1, -1, 2, 4);
    NSValue *value = $(expected);

    expect([value LTVector4Value]).to.equal(expected);
  });
  
  it(@"should box LTRect", ^{
    LTRect expected(1, 2, 3, 4);
    NSValue *value = $(expected);
    expect([value LTRectValue]).to.equal(expected);
  });
});

SpecEnd

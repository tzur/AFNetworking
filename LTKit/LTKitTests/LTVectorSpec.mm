// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTVector.h"

SpecBegin(LTVector)

context(@"LTVector2", ^{
  it(@"should initialize correctly", ^{
    LTVector2 v1;
    expect(v1.x).to.equal(0);
    expect(v1.y).to.equal(0);

    LTVector2 v2(1, 2);
    expect(v2.x).to.equal(1);
    expect(v2.y).to.equal(2);

    LTVector2 v3(CGPointMake(3, 4));
    expect(v3.x).to.equal(3);
    expect(v3.y).to.equal(4);

    LTVector2 v4(CGSizeMake(5, 6));
    expect(v4.x).to.equal(5);
    expect(v4.y).to.equal(6);
    
    LTVector2 v5(GLKVector2Make(7, 8));
    expect(v5.x).to.equal(7);
    expect(v5.y).to.equal(8);
  });

  it(@"should cast to GLKVector2", ^{
    LTVector2 ltVector(5, 7);
    GLKVector2 glkVector(ltVector);

    expect(ltVector.x).to.equal(glkVector.x);
    expect(ltVector.y).to.equal(glkVector.y);
  });

  it(@"should cast to CGPoint", ^{
    LTVector2 vector(1, 2);
    CGPoint point(vector);

    expect(point.x).to.equal(vector.x);
    expect(point.y).to.equal(vector.y);
  });

  it(@"should cast to CGSize", ^{
    LTVector2 vector(1, 2);
    CGSize size(vector);
    
    expect(size.width).to.equal(vector.x);
    expect(size.height).to.equal(vector.y);
  });
  
  it(@"should perform math operations correctly", ^{
    LTVector2 v1(10, 8);
    LTVector2 v2(5, 4);

    expect(v1 + v2).to.equal(LTVector2(15, 12));
    expect(v1 - v2).to.equal(LTVector2(5, 4));
    expect(v1 * v2).to.equal(LTVector2(50, 32));
    expect(v1 / v2).to.equal(LTVector2(2, 2));
  });

  it(@"should perform equality correctly", ^{
    expect(LTVector2(1, 2) == LTVector2(1, 2)).to.beTruthy();
    expect(LTVector2(1, 3) == LTVector2(1, 2)).to.beFalsy();
    expect(LTVector2(1, 2) != LTVector2(1, 2)).to.beFalsy();
    expect(LTVector2(1, 3) != LTVector2(1, 2)).to.beTruthy();
  });

  it(@"should access rgb values correctly", ^{
    LTVector2 v(1, 2);
    v.r() = 5;
    v.g() = 8;
    expect(v).to.equal(LTVector2(5, 8));
  });

  it(@"should convert from string", ^{
    NSString *value = @"(1.5, 2.5, 3)";
    LTVector3 vector = LTVector3FromString(value);
    expect(vector.x).to.equal(1.5);
    expect(vector.y).to.equal(2.5);
    expect(vector.z).to.equal(3);
  });

  it(@"should return zero vector on invalid string", ^{
    expect(LTVector2FromString(@"(1.5)")).to.equal(LTVector2());
    expect(LTVector2FromString(@"(1.5, 2.5")).to.equal(LTVector2());
    expect(LTVector2FromString(@"1.5, 2.5)")).to.equal(LTVector2());
    expect(LTVector2FromString(@"(3)")).to.equal(LTVector2());
    expect(LTVector2FromString(@"(a, 2)")).to.equal(LTVector2());
  });
});

context(@"LTVector3", ^{
  it(@"should initialize correctly", ^{
    LTVector3 v1;
    expect(v1.x).to.equal(0);
    expect(v1.y).to.equal(0);
    expect(v1.z).to.equal(0);

    LTVector3 v2(1, 2, 3);
    expect(v2.x).to.equal(1);
    expect(v2.y).to.equal(2);
    expect(v2.z).to.equal(3);

    LTVector3 v3(GLKVector3Make(3, 4, 5));
    expect(v3.x).to.equal(3);
    expect(v3.y).to.equal(4);
    expect(v3.z).to.equal(5);
  });

  it(@"should cast to GLKVector3", ^{
    LTVector3 ltVector(5, 7, 9);
    GLKVector3 glkVector(ltVector);

    expect(ltVector.x).to.equal(glkVector.x);
    expect(ltVector.y).to.equal(glkVector.y);
    expect(ltVector.z).to.equal(glkVector.z);
  });

  it(@"should perform math operations correctly", ^{
    LTVector3 v1(10, 8, 6);
    LTVector3 v2(5, 4, 2);

    expect(v1 + v2).to.equal(LTVector3(15, 12, 8));
    expect(v1 - v2).to.equal(LTVector3(5, 4, 4));
    expect(v1 * v2).to.equal(LTVector3(50, 32, 12));
    expect(v1 / v2).to.equal(LTVector3(2, 2, 3));
  });

  it(@"should perform equality correctly", ^{
    expect(LTVector3(1, 2, 3) == LTVector3(1, 2, 3)).to.beTruthy();
    expect(LTVector3(1, 3, 3) == LTVector3(1, 2, 3)).to.beFalsy();
    expect(LTVector3(1, 2, 3) != LTVector3(1, 2, 3)).to.beFalsy();
    expect(LTVector3(1, 3, 3) != LTVector3(1, 2, 3)).to.beTruthy();
  });

  it(@"should access rgb values correctly", ^{
    LTVector3 v(1, 2, 3);
    v.r() = 5;
    v.g() = 8;
    v.b() = 2;
    expect(v).to.equal(LTVector3(5, 8, 2));
  });

  it(@"should convert from string", ^{
    NSString *value = @"(1.5, 2.5, 3)";
    LTVector3 vector = LTVector3FromString(value);
    expect(vector.x).to.equal(1.5);
    expect(vector.y).to.equal(2.5);
    expect(vector.z).to.equal(3);
  });

  it(@"should return zero vector on invalid string", ^{
    expect(LTVector3FromString(@"(1.5, 2.5)")).to.equal(LTVector3());
    expect(LTVector3FromString(@"(1.5, 2.5, 3")).to.equal(LTVector3());
    expect(LTVector3FromString(@"1.5, 2.5, 3)")).to.equal(LTVector3());
    expect(LTVector3FromString(@"(3, 4)")).to.equal(LTVector3());
    expect(LTVector3FromString(@"(a, 2, 4)")).to.equal(LTVector3());
  });
});

context(@"LTVector4", ^{
  it(@"should initialize correctly", ^{
    LTVector4 v1;
    expect(v1.x).to.equal(0);
    expect(v1.y).to.equal(0);
    expect(v1.z).to.equal(0);
    expect(v1.w).to.equal(0);

    LTVector4 v2(1, 2, 3, 4);
    expect(v2.x).to.equal(1);
    expect(v2.y).to.equal(2);
    expect(v2.z).to.equal(3);
    expect(v2.w).to.equal(4);

    LTVector4 v3(GLKVector4Make(3, 4, 5, 6));
    expect(v3.x).to.equal(3);
    expect(v3.y).to.equal(4);
    expect(v3.z).to.equal(5);
    expect(v3.w).to.equal(6);
  });

  it(@"should cast to GLKVector4", ^{
    LTVector4 ltVector(5, 7, 9, 11);
    GLKVector4 glkVector(ltVector);

    expect(ltVector.x).to.equal(glkVector.x);
    expect(ltVector.y).to.equal(glkVector.y);
    expect(ltVector.z).to.equal(glkVector.z);
    expect(ltVector.w).to.equal(glkVector.w);
  });

  it(@"should perform math operations correctly", ^{
    LTVector4 v1(10, 8, 6, 12);
    LTVector4 v2(5, 4, 2, 6);

    expect(v1 + v2).to.equal(LTVector4(15, 12, 8, 18));
    expect(v1 - v2).to.equal(LTVector4(5, 4, 4, 6));
    expect(v1 * v2).to.equal(LTVector4(50, 32, 12, 72));
    expect(v1 / v2).to.equal(LTVector4(2, 2, 3, 2));
  });

  it(@"should perform equality correctly", ^{
    expect(LTVector4(1, 2, 3, 1) == LTVector4(1, 2, 3, 1)).to.beTruthy();
    expect(LTVector4(1, 3, 3, 1) == LTVector4(1, 2, 3, 1)).to.beFalsy();
    expect(LTVector4(1, 2, 3, 1) != LTVector4(1, 2, 3, 1)).to.beFalsy();
    expect(LTVector4(1, 3, 3, 1) != LTVector4(1, 2, 3, 1)).to.beTruthy();
  });

  it(@"should access rgb values correctly", ^{
    LTVector4 v(1, 2, 3, 4);
    v.r() = 5;
    v.g() = 8;
    v.b() = 2;
    v.a() = 12;
    expect(v).to.equal(LTVector4(5, 8, 2, 12));
  });

  it(@"should convert from string", ^{
    NSString *value = @"(1.5, 2.5, 3, 4)";
    LTVector4 vector = LTVector4FromString(value);
    expect(vector.x).to.equal(1.5);
    expect(vector.y).to.equal(2.5);
    expect(vector.z).to.equal(3);
    expect(vector.w).to.equal(4);
  });

  it(@"should return zero vector on invalid string", ^{
    expect(LTVector4FromString(@"(1.5, 2.5, 3)")).to.equal(LTVector4());
    expect(LTVector4FromString(@"(1.5, 2.5, 3, 4")).to.equal(LTVector4());
    expect(LTVector4FromString(@"1.5, 2.5, 3, 4)")).to.equal(LTVector4());
    expect(LTVector4FromString(@"(3, 4)")).to.equal(LTVector4());
    expect(LTVector4FromString(@"(a, 2, 3, 4)")).to.equal(LTVector4());
  });
});

SpecEnd

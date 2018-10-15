// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTVector.h"

#import "UIColor+Vector.h"

SpecBegin(LTVector)

static const CGFloat kEpsilon = 1e-5;

using half_float::half;

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

    LTVector2 v5(LTVector2(7, 8));
    expect(v5.x).to.equal(7);
    expect(v5.y).to.equal(8);

    LTVector2 v6(9);
    expect(v6.x).to.equal(9);
    expect(v6.y).to.equal(9);
  });

  it(@"should cast to LTVector2", ^{
    LTVector2 ltVector(5, 7);
    LTVector2 glkVector(ltVector);

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
    expect(v1 * 2).to.equal(LTVector2(20, 16));
    expect(2 * v1).to.equal(LTVector2(20, 16));
    expect(v1 / v2).to.equal(LTVector2(2, 2));
    expect(v1 / 2).to.equal(LTVector2(5, 4));
    expect(80 / v1).to.equal(LTVector2(8, 10));
    expect(-v1).to.equal(LTVector2(-10, -8));
  });

  it(@"should perform equality correctly", ^{
    expect(LTVector2(1, 2) == LTVector2(1, 2)).to.beTruthy();
    expect(LTVector2(1, 3) == LTVector2(1, 2)).to.beFalsy();
    expect(LTVector2(1, 2) != LTVector2(1, 2)).to.beFalsy();
    expect(LTVector2(1, 3) != LTVector2(1, 2)).to.beTruthy();
  });

  it(@"should return true from isNull if the vector is the null vector", ^{
    LTVector2 v1(LTVector2::null());
    LTVector2 v2(1, NAN);
    LTVector2 v3(1, 2);
    expect(v1.isNull()).to.beTruthy();
    expect(v2.isNull()).to.beFalsy();
    expect(v3.isNull()).to.beFalsy();
  });

  it(@"should return a unit vector specified by an angle", ^{
    LTVector2 vector = LTVector2::angle(M_PI);
    expect(vector.x).to.beCloseToWithin(-1, kEpsilon);
    expect(vector.y).to.beCloseToWithin(0, kEpsilon);
  });

  it(@"should access rgb values correctly", ^{
    LTVector2 v(1, 2);
    v.r() = 5;
    v.g() = 8;
    expect(v).to.equal(LTVector2(5, 8));
  });

  it(@"should sum the vector components correctly", ^{
    LTVector2 v(1, 2);
    expect(v.sum()).to.equal(3);
  });

  it(@"should return the correct angle", ^{
    LTVector2 v(1, 0);
    CGFloat angle = v.angle(LTVector2(1, 0));
    expect(angle).to.equal(0);
    angle = v.angle(LTVector2(0.5, 0.5));
    expect(angle).to.beCloseToWithin(0.5 * M_PI_2, kEpsilon);
    angle = v.angle(LTVector2(0, 1));
    expect(angle).to.beCloseToWithin(M_PI_2, kEpsilon);
    angle = v.angle(LTVector2(-0.5, 0.5));
    expect(angle).to.beCloseToWithin(1.5 * M_PI_2, kEpsilon);
    angle = v.angle(LTVector2(-1, 0));
    expect(angle).to.beCloseToWithin(M_PI, kEpsilon);
    angle = v.angle(LTVector2(-0.5, -0.5));
    expect(angle).to.beCloseToWithin(2.5 * M_PI_2, kEpsilon);
    angle = v.angle(LTVector2(0, -1));
    expect(angle).to.beCloseToWithin(3 * M_PI_2, kEpsilon);
    angle = v.angle(LTVector2(0.5, -0.5));
    expect(angle).to.beCloseToWithin(3.5 * M_PI_2, kEpsilon);

    v = LTVector2(0.5, 0.5);
    angle = v.angle(LTVector2(0.5, 0.5));
    expect(angle).to.equal(0);
    angle = v.angle(LTVector2(-0.5, 0.5));
    expect(angle).to.beCloseToWithin(M_PI_2, kEpsilon);
    angle = v.angle(LTVector2(-0.5, -0.5));
    expect(angle).to.beCloseToWithin(M_PI, kEpsilon);
    angle = v.angle(LTVector2(0.5, -0.5));
    expect(angle).to.beCloseToWithin(3 * M_PI_2, kEpsilon);

    angle = (LTVector2(948.0838623046875, 198.879669189453125) -
             LTVector2(223.8236083984375, 198.879638671875)).angle(LTVector2(1, 0));
    expect(angle).to.beLessThan(2 * M_PI);
  });

  context(@"perpendicular", ^{
    LTVector2 v(1, 2);

    it(@"should return a perpendicular vector, resulting from clockwise rotation", ^{
      expect(v.perpendicular(YES)).to.equal(LTVector2(2, -1));
    });

    it(@"should return a perpendicular vector, resulting from counter-clockwise rotation", ^{
      expect(v.perpendicular(NO)).to.equal(LTVector2(-2, 1));
    });

    it(@"should return a perpendicular vector, resulting from default (clockwise) rotation", ^{
      expect(v.perpendicular()).to.equal(v.perpendicular(YES));
    });
  });

  it(@"should clamp point elements between two points elements", ^{
    expect(LTVector2(0.5, -0.5).clamp(LTVector2(0, 0), LTVector2(1, 1)))
        .to.equal(LTVector2(0.5, 0));
    expect(LTVector2(0.5, -0.5).clamp(LTVector2(-1, 0), LTVector2(1, 1)))
        .to.equal(LTVector2(0.5, 0));
    expect(LTVector2(0.5, -0.5).clamp(LTVector2(-1, -1), LTVector2(0, 1)))
        .to.equal(LTVector2(0, -0.5));
  });

  it(@"should clamp point elements between two scalars", ^{
    expect(LTVector2(0.5, -0.5).clamp(0, 1)).to.equal(LTVector2(0.5, 0));
    expect(LTVector2(0.5, -0.5).clamp(-1, 0)).to.equal(LTVector2(0, -0.5));
  });

  it(@"should access data correctly", ^{
    LTVector2 v(1, 2);
    expect(v.data()[0]).to.equal(1);
    expect(v.data()[1]).to.equal(2);
  });

  context(@"std", ^{
    it(@"should return rounded vector", ^{
      LTVector2 v(1.3, 2.7);
      expect(std::round(v)).to.equal(LTVector2(1, 3));
    });

    it(@"should return minimal vector", ^{
      LTVector2 v1(1, 4);
      LTVector2 v2(2, 3);
      expect(std::min(v1, v2)).to.equal(LTVector2(1, 3));
    });

    it(@"should return minimal component", ^{
      expect(std::min(LTVector2(1, 7))).to.equal(1);
    });

    it(@"should return maximal vector", ^{
      LTVector2 v1(1, 4);
      LTVector2 v2(2, 3);
      expect(std::max(v1, v2)).to.equal(LTVector2(2, 4));
    });

    it(@"should return maximal component", ^{
      expect(std::max(LTVector2(1, 7))).to.equal(7);
    });

    it(@"should return absolute value of each element", ^{
      expect(std::abs(LTVector2(-1, 2))).to.equal(LTVector2(1, 2));
      expect(std::abs(LTVector2(1, -2))).to.equal(LTVector2(1, 2));
    });

    it(@"should return square root of each element", ^{
      expect(std::sqrt(LTVector2(0, 4))).to.equal(LTVector2(0, 2));
    });

    it(@"should return each element raised to the power", ^{
      expect(std::pow(LTVector2(1, 2), 2)).to.equal(LTVector2(1, 4));
      expect(std::pow(LTVector2(4, 16), 0.5)).to.equal(LTVector2(2, 4));
    });

    it(@"should return each element raised to the power element-wise", ^{
      expect(std::pow(LTVector2(1, 4), LTVector2(0, 2)))
          .to.equal(LTVector2(1, 16));
    });

    it(@"should mix using a given scalar", ^{
      LTVector2 vector1(2, 4);
      LTVector2 vector2(4, 8);

      expect(std::mix(vector1, vector2, 0)).to.equal(vector1);
      expect(std::mix(vector1, vector2, 1)).to.equal(vector2);
      expect(std::mix(vector1, vector2, 0.5)).to.equal(LTVector2(3, 6));
    });

    it(@"should mix using an interpolation vector ", ^{
      LTVector2 vector1(2, 4);
      LTVector2 vector2(4, 8);

      expect(std::mix(vector1, vector2, LTVector2::zeros())).to.equal(vector1);
      expect(std::mix(vector1, vector2, LTVector2::ones())).to.equal(vector2);
      expect(std::mix(vector1, vector2, LTVector2(0.5, 0.25))).to.equal(LTVector2(3, 5));
    });

    it(@"should step with an edge scalar", ^{
      LTVector2 vector1(2, 4);
      LTVector2 vector2(4, 2);
      LTVector2 vector3(3, 3);

      expect(std::step(3, vector1)).to.equal(LTVector2(0, 1));
      expect(std::step(3, vector2)).to.equal(LTVector2(1, 0));
      expect(std::step(3, vector3)).to.equal(LTVector2(1, 1));
    });

    it(@"should step with an edge vector", ^{
      LTVector2 vector(2, 4);

      expect(std::step(LTVector2(3, 3), vector)).to.equal(LTVector2(0, 1));
      expect(std::step(LTVector2(1, 5), vector)).to.equal(LTVector2(1, 0));
      expect(std::step(LTVector2(2, 4), vector)).to.equal(LTVector2(1, 1));
    });
  });

  context(@"string-vector conversions", ^{
    it(@"should return a string from a given vector", ^{
      expect(NSStringFromLTVector2(LTVector2(1.5, 2.5))).to.equal(@"(1.5, 2.5)");
    });

    it(@"should convert from string", ^{
      NSString *value = @"(1.5, 2.5)";
      LTVector2 vector = LTVector2FromString(value);
      expect(vector.x).to.equal(1.5);
      expect(vector.y).to.equal(2.5);
    });

    it(@"should convert from string with non-numeric values", ^{
      LTVector2 vector = LTVector2FromString(@"(nan, inf)");
      expect(std::isnan(vector.x)).to.beTruthy();
      expect(std::isinf(vector.y) && vector.y > 0).to.beTruthy();

      vector = LTVector2FromString(@"(-inf, nan)");
      expect(std::isinf(vector.x) && vector.x < 0).to.beTruthy();
      expect(std::isnan(vector.y)).to.beTruthy();
    });

    it(@"should return zero vector on invalid string", ^{
      expect(LTVector2FromString(@"(1.5)")).to.equal(LTVector2());
      expect(LTVector2FromString(@"(1.5, 2.5")).to.equal(LTVector2());
      expect(LTVector2FromString(@"1.5, 2.5)")).to.equal(LTVector2());
      expect(LTVector2FromString(@"(3)")).to.equal(LTVector2());
      expect(LTVector2FromString(@"(a, 2)")).to.equal(LTVector2());
    });
  });
});

context(@"LTVector3", ^{
  it(@"should initialize correctly", ^{
    LTVector3 v1;
    expect(v1.x).to.equal(0);
    expect(v1.y).to.equal(0);
    expect(v1.z).to.equal(0);

    LTVector3 v2(1);
    expect(v2.x).to.equal(1);
    expect(v2.y).to.equal(1);
    expect(v2.z).to.equal(1);

    LTVector3 v3(1, 2, 3);
    expect(v3.x).to.equal(1);
    expect(v3.y).to.equal(2);
    expect(v3.z).to.equal(3);

    LTVector3 v4(LTVector3(3, 4, 5));
    expect(v4.x).to.equal(3);
    expect(v4.y).to.equal(4);
    expect(v4.z).to.equal(5);
  });

  it(@"should cast to LTVector3", ^{
    LTVector3 ltVector(5, 7, 9);
    LTVector3 glkVector(ltVector);

    expect(ltVector.x).to.equal(glkVector.x);
    expect(ltVector.y).to.equal(glkVector.y);
    expect(ltVector.z).to.equal(glkVector.z);
  });

  it(@"should cast to cv::Vec3b", ^{
    LTVector3 ltVector = LTVector3(5, 7, 9);
    cv::Vec3b cvVector = (cv::Vec3b)(ltVector / UCHAR_MAX);

    expect(cvVector[0]).to.equal(ltVector.x);
    expect(cvVector[1]).to.equal(ltVector.y);
    expect(cvVector[2]).to.equal(ltVector.z);
  });

  it(@"should cast to cv::Vec3f", ^{
    LTVector3 ltVector = LTVector3(-0.5, 0.7, -1.1);
    cv::Vec3f cvVector = (cv::Vec3f)ltVector;

    expect(cvVector[0]).to.equal(ltVector.x);
    expect(cvVector[1]).to.equal(ltVector.y);
    expect(cvVector[2]).to.equal(ltVector.z);
  });

  it(@"should perform math operations correctly", ^{
    LTVector3 v1(10, 8, 6);
    LTVector3 v2(5, 4, 2);

    expect(v1 + v2).to.equal(LTVector3(15, 12, 8));
    expect(v1 - v2).to.equal(LTVector3(5, 4, 4));
    expect(v1 * v2).to.equal(LTVector3(50, 32, 12));
    expect(v1 * 2).to.equal(LTVector3(20, 16, 12));
    expect(2 * v1).to.equal(LTVector3(20, 16, 12));
    expect(v1 / v2).to.equal(LTVector3(2, 2, 3));
    expect(v1 / 2).to.equal(LTVector3(5, 4, 3));
    expect(480 / v1).to.equal(LTVector3(48, 60, 80));
    expect(-v1).to.equal(LTVector3(-10, -8, -6));
  });

  it(@"should perform equality correctly", ^{
    expect(LTVector3(1, 2, 3) == LTVector3(1, 2, 3)).to.beTruthy();
    expect(LTVector3(1, 3, 3) == LTVector3(1, 2, 3)).to.beFalsy();
    expect(LTVector3(1, 2, 3) != LTVector3(1, 2, 3)).to.beFalsy();
    expect(LTVector3(1, 3, 3) != LTVector3(1, 2, 3)).to.beTruthy();
  });

  it(@"should return true from isNull if the vector is the null vector", ^{
    LTVector3 v1(LTVector3::null());
    LTVector3 v2(1, NAN, NAN);
    LTVector3 v3(1, 2, 3);
    expect(v1.isNull()).to.beTruthy();
    expect(v2.isNull()).to.beFalsy();
    expect(v3.isNull()).to.beFalsy();
  });

  it(@"should access rgb values correctly", ^{
    LTVector3 v(1, 2, 3);
    v.r() = 5;
    v.g() = 8;
    v.b() = 2;
    expect(v).to.equal(LTVector3(5, 8, 2));
  });

  it(@"should sum the vector components correctly", ^{
    LTVector3 v(1, 2, 3);
    expect(v.sum()).to.equal(6);
  });

  it(@"should clamp vector elements between two vectors elements", ^{
    expect(LTVector3(0.5, -0.5, 1.1).clamp(LTVector3(0, 0, 0), LTVector3(1, 1, 1)))
        .to.equal(LTVector3(0.5, 0, 1));
    expect(LTVector3(0.5, -0.5, 1.1).clamp(LTVector3(0, -1, 0), LTVector3(1, 1, 1)))
        .to.equal(LTVector3(0.5, -0.5, 1));
    expect(LTVector3(0.5, -0.5, 1.1).clamp(LTVector3(-1, -1, 0), LTVector3(0, 1, 1)))
        .to.equal(LTVector3(0, -0.5, 1));
    expect(LTVector3(0.5, -0.5, 1.1).clamp(LTVector3(-1, -1, 0), LTVector3(0, 1, 1.5)))
        .to.equal(LTVector3(0, -0.5, 1.1));
  });

  it(@"should clamp vector elements between two scalars", ^{
    expect(LTVector3(0.5, -0.5, 1.1).clamp(0, 1)).to.equal(LTVector3(0.5, 0, 1));
    expect(LTVector3(0.5, -0.5, 1.1).clamp(-1, 0)).to.equal(LTVector3(0, -0.5, 0));
  });

  it(@"should access data correctly", ^{
    LTVector3 v(1, 2, 3);
    expect(v.data()[0]).to.equal(1);
    expect(v.data()[1]).to.equal(2);
    expect(v.data()[2]).to.equal(3);
  });

  context(@"std", ^{
    it(@"should return rounded vector", ^{
      LTVector3 v(1.3, 2.7, 3.3);
      expect(std::round(v)).to.equal(LTVector3(1, 3, 3));
    });

    it(@"should return minimal vector", ^{
      LTVector3 v1(1, 4, 5);
      LTVector3 v2(2, 3, 4);
      expect(std::min(v1, v2)).to.equal(LTVector3(1, 3, 4));
    });

    it(@"should return minimal component", ^{
      expect(std::min(LTVector3(1, 7, -5))).to.equal(-5);
    });

    it(@"should return maximal vector", ^{
      LTVector3 v1(1, 4, 5);
      LTVector3 v2(2, 3, 4);
      expect(std::max(v1, v2)).to.equal(LTVector3(2, 4, 5));
    });

    it(@"should return maximal component", ^{
      expect(std::max(LTVector3(1, 7, -5))).to.equal(7);
    });

    it(@"should return absolute value of each element", ^{
      expect(std::abs(LTVector3(-1, 2, -3))).to.equal(LTVector3(1, 2, 3));
      expect(std::abs(LTVector3(1, -2, 3))).to.equal(LTVector3(1, 2, 3));
    });

    it(@"should return square root of each element", ^{
      expect(std::sqrt(LTVector3(0, 4, 9))).to.equal(LTVector3(0, 2, 3));
    });

    it(@"should return each element raised to the power", ^{
      expect(std::pow(LTVector3(1, 2, 0.5), 2)).to.equal(LTVector3(1, 4, 0.25));
      expect(std::pow(LTVector3(1, 4, 16), 0.5)).to.equal(LTVector3(1, 2, 4));
    });

    it(@"should return each element raised to the power element-wise", ^{
      expect(std::pow(LTVector3(1, 2, 4), LTVector3(0, 2, 0.5)))
          .to.equal(LTVector3(1, 4, 2));
    });

    it(@"should mix using a given scalar", ^{
      LTVector3 vector1(2, 4, 6);
      LTVector3 vector2(4, 8, 12);

      expect(std::mix(vector1, vector2, 0)).to.equal(vector1);
      expect(std::mix(vector1, vector2, 1)).to.equal(vector2);
      expect(std::mix(vector1, vector2, 0.5)).to.equal(LTVector3(3, 6, 9));
    });

    it(@"should mix using an interpolation vector ", ^{
      LTVector3 vector1(2, 4, 6);
      LTVector3 vector2(4, 8, 12);

      expect(std::mix(vector1, vector2, LTVector3::zeros())).to.equal(vector1);
      expect(std::mix(vector1, vector2, LTVector3::ones())).to.equal(vector2);
      expect(std::mix(vector1, vector2, LTVector3(0.5, 0.25, 1))).to.equal(LTVector3(3, 5, 12));
    });

    it(@"should step with an edge scalar", ^{
      LTVector3 vector1(2, 4, 4);
      LTVector3 vector2(4, 2, 4);
      LTVector3 vector3(4, 4, 2);
      LTVector3 vector4(3, 3, 3);

      expect(std::step(3, vector1)).to.equal(LTVector3(0, 1, 1));
      expect(std::step(3, vector2)).to.equal(LTVector3(1, 0, 1));
      expect(std::step(3, vector3)).to.equal(LTVector3(1, 1, 0));
      expect(std::step(3, vector4)).to.equal(LTVector3(1, 1, 1));
    });

    it(@"should step with an edge vector", ^{
      LTVector3 vector(2, 4, 6);

      expect(std::step(LTVector3(3, 3, 5), vector)).to.equal(LTVector3(0, 1, 1));
      expect(std::step(LTVector3(1, 5, 5), vector)).to.equal(LTVector3(1, 0, 1));
      expect(std::step(LTVector3(1, 3, 7), vector)).to.equal(LTVector3(1, 1, 0));
      expect(std::step(LTVector3(2, 4, 6), vector)).to.equal(LTVector3(1, 1, 1));
    });
  });

  context(@"color conversions", ^{
    it(@"should convert from rgb to hsv", ^{
      LTVector3 expected = LTVector3(0, 1, 1);
      expect((LTVector3(1, 0, 0).rgbToHsv() - expected).length()).to.beCloseToWithin(0, 1e-4);
    });

    it(@"should convert from rgb to hsv when max channel value is red", ^{
      LTVector3 rgb(0.97, 0.4, 0.5);
      LTVector3 expected = [[UIColor lt_colorWithLTVector:LTVector4(rgb, 1)] lt_ltVectorHSVA].rgb();
      expect((rgb.rgbToHsv() - expected).length()).to.beCloseToWithin(0, 1e-4);
    });

    it(@"should convert from rgb to hsv when max channel value is green", ^{
      LTVector3 rgb(0.97, 0.99, 0.5);
      LTVector3 expected = [[UIColor lt_colorWithLTVector:LTVector4(rgb, 1)] lt_ltVectorHSVA].rgb();
      expect((rgb.rgbToHsv() - expected).length()).to.beCloseToWithin(0, 1e-4);
    });

    it(@"should convert from rgb to hsv when max channel value is blue", ^{
      LTVector3 rgb(0.97, 0.4, 0.985);
      LTVector3 expected = [[UIColor lt_colorWithLTVector:LTVector4(rgb, 1)] lt_ltVectorHSVA].rgb();
      expect((rgb.rgbToHsv() - expected).length()).to.beCloseToWithin(0, 1e-4);
    });

    it(@"should convert from rgb to hsv with almost gray color", ^{
      LTVector3 rgb(0.860001, 0.8600001, 0.8600002);
      LTVector3 expected = [[UIColor lt_colorWithLTVector:LTVector4(rgb, 1)] lt_ltVectorHSVA].rgb();
      expect((rgb.rgbToHsv() - expected).length()).to.beCloseToWithin(0, 1e-4);
    });

    it(@"should convert from rgb to hsv with gray color", ^{
      LTVector3 rgb(0.86, 0.86, 0.86);
      LTVector3 expected = [[UIColor lt_colorWithLTVector:LTVector4(rgb, 1)] lt_ltVectorHSVA].rgb();
      expect((rgb.rgbToHsv() - expected).length()).to.beCloseToWithin(0, 1e-4);
    });

    it(@"should convert from rgb to hsv with black color", ^{
      LTVector3 rgb(0, 0, 0);
      LTVector3 expected = [[UIColor lt_colorWithLTVector:LTVector4(rgb, 1)] lt_ltVectorHSVA].rgb();
      expect((rgb.rgbToHsv() - expected).length()).to.beCloseToWithin(0, 1e-4);
    });

    it(@"should convert from hsv to rgb", ^{
      LTVector3 expected = LTVector3(1, 0, 0);
      expect((LTVector3(0, 1, 1).hsvToRgb() - expected).length()).to.beCloseToWithin(0, 1e-4);
    });
  });

  context(@"string-vector conversions", ^{
    it(@"should return a string from a given vector", ^{
      expect(NSStringFromLTVector3(LTVector3(1.5, 2.5, 3))).to.equal(@"(1.5, 2.5, 3)");
    });

    it(@"should convert from string", ^{
      NSString *value = @"(1.5, 2.5, 3)";
      LTVector3 vector = LTVector3FromString(value);
      expect(vector.x).to.equal(1.5);
      expect(vector.y).to.equal(2.5);
      expect(vector.z).to.equal(3);
    });

    it(@"should convert from string with non-numeric values", ^{
      LTVector3 vector = LTVector3FromString(@"(nan, inf, -inf)");
      expect(std::isnan(vector.x)).to.beTruthy();
      expect(std::isinf(vector.y) && vector.y > 0).to.beTruthy();
      expect(std::isinf(vector.z) && vector.z < 0).to.beTruthy();
    });

    it(@"should return zero vector on invalid string", ^{
      expect(LTVector3FromString(@"(1.5, 2.5)")).to.equal(LTVector3());
      expect(LTVector3FromString(@"(1.5, 2.5, 3")).to.equal(LTVector3());
      expect(LTVector3FromString(@"1.5, 2.5, 3)")).to.equal(LTVector3());
      expect(LTVector3FromString(@"(3, 4)")).to.equal(LTVector3());
      expect(LTVector3FromString(@"(a, 2, 4)")).to.equal(LTVector3());
    });
  });
});

context(@"LTVector4", ^{
  it(@"should initialize correctly", ^{
    LTVector4 v1;
    expect(v1.x).to.equal(0);
    expect(v1.y).to.equal(0);
    expect(v1.z).to.equal(0);
    expect(v1.w).to.equal(0);

    LTVector4 v2(1);
    expect(v2.x).to.equal(1);
    expect(v2.y).to.equal(1);
    expect(v2.z).to.equal(1);
    expect(v2.w).to.equal(1);

    LTVector4 v3(1, 2, 3, 4);
    expect(v3.x).to.equal(1);
    expect(v3.y).to.equal(2);
    expect(v3.z).to.equal(3);
    expect(v3.w).to.equal(4);

    LTVector4 v4(LTVector4(3, 4, 5, 6));
    expect(v4.x).to.equal(3);
    expect(v4.y).to.equal(4);
    expect(v4.z).to.equal(5);
    expect(v4.w).to.equal(6);

    LTVector4 v5(LTVector3(7, 8, 9), 0);
    expect(v5.x).to.equal(7);
    expect(v5.y).to.equal(8);
    expect(v5.z).to.equal(9);
    expect(v5.w).to.equal(0);

    LTVector4 v6(cv::Vec4b(7.0, 8.0, 9.0, 10.0));
    expect(v6.x).to.equal(7.0 / UCHAR_MAX);
    expect(v6.y).to.equal(8.0 / UCHAR_MAX);
    expect(v6.z).to.equal(9.0 / UCHAR_MAX);
    expect(v6.w).to.equal(10.0 / UCHAR_MAX);

    LTVector4 v7(cv::Vec4f(0.1, 0.2, 0.3, 0.4));
    expect(v7.x).to.equal(0.1);
    expect(v7.y).to.equal(0.2);
    expect(v7.z).to.equal(0.3);
    expect(v7.w).to.equal(0.4);

    LTVector4 v8(cv::Vec4hf(half(0.1), half(0.2), half(0.3), half(0.4)));
    expect(v8.x).to.equal((float)half(0.1));
    expect(v8.y).to.equal((float)half(0.2));
    expect(v8.z).to.equal((float)half(0.3));
    expect(v8.w).to.equal((float)half(0.4));
});

  it(@"should cast to GLKVector4", ^{
    LTVector4 ltVector(5, 7, 9, 11);
    GLKVector4 glkVector = (GLKVector4)ltVector;

    expect(glkVector.x).to.equal(ltVector.x);
    expect(glkVector.y).to.equal(ltVector.y);
    expect(glkVector.z).to.equal(ltVector.z);
    expect(glkVector.w).to.equal(ltVector.w);
  });

  it(@"should cast to cv::Vec4b", ^{
    LTVector4 ltVector = LTVector4(5, 7, 9, 11);
    cv::Vec4b cvVector = (cv::Vec4b)(ltVector / UCHAR_MAX);

    expect(cvVector[0]).to.equal(ltVector.x);
    expect(cvVector[1]).to.equal(ltVector.y);
    expect(cvVector[2]).to.equal(ltVector.z);
    expect(cvVector[3]).to.equal(ltVector.w);
  });

  it(@"should cast to cv::Vec4f", ^{
    LTVector4 ltVector = LTVector4(-0.5, 0.7, 0.9, -1.1);
    cv::Vec4f cvVector = (cv::Vec4f)ltVector;

    expect(cvVector[0]).to.equal(ltVector.x);
    expect(cvVector[1]).to.equal(ltVector.y);
    expect(cvVector[2]).to.equal(ltVector.z);
    expect(cvVector[3]).to.equal(ltVector.w);
  });

  it(@"should cast to cv::Vec4hf", ^{
    LTVector4 ltVector = LTVector4(-0.5, 0.7, 0.9, -1.1);
    cv::Vec4hf cvVector = (cv::Vec4hf)ltVector;

    expect(float(cvVector[0])).to.equal(float(half(ltVector.x)));
    expect(float(cvVector[1])).to.equal(float(half(ltVector.y)));
    expect(float(cvVector[2])).to.equal(float(half(ltVector.z)));
    expect(float(cvVector[3])).to.equal(float(half(ltVector.w)));
  });

  it(@"should perform math operations correctly", ^{
    LTVector4 v1(10, 8, 6, 12);
    LTVector4 v2(5, 4, 2, 6);

    expect(v1 + v2).to.equal(LTVector4(15, 12, 8, 18));
    expect(v1 + 1).to.equal(LTVector4(11, 9, 7, 13));
    expect(v1 - v2).to.equal(LTVector4(5, 4, 4, 6));
    expect(v1 * v2).to.equal(LTVector4(50, 32, 12, 72));
    expect(v1 * 2).to.equal(LTVector4(20, 16, 12, 24));
    expect(2 * v1).to.equal(LTVector4(20, 16, 12, 24));
    expect(v1 / v2).to.equal(LTVector4(2, 2, 3, 2));
    expect(v1 / 2).to.equal(LTVector4(5, 4, 3, 6));
    expect(480 / v1).to.equal(LTVector4(48, 60, 80, 40));
    expect(-v1).to.equal(LTVector4(-10, -8, -6, -12));
  });

  it(@"should perform equality correctly", ^{
    expect(LTVector4(1, 2, 3, 1) == LTVector4(1, 2, 3, 1)).to.beTruthy();
    expect(LTVector4(1, 3, 3, 1) == LTVector4(1, 2, 3, 1)).to.beFalsy();
    expect(LTVector4(1, 2, 3, 1) != LTVector4(1, 2, 3, 1)).to.beFalsy();
    expect(LTVector4(1, 3, 3, 1) != LTVector4(1, 2, 3, 1)).to.beTruthy();
    expect(LTVector4(1, 2, 3, 0) != LTVector4(1, 2, 3, 1)).to.beTruthy();
  });

  it(@"should return true from isNull if the vector is the null vector", ^{
    LTVector4 v1(LTVector4::null());
    LTVector4 v2(1, NAN, NAN, NAN);
    LTVector4 v3(1, 2, 3, 4);
    expect(v1.isNull()).to.beTruthy();
    expect(v2.isNull()).to.beFalsy();
    expect(v3.isNull()).to.beFalsy();
  });

  it(@"should access rgb values correctly", ^{
    LTVector4 v(1, 2, 3, 4);
    v.r() = 5;
    v.g() = 8;
    v.b() = 2;
    v.a() = 12;
    expect(v).to.equal(LTVector4(5, 8, 2, 12));
    expect(v.rgb()).to.equal(LTVector3(5, 8, 2));
  });

  it(@"should return vector with bgra values", ^{
    LTVector4 v(1, 2, 3, 4);
    expect(v.bgra()).to.equal(LTVector4(3, 2, 1, 4));
  });

  it(@"should sum the vector components correctly", ^{
    LTVector4 v(1, 2, 3, 4);
    expect(v.sum()).to.equal(10);
  });

  it(@"should clamp vector elements between two vectors elements", ^{
    expect(LTVector4(0.5, -0.5, 1.1, -1.1).clamp(LTVector4(0, 0, 0, 0), LTVector4(1, 1, 1, 1)))
        .to.equal(LTVector4(0.5, 0, 1, 0));
    expect(LTVector4(0.5, -0.5, 1.1, -1.1).clamp(LTVector4(0, -1, 0 ,0), LTVector4(1, 1, 1, 1)))
        .to.equal(LTVector4(0.5, -0.5, 1, 0));
    expect(LTVector4(0.5, -0.5, 1.1, -1.1).clamp(LTVector4(-1, -1, 0, 0), LTVector4(0, 1, 1, 1)))
        .to.equal(LTVector4(0, -0.5, 1, 0));
    expect(LTVector4(0.5, -0.5, 1.1, -1.1).clamp(LTVector4(-1, -1, 0, 0), LTVector4(0, 1, 1.5, 1)))
         .to.equal(LTVector4(0, -0.5, 1.1, 0));
    expect(LTVector4(0.5, -0.5, 1.1, -1.1).clamp(LTVector4(-1, -1, 0, -1.5),
                                                 LTVector4(0, 1, 1.5, 1)))
        .to.equal(LTVector4(0, -0.5, 1.1, -1.1));
  });

  it(@"should clamp vector elements between two scalars", ^{
    expect(LTVector4(0.5, -0.5, 1.1, -1.1).clamp(0, 1)).to.equal(LTVector4(0.5, 0, 1, 0));
    expect(LTVector4(0.5, -0.5, 1.1, -1.1).clamp(-1, 0)).to.equal(LTVector4(0, -0.5, 0, -1));
  });

  it(@"should access data correctly", ^{
    LTVector4 v(1, 2, 3, 4);
    expect(v.data()[0]).to.equal(1);
    expect(v.data()[1]).to.equal(2);
    expect(v.data()[2]).to.equal(3);
    expect(v.data()[3]).to.equal(4);
  });

  context(@"std", ^{
    it(@"should return rounded vector", ^{
      LTVector4 v(1.3, 2.7, 3.3, -0.1);
      expect(std::round(v)).to.equal(LTVector4(1, 3, 3, 0));
    });

    it(@"should return minimal vector", ^{
      LTVector4 v1(1, 4, 5, 0);
      LTVector4 v2(2, 3, 4, -1);
      expect(std::min(v1, v2)).to.equal(LTVector4(1, 3, 4, -1));
    });

    it(@"should return minimal component", ^{
      expect(std::min(LTVector4(1, 7, -5, 100))).to.equal(-5);
    });

    it(@"should return maximal vector", ^{
      LTVector4 v1(1, 4, 5, 0);
      LTVector4 v2(2, 3, 4, -1);
      expect(std::max(v1, v2)).to.equal(LTVector4(2, 4, 5, 0));
    });

    it(@"should return maximal component", ^{
      expect(std::max(LTVector4(1, 7, -5, 100))).to.equal(100);
    });

    it(@"should return absolute value of each element", ^{
      expect(std::abs(LTVector4(-1, 2, -3, 4))).to.equal(LTVector4(1, 2, 3, 4));
      expect(std::abs(LTVector4(1, -2, 3, -4))).to.equal(LTVector4(1, 2, 3, 4));
    });

    it(@"should return square root of each element", ^{
      expect(std::sqrt(LTVector4(0, 4, 9, 16))).to.equal(LTVector4(0, 2, 3, 4));
    });

    it(@"should return each element raised to the power", ^{
      expect(std::pow(LTVector4(0, 4, 9, 16), 2)).to.equal(LTVector4(0, 16, 81, 256));
      expect(std::pow(LTVector4(0, 4, 9, 16), 0.5)).to.equal(LTVector4(0, 2, 3, 4));
    });

    it(@"should return each element raised to the power element-wise", ^{
      expect(std::pow(LTVector4(0, 4, 9, 16), LTVector4(0, 1, 2, 0.5)))
          .to.equal(LTVector4(1, 4, 81, 4));
    });

    it(@"should mix using a given scalar", ^{
      LTVector4 vector1(2, 4, 6, 8);
      LTVector4 vector2(4, 8, 12, 16);

      expect(std::mix(vector1, vector2, 0)).to.equal(vector1);
      expect(std::mix(vector1, vector2, 1)).to.equal(vector2);
      expect(std::mix(vector1, vector2, 0.5)).to.equal(LTVector4(3, 6, 9, 12));
    });

    it(@"should mix using an interpolation vector ", ^{
      LTVector4 vector1(2, 4, 6, 8);
      LTVector4 vector2(4, 8, 12, 16);

      expect(std::mix(vector1, vector2, LTVector4::zeros())).to.equal(vector1);
      expect(std::mix(vector1, vector2, LTVector4::ones())).to.equal(vector2);
      expect(std::mix(vector1, vector2, LTVector4(0.5, 0.25, 1, 0.125)))
          .to.equal(LTVector4(3, 5, 12, 9));
    });

    it(@"should step with an edge scalar", ^{
      LTVector4 vector1(2, 4, 4, 4);
      LTVector4 vector2(4, 2, 4, 4);
      LTVector4 vector3(4, 4, 2, 4);
      LTVector4 vector4(4, 4, 4, 2);
      LTVector4 vector5(3, 3, 3, 3);

      expect(std::step(3, vector1)).to.equal(LTVector4(0, 1, 1, 1));
      expect(std::step(3, vector2)).to.equal(LTVector4(1, 0, 1, 1));
      expect(std::step(3, vector3)).to.equal(LTVector4(1, 1, 0, 1));
      expect(std::step(3, vector4)).to.equal(LTVector4(1, 1, 1, 0));
      expect(std::step(3, vector5)).to.equal(LTVector4(1, 1, 1, 1));
    });

    it(@"should step with an edge vector", ^{
      LTVector4 vector(2, 4, 6, 8);

      expect(std::step(LTVector4(3, 3, 5, 7), vector)).to.equal(LTVector4(0, 1, 1, 1));
      expect(std::step(LTVector4(1, 5, 5, 7), vector)).to.equal(LTVector4(1, 0, 1, 1));
      expect(std::step(LTVector4(1, 3, 7, 7), vector)).to.equal(LTVector4(1, 1, 0, 1));
      expect(std::step(LTVector4(1, 3, 5, 9), vector)).to.equal(LTVector4(1, 1, 1, 0));
      expect(std::step(LTVector4(2, 4, 6, 8), vector)).to.equal(LTVector4(1, 1, 1, 1));
    });
  });

  context(@"color conversions", ^{
    it(@"should convert from rgb to hsv, while leaving last coordinate unchanged", ^{
      LTVector4 expected = LTVector4(0, 1, 1, 2);
      expect((LTVector4(1, 0, 0, 2).rgbToHsv() - expected).length()).to.beCloseToWithin(0, 1e-4);
    });

    it(@"should convert from hsv to rgb, while leaving last coordinate unchanged", ^{
      LTVector4 expected = LTVector4(1, 0, 0, 2);
      expect((LTVector4(0, 1, 1, 2).hsvToRgb() - expected).length()).to.beCloseToWithin(0, 1e-4);
    });
  });

  context(@"string-vector conversions", ^{
    it(@"should return a string from a given vector", ^{
      expect(NSStringFromLTVector4(LTVector4(1.5, 2.5, 3, 4))).to.equal(@"(1.5, 2.5, 3, 4)");
    });

    it(@"should convert from string", ^{
      NSString *value = @"(1.5, 2.5, 3, 4)";
      LTVector4 vector = LTVector4FromString(value);
      expect(vector.x).to.equal(1.5);
      expect(vector.y).to.equal(2.5);
      expect(vector.z).to.equal(3);
      expect(vector.w).to.equal(4);
    });

    it(@"should convert from string with non-numeric values", ^{
      LTVector4 vector = LTVector4FromString(@"(nan, inf, -inf, nan)");
      expect(std::isnan(vector.x)).to.beTruthy();
      expect(std::isinf(vector.y) && vector.y > 0).to.beTruthy();
      expect(std::isinf(vector.z) && vector.z < 0).to.beTruthy();
      expect(std::isnan(vector.w)).to.beTruthy();
    });

    it(@"should return zero vector on invalid string", ^{
      expect(LTVector4FromString(@"(1.5, 2.5, 3)")).to.equal(LTVector4());
      expect(LTVector4FromString(@"(1.5, 2.5, 3, 4")).to.equal(LTVector4());
      expect(LTVector4FromString(@"1.5, 2.5, 3, 4)")).to.equal(LTVector4());
      expect(LTVector4FromString(@"(3, 4)")).to.equal(LTVector4());
      expect(LTVector4FromString(@"(a, 2, 3, 4)")).to.equal(LTVector4());
    });
  });
});

SpecEnd

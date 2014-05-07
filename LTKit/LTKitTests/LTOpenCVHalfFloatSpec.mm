// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOpenCVHalfFloat.h"

#import "LTTestUtils.h"

using half_float::half;

SpecBegin(LTCVHalfFloatExtension)

context(@"setting values", ^{
  it(@"should set scalar value", ^{
    cv::Mat1hf mat(1, 1);

    half expected = half(2);
    mat(0, 0) = expected;
    half actual = mat(0, 0);

    expect((float)expected).to.equal((float)actual);
  });

  it(@"should set 2-element vector", ^{
    cv::Mat2hf mat(1, 1);

    cv::Vec2hf expected = cv::Vec2hf(half(1), half(2));
    mat(0, 0) = expected;
    cv::Vec2hf actual = mat(0, 0);

    BOOL isEqual = !memcmp(expected.val, actual.val, sizeof(expected.val));
    expect(isEqual).to.beTruthy();
  });

  it(@"should set 3-element vector", ^{
    cv::Mat3hf mat(1, 1);

    cv::Vec3hf expected = cv::Vec3hf(half(1), half(2), half(3));
    mat(0, 0) = expected;
    cv::Vec3hf actual = mat(0, 0);

    BOOL isEqual = !memcmp(expected.val, actual.val, sizeof(expected.val));
    expect(isEqual).to.beTruthy();
  });

  it(@"should set 4-element vector", ^{
    cv::Mat4hf mat(1, 1);

    cv::Vec4hf expected = cv::Vec4hf(half(1), half(2), half(3), half(4));
    mat(0, 0) = expected;
    cv::Vec4hf actual = mat(0, 0);

    BOOL isEqual = !memcmp(expected.val, actual.val, sizeof(expected.val));
    expect(isEqual).to.beTruthy();
  });
});

it(@"should have correct element size", ^{
  cv::Mat4hf mat(1, 1);

  expect(mat.elemSize1()).to.equal(2);
  expect(mat.elemSize()).to.equal(8);
});

it(@"should set entire mat to a value", ^{
  cv::Mat4hf mat(16, 16);

  cv::Vec4hf expected(half(1), half(2), half(3), half(4));
  mat.setTo(expected);

  for (const cv::Vec4hf &actual : mat) {
    BOOL isEqual = !memcmp(expected.val, actual.val, sizeof(expected.val));
    expect(isEqual).to.beTruthy();
  }
});

SpecEnd

// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOpenCVExtensions.h"

#import "LTTestUtils.h"

SpecBegin(LTOpenCVExtensions)

context(@"mat conversion", ^{
  it(@"should not change mat when type is similar to input", ^{
    cv::Mat4b input(16, 16);
    input.setTo(cv::Vec4b(1, 2, 3, 4));

    cv::Mat output;
    LTConvertMat(input, &output, CV_8UC4);

    expect(output.type()).to.equal(CV_8UC4);
    expect(LTCompareMat(input, output)).to.beTruthy();
  });

  context(@"different number of channels", ^{
    it(@"should truncate channels when number of channels is less than the input's", ^{
      cv::Vec4b value(1, 2, 3, 4);
      cv::Mat4b input(16, 16);
      input.setTo(value);

      cv::Mat output;
      LTConvertMat(input, &output, CV_8UC2);

      cv::Mat2b truncated(input.rows, input.cols, CV_8UC2);
      truncated.setTo(cv::Vec2b(value[0], value[1]));

      expect(output.type()).to.equal(CV_8UC2);
      expect(LTCompareMat(truncated, output)).to.beTruthy();
    });

    it(@"should pad extra channels with zeros", ^{
      cv::Vec2b value(1, 2);
      cv::Mat2b input(16, 16);
      input.setTo(value);

      cv::Mat output;
      LTConvertMat(input, &output, CV_8UC4);

      cv::Scalar paddedValue(1, 2, 0, 0);
      expect(LTCompareMatWithValue(paddedValue, output)).to.beTruthy();
    });
  });

  context(@"different depth", ^{
    it(@"should scale from ubyte to float", ^{
      cv::Vec4b value(255, 0, 128, 255);
      cv::Mat4b input(16, 16);
      input.setTo(value);

      cv::Mat output;
      LTConvertMat(input, &output, CV_32FC4);

      cv::Scalar convertedValue(1, 0, 0.5, 1);
      expect(LTFuzzyCompareMatWithValue(convertedValue, output)).to.beTruthy();
    });

    it(@"should scale from float to ubyte", ^{
      cv::Vec4f value(1, 0, 0.5, 1);
      cv::Mat4f input(16, 16);
      input.setTo(value);

      cv::Mat output;
      LTConvertMat(input, &output, CV_8UC4);

      cv::Scalar convertedValue(255, 0, 128, 255);
      expect(LTFuzzyCompareMatWithValue(convertedValue, output)).to.beTruthy();
    });
  });

  context(@"different depth and channels", ^{
    it(@"should convert depth and number of channels", ^{
      cv::Vec4f value(1, 0.5, 0.5, 1);
      cv::Mat4f input(16, 16);
      input.setTo(value);

      cv::Mat output;
      LTConvertMat(input, &output, CV_8UC2);

      cv::Scalar convertedValue(255, 128);
      expect(LTFuzzyCompareMatWithValue(convertedValue, output)).to.beTruthy();
    });
  });
});

SpecEnd

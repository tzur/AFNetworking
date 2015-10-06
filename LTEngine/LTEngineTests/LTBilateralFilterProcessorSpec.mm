// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBilateralFilterProcessor.h"

#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static const int kBilateralWindowSize = 3;

static cv::Mat4f LTCPUBilateralPass(cv::Mat4f original, cv::Mat4f input,
                                  float rangeSigma, BOOL horizontalPass) {
  cv::Mat output(input.cols, input.rows, CV_32FC4);

  for (int y = 0; y < input.rows; ++y) {
    for (int x = 0; x < input.cols; ++x) {
      float weightedSum = 0;
      cv::Vec4f colorSum(0, 0, 0, 0);

      cv::Vec4f color = original.at<cv::Vec4f>(y, x);

      for (int i = -kBilateralWindowSize; i <= kBilateralWindowSize; ++i) {
        cv::Point samplePos;
        if (horizontalPass) {
          samplePos.x = MAX(MIN(x + i, input.cols - 1), 0);
          samplePos.y = y;
        } else {
          samplePos.x = x;
          samplePos.y = MAX(MIN(y + i, input.rows - 1), 0);
        }

        cv::Vec4f neighborColor = input.at<cv::Vec4f>(samplePos);
        float currentWeight = cv::exp(-cv::norm(neighborColor - color) / rangeSigma);
        weightedSum += currentWeight;

        colorSum += neighborColor * currentWeight;
      }

      output.at<cv::Vec4f>(y, x) = cv::Vec4f(colorSum[0] / weightedSum,
                                             colorSum[1] / weightedSum,
                                             colorSum[2] / weightedSum,
                                             colorSum[3] / weightedSum);
    }
  }

  return output;
}

__unused static cv::Mat4b LTCPUBilateralFilter(cv::Mat4f original, float rangeSigma,
                                               NSUInteger iterations) {
  cv::Mat4f floatOriginal, floatInput;
  original.convertTo(floatOriginal, CV_32FC4, 1.f / 255.f);
  floatOriginal.copyTo(floatInput);

  BOOL horizontal = YES;
  for (NSUInteger i = 0; i < iterations; ++i) {
    floatInput = LTCPUBilateralPass(floatOriginal, floatInput, rangeSigma, horizontal);

    // Enforce float->uchar->float conversion.
    cv::Mat4b afterIteration;
    floatInput.convertTo(afterIteration, CV_8UC4, 255.f);
    afterIteration.convertTo(floatInput, CV_32FC4, 1.f / 255.f);

    horizontal = !horizontal;
  }

  cv::Mat output;
  floatInput.convertTo(output, CV_8UC4, 255.f);

  return output;
}

LTSpecBegin(LTBilateralFilterProcessor)

__block LTTexture *outputA;
__block LTTexture *outputB;
__block LTBilateralFilterProcessor *processor;

beforeEach(^{
  cv::Mat image = LTLoadMat([self class], @"Noise.png");
  LTTexture *input = [LTTexture textureWithImage:image];

  outputA = [LTTexture textureWithPropertiesOf:input];
  outputB = [LTTexture textureWithPropertiesOf:input];

  processor = [[LTBilateralFilterProcessor alloc] initWithInput:input
                                                        outputs:@[outputA, outputB]];
});

afterEach(^{
  outputA = nil;
  outputB = nil;
  processor = nil;
});

it(@"should process input image correctly", ^{
  processor.iterationsPerOutput = @[@1, @2];
  processor.rangeSigma = 0.1;

  [processor process];

  cv::Mat goldA = LTLoadMat([self class], @"NoiseGoldA.png");
  cv::Mat goldB = LTLoadMat([self class], @"NoiseGoldB.png");

  // After long research and discussion, we decided to give a large fuzziness in this test (6, which
  // is ~2% error). We suspect the errors are floating point errors and precision errors when
  // calling functions such as exp() and distance() on the GPU, which may be implemented differently
  // than their parallel CRT implmentations.
  expect(LTFuzzyCompareMat(goldA, [outputA image], 6)).to.beTruthy();
  expect(LTFuzzyCompareMat(goldB, [outputB image], 6)).to.beTruthy();
});

context(@"properties", ^{
  it(@"range sigma", ^{
    const CGFloat kRangeSigma = 1;
    processor.rangeSigma = kRangeSigma;
    expect(processor.rangeSigma).to.equal(kRangeSigma);
  });
});

LTSpecEnd

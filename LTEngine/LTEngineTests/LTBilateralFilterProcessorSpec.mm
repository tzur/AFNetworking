// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBilateralFilterProcessor.h"

#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTBilateralFilterProcessor)

// After long research and discussion, we decided to give a large fuzziness in this test (4, which
// is ~1.5% error). We suspect the errors are floating point errors and precision errors when
// calling functions such as exp() and distance() on the GPU, which may be implemented differently
// than their parallel CRT implmentations.
static const int kMatsComparisonToleranceFactor = 4;

__block LTTexture *input;
__block LTTexture *output;

beforeEach(^{
  cv::Mat inputImage = LTLoadMat([self class], @"Noise.png");

  input = [LTTexture textureWithImage:inputImage];
  output = [LTTexture textureWithPropertiesOf:input];
});

afterEach(^{
  input = nil;
  output = nil;
});

context(@"processing without a guide", ^{
  __block LTBilateralFilterProcessor *processor;

  beforeEach(^{
    processor = [[LTBilateralFilterProcessor alloc] initWithInput:input outputs:@[output]];
  });

  afterEach(^{
    processor = nil;
  });

  it(@"should process with different sigmas correctly", ^{
    processor.iterationsPerOutput = @[@(1)];
    processor.rangeSigma = 0.1;
    [processor process];
    cv::Mat expectedImage = LTLoadMat([self class], @"NoiseBilateralSigma01Steps1.png");
    expect($(output.image)).to.beCloseToMatWithin($(expectedImage), kMatsComparisonToleranceFactor);

    processor.rangeSigma = 0.2;
    [processor process];
    expectedImage = LTLoadMat([self class], @"NoiseBilateralSigma02Steps1.png");
    expect($(output.image)).to.beCloseToMatWithin($(expectedImage), kMatsComparisonToleranceFactor);
  });

  it(@"should process with different iteration count correctly", ^{
    processor.iterationsPerOutput = @[@(1)];
    processor.rangeSigma = 0.1;
    [processor process];
    cv::Mat expectedImage = LTLoadMat([self class], @"NoiseBilateralSigma01Steps1.png");
    expect($(output.image)).to.beCloseToMatWithin($(expectedImage), kMatsComparisonToleranceFactor);

    processor.iterationsPerOutput = @[@(2)];
    [processor process];
    expectedImage = LTLoadMat([self class], @"NoiseBilateralSigma01Steps2.png");
    expect($(output.image)).to.beCloseToMatWithin($(expectedImage), kMatsComparisonToleranceFactor);
  });
});

context(@"processing with a guide", ^{
  __block LTBilateralFilterProcessor *processor;

  beforeEach(^{
    cv::Mat guideImage = LTLoadMat([self class], @"NoiseGuide.png");
    LTTexture *guide = [LTTexture textureWithImage:guideImage];
    processor = [[LTBilateralFilterProcessor alloc] initWithInput:input guide:guide
                                                                outputs:@[output]];
  });

  afterEach(^{
    processor = nil;
  });

  it(@"should process with different sigmas correctly", ^{
    processor.iterationsPerOutput = @[@(1)];
    processor.rangeSigma = 0.1;
    [processor process];
    cv::Mat expectedImage = LTLoadMat([self class], @"NoiseGuidedSigma01Steps1.png");
    expect($(output.image)).to.beCloseToMatWithin($(expectedImage), kMatsComparisonToleranceFactor);

    processor.rangeSigma = 0.2;
    [processor process];
    expectedImage = LTLoadMat([self class], @"NoiseGuidedSigma02Steps1.png");
    expect($(output.image)).to.beCloseToMatWithin($(expectedImage), kMatsComparisonToleranceFactor);
  });

  it(@"should process with different iteration count correctly", ^{
    processor.iterationsPerOutput = @[@(1)];
    processor.rangeSigma = 0.1;
    [processor process];
    cv::Mat expectedImage = LTLoadMat([self class], @"NoiseGuidedSigma01Steps1.png");
    expect($(output.image)).to.beCloseToMatWithin($(expectedImage), kMatsComparisonToleranceFactor);

    processor.iterationsPerOutput = @[@(2)];
    [processor process];
    expectedImage = LTLoadMat([self class], @"NoiseGuidedSigma01Steps2.png");
    expect($(output.image)).to.beCloseToMatWithin($(expectedImage), kMatsComparisonToleranceFactor);
  });
});

SpecEnd

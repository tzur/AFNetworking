// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTGaussianFilterProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static cv::Mat4b LTCreate1DRGBAMat(const std::vector<uchar> &input) {
  cv::Mat4b rgba(1, (int)input.size());
  for (size_t i = 0; i < input.size(); ++i) {
    int x = (int)i;
    rgba(0, x) = cv::Vec4b(input[i], input[i], input[i], 255);
  }
  return rgba;
}

SpecBegin(LTGaussianFilterProcessor)

context(@"parameter validation", ^{
  it(@"should not initialize with invalid numberOfTaps", ^{
    id someTexture = OCMClassMock([LTTexture class]);
    expect(^{
      LTGaussianFilterProcessor * __unused filter =
          [[LTGaussianFilterProcessor alloc] initWithInput:someTexture
                                                   outputs:@[someTexture] numberOfTaps:0];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      LTGaussianFilterProcessor * __unused filter =
          [[LTGaussianFilterProcessor alloc] initWithInput:someTexture
                                                   outputs:@[someTexture] numberOfTaps:4];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      LTGaussianFilterProcessor * __unused filter =
          [[LTGaussianFilterProcessor alloc] initWithInput:someTexture
                                                   outputs:@[someTexture] numberOfTaps:99];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"1D filter kernel", ^{
  __block LTTexture *input;
  __block LTTexture *output;

  beforeEach(^{
    cv::Mat delta = LTCreate1DRGBAMat({0, 0, 0, 0, 0, 255, 0, 0, 0, 0, 0});
    input = [LTTexture textureWithImage:delta];
    output = [LTTexture textureWithPropertiesOf:input];
  });

  afterEach(^{
    input = nil;
    output = nil;
  });

  it(@"should output the box kernel for a very large sigma", ^{
    LTGaussianFilterProcessor *filter =
        [[LTGaussianFilterProcessor alloc] initWithInput:input outputs:@[output] numberOfTaps:3];
    filter.sigma = 999;
    [filter process];
    cv::Mat result = [output image];
    expect($(result)).to.
        equalMat($(LTCreate1DRGBAMat({0, 0, 0, 0, 85, 85, 85, 0, 0, 0, 0})));
  });

  it(@"should output the expected kernel for the given sigma", ^{
    LTGaussianFilterProcessor *filter =
        [[LTGaussianFilterProcessor alloc] initWithInput:input outputs:@[output] numberOfTaps:3];
    filter.sigma = 1;
    [filter process];
    cv::Mat result = [output image];
    expect($(result)).to.
        equalMat($(LTCreate1DRGBAMat({0, 0, 0, 0, 70, 115, 70, 0, 0, 0, 0})));
  });
});

context(@"compare to OpenCV 2d on real image", ^{
  __block LTTexture *input;
  __block LTTexture *output;

  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"GaussianFilterLena256.png")];
    output = [LTTexture textureWithPropertiesOf:input];
  });

  afterEach(^{
    input = nil;
    output = nil;
  });

  it(@"should produce correct output for sigma equals 1", ^{
    const CGFloat kSigma = 1;
    const NSUInteger kKernelSize = 3;
    LTGaussianFilterProcessor *filter =
        [[LTGaussianFilterProcessor alloc] initWithInput:input outputs:@[output]
                                            numberOfTaps:kKernelSize];
    filter.sigma = kSigma;
    [filter process];
    cv::Mat expected;
    cv::GaussianBlur([input image], expected, cv::Size(kKernelSize, kKernelSize), kSigma, kSigma,
        cv::BORDER_REPLICATE);
    expect($([output image])).to.beCloseToMatWithin($(expected), 1);
  });

  it(@"should produce correct output for sigma equals 1.5 and a bigger kernel size", ^{
    const CGFloat kSigma = 1.5;

    // Note: while the kernel fits 7 taps the OpenCV ruins alpha channel for some reason
    const NSUInteger kKernelSize = 9;
    LTGaussianFilterProcessor *filter =
        [[LTGaussianFilterProcessor alloc] initWithInput:input outputs:@[output]
                                            numberOfTaps:kKernelSize];
    filter.sigma = kSigma;
    [filter process];
    cv::Mat expected;
    cv::GaussianBlur([input image], expected, cv::Size(kKernelSize, kKernelSize), kSigma, kSigma,
        cv::BORDER_REPLICATE);
    expect($([output image])).to.beCloseToMatWithin($(expected), 1);
  });
});

context(@"compare to OpenCV 2d delta", ^{
  __block LTTexture *input;
  __block LTTexture *output;

  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"GaussianFilterDelta51.png")];
    output = [LTTexture textureWithPropertiesOf:input];
  });

  afterEach(^{
    input = nil;
    output = nil;
  });

  it(@"should produce correct output for sigma equals 1", ^{
    const CGFloat kSigma = 1;
    const NSUInteger kKernelSize = 3;
    LTGaussianFilterProcessor *filter =
        [[LTGaussianFilterProcessor alloc] initWithInput:input outputs:@[output]
                                            numberOfTaps:kKernelSize];
    filter.sigma = kSigma;
    [filter process];
    cv::Mat expected;
    cv::GaussianBlur([input image], expected, cv::Size(kKernelSize, kKernelSize), kSigma, kSigma,
        cv::BORDER_REPLICATE);
    expect($([output image])).to.beCloseToMatPSNR($(expected), 50);
  });

  it(@"should produce correct output for sigma equals 1.5 and a bigger kernel size", ^{
    const CGFloat kSigma = 1.5;

    // Note: while the kernel fits 7 taps OpenCV ruins alpha channel for some reason.
    const NSUInteger kKernelSize = 9;
    LTGaussianFilterProcessor *filter =
        [[LTGaussianFilterProcessor alloc] initWithInput:input outputs:@[output]
                                            numberOfTaps:kKernelSize];
    filter.sigma = kSigma;
    [filter process];
    cv::Mat expected;
    cv::GaussianBlur([input image], expected, cv::Size(kKernelSize, kKernelSize), kSigma, kSigma,
        cv::BORDER_REPLICATE);
    expect($([output image])).to.beCloseToMatWithin($(expected), 1);
  });
});

SpecEnd

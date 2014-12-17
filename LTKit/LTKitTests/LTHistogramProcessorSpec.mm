// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTHistogramProcessor.h"

#import "LTColorGradient.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTHistogramProcessor)

__block LTTexture *inputTexture;
__block LTHistogramProcessor *processor;

afterEach(^{
  processor = nil;
  inputTexture = nil;
});

context(@"initialization", ^{
  it(@"should not initialize with red texture", ^{
    expect(^{
      inputTexture = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
      processor = [[LTHistogramProcessor alloc] initWithInputTexture:inputTexture];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with half float texture", ^{
    expect(^{
      inputTexture = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                      precision:LTTexturePrecisionHalfFloat
                                         format:LTTextureFormatRGBA allocateMemory:YES];
      processor = [[LTHistogramProcessor alloc] initWithInputTexture:inputTexture];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  it(@"should create correct histogram of the linear gradient", ^{
    inputTexture = [[LTColorGradient identityGradient] textureWithSamplingPoints:256];
    processor = [[LTHistogramProcessor alloc] initWithInputTexture:inputTexture];
    [processor process];

    cv::Mat histogram = cv::Mat1f::ones(256, 1);
    expect($(processor.redHistogram)).to.beCloseToMat($(histogram));
    expect($(processor.greenHistogram)).to.beCloseToMat($(histogram));
    expect($(processor.blueHistogram)).to.beCloseToMat($(histogram));

    expect(processor.maxRedCount).to.equal(1);
    expect(processor.maxGreenCount).to.equal(1);
    expect(processor.maxBlueCount).to.equal(1);
  });

  it(@"should create correct histogram of the delta function", ^{
    inputTexture = [LTTexture textureWithImage:LTCreateDeltaMat(CGSizeMake(4, 4))];
    processor = [[LTHistogramProcessor alloc] initWithInputTexture:inputTexture];
    [processor process];

    cv::Mat1f histogram = cv::Mat1f::zeros(256, 1);
    histogram(0, 0) = 15;
    histogram(255, 0) = 1;

    expect($(processor.redHistogram)).to.beCloseToMat($(histogram));
    expect($(processor.greenHistogram)).to.beCloseToMat($(histogram));
    expect($(processor.blueHistogram)).to.beCloseToMat($(histogram));

    expect(processor.maxRedCount).to.equal(15);
    expect(processor.maxGreenCount).to.equal(15);
    expect(processor.maxBlueCount).to.equal(15);
  });

  it(@"should create correct histogram when channels are not equal", ^{
    cv::Mat4b inputImage(4, 4, cv::Vec4b(0, 128, 255, 255));
    inputImage(0, 0) = cv::Vec4b(0, 0, 0, 255);
    inputImage(0, 1) = cv::Vec4b(0, 128, 0, 255);
    inputTexture = [LTTexture textureWithImage:inputImage];
    processor = [[LTHistogramProcessor alloc] initWithInputTexture:inputTexture];
    [processor process];

    cv::Mat1f redHistogram = cv::Mat1f::zeros(256, 1);
    redHistogram(0, 0) = 16;
    cv::Mat1f greenHistogram = cv::Mat1f::zeros(256, 1);
    greenHistogram(0, 0) = 1;
    greenHistogram(128, 0) = 15;
    cv::Mat1f blueHistogram = cv::Mat1f::zeros(256, 1);
    blueHistogram(0, 0) = 2;
    blueHistogram(255, 0) = 14;

    expect($(processor.redHistogram)).to.beCloseToMat($(redHistogram));
    expect($(processor.greenHistogram)).to.beCloseToMat($(greenHistogram));
    expect($(processor.blueHistogram)).to.beCloseToMat($(blueHistogram));

    expect(processor.maxRedCount).to.equal(16);
    expect(processor.maxGreenCount).to.equal(15);
    expect(processor.maxBlueCount).to.equal(14);
  });
});

LTSpecEnd

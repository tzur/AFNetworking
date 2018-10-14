// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKConstantAlpha.h"

DeviceSpecBegin(PNKConstantAlpha)

static const NSUInteger kInputWidth = 6;
static const NSUInteger kInputHeight = 6;
static const NSUInteger kInputFeatureChannels = 4;

__block id<MTLDevice> device;
__block PNKConstantAlpha *alphaLayer;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  alphaLayer = [[PNKConstantAlpha alloc] initWithDevice:device alpha:0.5];
});

afterEach(^{
  device = nil;
  alphaLayer = nil;
});

context(@"parameter verification", ^{
  __block id<MTLCommandBuffer> commandBuffer;

  beforeEach(^{
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];
  });

  afterEach(^{
    commandBuffer = nil;
  });

  it(@"should raise an exception when input width mismatch", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth * 2, kInputHeight,
                                         kInputFeatureChannels);
    expect(^{
      [alphaLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input height mismatch", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight * 2,
                                         kInputFeatureChannels);
    expect(^{
      [alphaLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input texture is an array", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, 8);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    expect(^{
      [alphaLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when output texture is an array", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, 8);
    expect(^{
      [alphaLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when output texture is not 4 channels", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, 3);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, 3);
    expect(^{
      [alphaLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not raise an exception wuth correct input and output", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, 3);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, 4);
    expect(^{
      [alphaLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
    }).toNot.raiseAny();
  });
});

context(@"kernel input region", ^{
  it(@"should calculate input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, kInputFeatureChannels};
    MTLRegion inputRegion = [alphaLayer inputRegionForOutputSize:outputSize];

    expect($(inputRegion.size)).to.equalMTLSize($(outputSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kInputFeatureChannels};
    MTLSize outputSize = [alphaLayer outputSizeForInputSize:inputSize];

    expect($(inputSize)).to.equalMTLSize($(outputSize));
  });
});

context(@"processing", ^{
  static const cv::Vec4b kRedColor(255, 0, 0, 255);
  static const cv::Vec4b kRedColorHalfAlpha(255, 0, 0, 128);

  __block id<MTLCommandBuffer> commandBuffer;

  beforeEach(^{
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];
  });

  afterEach(^{
    commandBuffer = nil;
  });

  it(@"should adjust alpha channel correctly for RGBA input", ^{
    cv::Mat4b inputMat(kInputWidth, kInputHeight, kRedColor);
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);

    [alphaLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto output = PNKMatFromMTLTexture(outputImage.texture);
    cv::Mat4b expected(kInputWidth, kInputHeight, kRedColorHalfAlpha);
    expect($(output)).to.equalMat($(expected));
  });

  it(@"should adjust alpha channel correctly for RGB input", ^{
    cv::Mat4b inputMat(kInputWidth, kInputHeight, kRedColor);
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, 3);
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);

    [alphaLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto output = PNKMatFromMTLTexture(outputImage.texture);
    cv::Mat4b expected(kInputWidth, kInputHeight, kRedColorHalfAlpha);
    expect($(output)).to.equalMat($(expected));
  });
});

DeviceSpecEnd

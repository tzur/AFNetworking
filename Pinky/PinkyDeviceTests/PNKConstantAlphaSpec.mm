// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKConstantAlpha.h"

DeviceSpecBegin(PNKConstantAlpha)

static const NSUInteger kInputWidth = 6;
static const NSUInteger kInputHeight = 6;
static const NSUInteger kInputFeatureChannels = 4;

__block id<MTLDevice> device;
__block id<MTLCommandBuffer> commandBuffer;
__block PNKConstantAlpha *alphaLayer;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  auto commandQueue = [device newCommandQueue];
  commandBuffer = [commandQueue commandBuffer];
  alphaLayer = [[PNKConstantAlpha alloc] initWithDevice:device alpha:0.5];
});

it(@"should raise an exception when input width mismatch", ^{
  auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
  auto outputImage = PNKImageMakeUnorm(device, kInputWidth * 2, kInputHeight,
                                       kInputFeatureChannels);
  expect(^{
    [alphaLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise an exception when input height mismatch", ^{
  auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
  auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight * 2,
                                       kInputFeatureChannels);
  expect(^{
    [alphaLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise an exception when input texture is an array", ^{
  auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, 8);
  auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
  expect(^{
    [alphaLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise an exception when output texture is an array", ^{
  auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
  auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, 8);
  expect(^{
    [alphaLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
  }).to.raise(NSInvalidArgumentException);
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

  it(@"should adjust alpha channel correctly", ^{
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
});

context(@"PNKUnaryKernel with MPSTemporaryImage", ^{
  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    return @{
      kPNKTemporaryImageExamplesKernel: alphaLayer,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @(kInputFeatureChannels)
    };
  });
});

DeviceSpecEnd

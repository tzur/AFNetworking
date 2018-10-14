// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKGammaCorrection.h"

DeviceSpecBegin(PNKGammaCorrection)

static const NSUInteger kInputWidth = 6;
static const NSUInteger kInputHeight = 6;
static const NSUInteger kInputFeatureChannels = 4;

__block id<MTLDevice> device;
__block PNKGammaCorrection *gammaCorrection;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  gammaCorrection = [[PNKGammaCorrection alloc] initWithDevice:device gamma:0.5];
});

afterEach(^{
  device = nil;
  gammaCorrection = nil;
});

context(@"kernel input verification", ^{
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
      [gammaCorrection encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                 outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input height mismatch", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight * 2,
                                         kInputFeatureChannels);
    expect(^{
      [gammaCorrection encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                 outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input texture is an array", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, 8);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    expect(^{
      [gammaCorrection encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                 outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when output texture is an array", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, 8);
    expect(^{
      [gammaCorrection encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                 outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"kernel input region", ^{
  it(@"should calculate input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, kInputFeatureChannels};
    MTLRegion inputRegion = [gammaCorrection inputRegionForOutputSize:outputSize];

    expect($(inputRegion.size)).to.equalMTLSize($(outputSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kInputFeatureChannels};
    MTLSize outputSize = [gammaCorrection outputSizeForInputSize:inputSize];
    expect($(inputSize)).to.equalMTLSize($(outputSize));
  });
});

context(@"processing", ^{
  __block id<MTLCommandBuffer> commandBuffer;

  beforeEach(^{
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];
  });

  afterEach(^{
    commandBuffer = nil;
  });

  it(@"should adjust alpha channel correctly for Unorm texture", ^{
    cv::Vec4b kInputColor(4, 9, 4, 255);
    cv::Vec4b kGammaCorrectedInputColor(32, 48, 32, 255);
    cv::Mat4b inputMat(kInputWidth, kInputHeight, kInputColor);
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);

    [gammaCorrection encodeToCommandBuffer:commandBuffer inputImage:inputImage
                               outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto output = PNKMatFromMTLTexture(outputImage.texture);
    cv::Mat4b expected(kInputWidth, kInputHeight, kGammaCorrectedInputColor);
    expect($(output)).to.equalMat($(expected));
  });

  it(@"should adjust alpha channel correctly for half float texture", ^{
    cv::Vec4hf kInputColor(half_float::half(4. / 255.), half_float::half(9. / 255.),
                           half_float::half(4. / 255.), half_float::half(1.));
    cv::Vec4hf kGammaCorrectedInputColor(half_float::half(32. / 255.), half_float::half(48. / 255.),
                                         half_float::half(32. / 255.), half_float::half(1.));
    cv::Mat4hf inputMat(kInputWidth, kInputHeight);
    inputMat.setTo(kInputColor);

    auto inputImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                   kInputHeight, kInputFeatureChannels);
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);
    auto outputImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                    kInputHeight, kInputFeatureChannels);

    [gammaCorrection encodeToCommandBuffer:commandBuffer inputImage:inputImage
                               outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto output = PNKMatFromMTLTexture(outputImage.texture);
    cv::Mat4hf expected(kInputWidth, kInputHeight);
    expected.setTo(kGammaCorrectedInputColor);
    expect($(output)).to.beCloseToMatWithin($(expected), @(1e-3));
  });
});

DeviceSpecEnd

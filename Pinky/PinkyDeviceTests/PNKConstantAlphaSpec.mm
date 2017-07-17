// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKConstantAlpha.h"

#import "PNKOpenCVExtensions.h"

static MPSImage *PNKImageMake(id<MTLDevice> device, NSUInteger width, NSUInteger height,
                              NSUInteger channels) {
  auto imageDescriptor =
      [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatUnorm8
                                                     width:width height:height
                                           featureChannels:channels];
  return [[MPSImage alloc] initWithDevice:device imageDescriptor:imageDescriptor];
}

SpecBegin(PNKConstantAlpha)

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
  auto inputImage = PNKImageMake(device, kInputWidth, kInputHeight, kInputFeatureChannels);
  auto outputImage = PNKImageMake(device, kInputWidth * 2, kInputHeight, kInputFeatureChannels);
  expect(^{
    [alphaLayer encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                        outputTexture:outputImage.texture];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise an exception when input height mismatch", ^{
  auto inputImage = PNKImageMake(device, kInputWidth, kInputHeight, kInputFeatureChannels);
  auto outputImage = PNKImageMake(device, kInputWidth, kInputHeight * 2, kInputFeatureChannels);
  expect(^{
    [alphaLayer encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                        outputTexture:outputImage.texture];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise an exception when input texture is an array", ^{
  auto inputImage = PNKImageMake(device, kInputWidth, kInputHeight, 8);
  auto outputImage = PNKImageMake(device, kInputWidth, kInputHeight, kInputFeatureChannels);
  expect(^{
    [alphaLayer encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                        outputTexture:outputImage.texture];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise an exception when output texture is an array", ^{
  auto inputImage = PNKImageMake(device, kInputWidth, kInputHeight, kInputFeatureChannels);
  auto outputImage = PNKImageMake(device, kInputWidth, kInputHeight, 8);
  expect(^{
    [alphaLayer encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                        outputTexture:outputImage.texture];
  }).to.raise(NSInvalidArgumentException);
});

context(@"kernel output size", ^{
  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kInputFeatureChannels};
    MTLSize output = [alphaLayer outputSizeForInputSize:inputSize];

    expect(output.width).to.equal(kInputWidth);
    expect(output.height).to.equal(kInputHeight);
    expect(output.depth).to.equal(kInputFeatureChannels);
  });
});

context(@"processing", ^{
  static const cv::Vec4b kRedColor(255, 0, 0, 255);
  static const cv::Vec4b kRedColorHalfAlpha(255, 0, 0, 128);

  it(@"should adjust alpha channel correctly", ^{
    cv::Mat4b inputMat(kInputWidth, kInputHeight, kRedColor);
    auto imageDescriptor =
        [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatUnorm8
                                                       width:kInputWidth
                                                      height:kInputHeight
                                             featureChannels:kInputFeatureChannels];
    auto inputImage = [[MPSImage alloc] initWithDevice:device imageDescriptor:imageDescriptor];
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);
    auto outputImage = [[MPSImage alloc] initWithDevice:device imageDescriptor:imageDescriptor];

    [alphaLayer encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                        outputTexture:outputImage.texture];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto output = PNKMatFromMTLTexture(outputImage.texture);
    cv::Mat4b expected(kInputWidth, kInputHeight, kRedColorHalfAlpha);
    expect($(output)).to.equalMat($(expected));
  });
});

SpecEnd

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKReflectionPadding.h"

#import <LTEngine/LTOpenCVExtensions.h>

DeviceSpecBegin(PNKReflectionPadding)

static const NSUInteger kInputWidth = 8;
static const NSUInteger kInputHeight = 8;
static const NSUInteger kInputFeatureChannels = 4;
static const NSUInteger kInputArrayFeatureChannels = 12;

static const pnk::SymmetricPadding kPadding = {.width = 3, .height = 6};
static const NSUInteger kOutputWidth = kInputWidth + kPadding.width * 2;
static const NSUInteger kOutputHeight = kInputHeight + kPadding.height * 2;

__block id<MTLDevice> device;
__block id<MTLCommandBuffer> commandBuffer;
__block PNKReflectionPadding *reflectionPadding;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  auto commandQueue = [device newCommandQueue];
  commandBuffer = [commandQueue commandBuffer];
});

context(@"kernel input verification", ^{
  beforeEach(^{
    reflectionPadding = [[PNKReflectionPadding alloc] initWithDevice:device
                                                inputFeatureChannels:kInputFeatureChannels
                                                         paddingSize:kPadding];
  });

  it(@"should raise an exception when input feature channels mismatch", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth, kOutputHeight,
                                         kInputFeatureChannels * 2);
    expect(^{
      [reflectionPadding encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                                 outputTexture:outputImage.texture];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input is array for non-array kernel", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight,
                                        kInputArrayFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth, kOutputHeight,
                                         kInputArrayFeatureChannels);
    expect(^{
      [reflectionPadding encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                                 outputTexture:outputImage.texture];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input width is smaller than padding width", ^{
    auto inputImage = PNKImageMakeUnorm(device, kPadding.width - 1, kInputHeight,
                                        kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, 3 * kPadding.width - 1, kOutputHeight,
                                         kInputFeatureChannels);
    expect(^{
      [reflectionPadding encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                                 outputTexture:outputImage.texture];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input height is smaller than padding height", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kPadding.height - 1,
                                        kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth, 3 * kPadding.height - 1,
                                         kInputFeatureChannels);
    expect(^{
      [reflectionPadding encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                                 outputTexture:outputImage.texture];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when output width is incorrect", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth + 1, kOutputHeight,
                                         kInputFeatureChannels);
    expect(^{
      [reflectionPadding encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                                 outputTexture:outputImage.texture];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when output height is incorrect", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth, kOutputHeight + 1,
                                         kInputFeatureChannels);
    expect(^{
      [reflectionPadding encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                                 outputTexture:outputImage.texture];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"kernel input region", ^{
  beforeEach(^{
    reflectionPadding = [[PNKReflectionPadding alloc] initWithDevice:device
                                                inputFeatureChannels:kInputFeatureChannels
                                                         paddingSize:kPadding];
  });

  it(@"should calculate input region correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kInputFeatureChannels};
    MTLSize outputSize = {
      kInputWidth + kPadding.width * 2,
      kInputHeight + kPadding.height * 2,
      kInputFeatureChannels
    };
    MTLRegion inputRegion = [reflectionPadding inputRegionForOutputSize:outputSize];

    expect($(inputRegion.size)).to.equalMTLSize($(inputSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kInputFeatureChannels};
    MTLSize expectedSize = {
      kInputWidth + kPadding.width * 2,
      kInputHeight + kPadding.height * 2,
      kInputFeatureChannels
    };
    MTLSize outputSize = [reflectionPadding outputSizeForInputSize:inputSize];
    expect($(outputSize)).to.equalMTLSize($(expectedSize));
  });
});

context(@"reflection padding with Unorm8 channel format", ^{
  __block cv::Mat4b inputMat;
  __block cv::Mat4b expected;

  beforeEach(^{
    inputMat = LTLoadMat([self class], @"Lena128.png");
    expected = cv::Mat4b(inputMat.rows + (int)kPadding.height * 2,
                         inputMat.cols + (int)kPadding.width * 2);
    cv::copyMakeBorder(inputMat, expected, (int)kPadding.height, (int)kPadding.height,
                       (int)kPadding.width, (int)kPadding.width,
                       cv::BORDER_REFLECT_101);
  });

  it(@"should add inputs correctly for non-array textures", ^{
    reflectionPadding = [[PNKReflectionPadding alloc] initWithDevice:device
                                                inputFeatureChannels:kInputFeatureChannels
                                                         paddingSize:kPadding];

    auto inputImage = PNKImageMakeUnorm(device, inputMat.cols, inputMat.rows,
                                        kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, expected.cols, expected.rows,
                                         kInputFeatureChannels);

    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    [reflectionPadding encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                               outputTexture:outputImage.texture];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto output = PNKMatFromMTLTexture(outputImage.texture);
    expect($(output)).to.equalMat($(expected));
  });

  it(@"should add inputs correctly for array textures", ^{
    reflectionPadding = [[PNKReflectionPadding alloc] initWithDevice:device
                                                inputFeatureChannels:kInputArrayFeatureChannels
                                                         paddingSize:kPadding];

    auto inputImage = PNKImageMakeUnorm(device, inputMat.cols, inputMat.rows,
                                        kInputArrayFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, expected.cols, expected.rows,
                                         kInputArrayFeatureChannels);

    for (NSUInteger i = 0; i < kInputArrayFeatureChannels / 4; ++i) {
      PNKCopyMatToMTLTexture(inputImage.texture, inputMat, i);
    }

    [reflectionPadding encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                               outputTexture:outputImage.texture];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    for (NSUInteger i = 0; i < kInputArrayFeatureChannels / 4; ++i) {
      auto outputSlice = PNKMatFromMTLTexture(outputImage.texture, i);
      expect($(outputSlice)).to.equalMat($(expected));
    }
  });
});

context(@"PNKUnaryKernel with MPSTemporaryImage", ^{
  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    reflectionPadding = [[PNKReflectionPadding alloc] initWithDevice:device
                                                inputFeatureChannels:kInputFeatureChannels
                                                         paddingSize:kPadding];
    return @{
      kPNKTemporaryImageExamplesKernel: reflectionPadding,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesOutputChannels: @(kInputFeatureChannels)
    };
  });

  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    reflectionPadding = [[PNKReflectionPadding alloc] initWithDevice:device
                                                inputFeatureChannels:kInputArrayFeatureChannels
                                                         paddingSize:kPadding];
    return @{
      kPNKTemporaryImageExamplesKernel: reflectionPadding,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesOutputChannels: @(kInputArrayFeatureChannels)
    };
  });
});

DeviceSpecEnd

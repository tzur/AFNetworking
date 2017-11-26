// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKNearestNeighborUpsampling.h"

#import <LTEngine/LTOpenCVExtensions.h>

DeviceSpecBegin(PNKNearestNeighborUpsampling)

static const NSUInteger kInputWidth = 4;
static const NSUInteger kInputHeight = 4;
static const NSUInteger kInputFeatureChannels = 4;
static const NSUInteger kInputArrayFeatureChannels = 12;

static const NSUInteger kMagnificationFactor = 3;
static const NSUInteger kOutputWidth = kInputWidth * kMagnificationFactor;
static const NSUInteger kOutputHeight = kInputHeight * kMagnificationFactor;

__block id<MTLDevice> device;
__block id<MTLCommandBuffer> commandBuffer;
__block PNKNearestNeighborUpsampling *nearestNeighborUpsampler;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  auto commandQueue = [device newCommandQueue];
  commandBuffer = [commandQueue commandBuffer];
});

context(@"initialization", ^{
  it(@"should raise an exception when magnification factor is zero", ^{
    expect(^{
      nearestNeighborUpsampler =
          [[PNKNearestNeighborUpsampling alloc] initWithDevice:device
                                          inputFeatureChannels:kInputFeatureChannels
                                           magnificationFactor:0];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when magnification factor is one", ^{
    expect(^{
      nearestNeighborUpsampler =
          [[PNKNearestNeighborUpsampling alloc] initWithDevice:device
                                          inputFeatureChannels:kInputFeatureChannels
                                           magnificationFactor:1];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"kernel input verification", ^{
  beforeEach(^{
    nearestNeighborUpsampler =
        [[PNKNearestNeighborUpsampling alloc] initWithDevice:device
                                        inputFeatureChannels:kInputFeatureChannels
                                         magnificationFactor:kMagnificationFactor];
  });

  it(@"should raise an exception when input array length mismatch", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth, kOutputHeight,
                                         kInputArrayFeatureChannels);
    expect(^{
      [nearestNeighborUpsampler encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                                        outputTexture:outputImage.texture];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input is array for non-array kernel", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight,
                                        kInputArrayFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth, kOutputHeight,
                                         kInputArrayFeatureChannels);
    expect(^{
      [nearestNeighborUpsampler encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                                 outputTexture:outputImage.texture];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when output width is incorrect", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth * 2, kOutputHeight,
                                         kInputFeatureChannels);
    expect(^{
      [nearestNeighborUpsampler encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                                        outputTexture:outputImage.texture];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when output height is incorrect", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth, kOutputHeight * 2,
                                         kInputFeatureChannels);
    expect(^{
      [nearestNeighborUpsampler encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                                        outputTexture:outputImage.texture];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"kernel output size", ^{
  beforeEach(^{
    nearestNeighborUpsampler =
        [[PNKNearestNeighborUpsampling alloc] initWithDevice:device
                                        inputFeatureChannels:kInputFeatureChannels
                                         magnificationFactor:kMagnificationFactor];
  });

  it(@"should calculate input region correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kInputFeatureChannels};
    MTLSize outputSize = { kOutputWidth, kOutputHeight, kInputFeatureChannels};
    MTLRegion inputRegion = [nearestNeighborUpsampler inputRegionForOutputSize:outputSize];

    expect($(inputRegion.size)).to.equalMTLSize($(inputSize));
  });
});

context(@"nearest neighbor upsampling with Unorm8 channel format", ^{
  __block cv::Mat4b inputMat;
  __block cv::Mat4b expected;

  beforeEach(^{
    inputMat = LTLoadMat([self class], @"Lena128.png");
    expected = cv::Mat4b(inputMat.rows * kMagnificationFactor,
                         inputMat.cols * kMagnificationFactor);
    cv::resize(inputMat, expected, expected.size(), 0, 0, cv::INTER_NEAREST);
  });

  it(@"should upsample correctly for non-array textures", ^{
    nearestNeighborUpsampler =
        [[PNKNearestNeighborUpsampling alloc] initWithDevice:device
                                        inputFeatureChannels:kInputFeatureChannels
                                         magnificationFactor:kMagnificationFactor];
    auto inputImage = PNKImageMakeUnorm(device, inputMat.cols, inputMat.rows,
                                        kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, expected.cols, expected.rows,
                                         kInputFeatureChannels);
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    [nearestNeighborUpsampler encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                                      outputTexture:outputImage.texture];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto output = PNKMatFromMTLTexture(outputImage.texture);
    expect($(output)).to.equalMat($(expected));
  });

  it(@"should upsample correctly for array textures", ^{
    nearestNeighborUpsampler =
        [[PNKNearestNeighborUpsampling alloc] initWithDevice:device
                                        inputFeatureChannels:kInputArrayFeatureChannels
                                         magnificationFactor:kMagnificationFactor];
    auto inputImage = PNKImageMakeUnorm(device, inputMat.cols, inputMat.rows,
                                        kInputArrayFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, expected.cols, expected.rows,
                                         kInputArrayFeatureChannels);

    for (NSUInteger i = 0; i < kInputArrayFeatureChannels / 4; ++i) {
      PNKCopyMatToMTLTexture(inputImage.texture, inputMat, i);
    }

    [nearestNeighborUpsampler encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
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
    nearestNeighborUpsampler =
        [[PNKNearestNeighborUpsampling alloc] initWithDevice:device
                                        inputFeatureChannels:kInputFeatureChannels
                                         magnificationFactor:2];
    return @{
      kPNKTemporaryImageExamplesKernel: nearestNeighborUpsampler,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesOutputChannels: @(kInputFeatureChannels)
    };
  });

  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    nearestNeighborUpsampler =
        [[PNKNearestNeighborUpsampling alloc] initWithDevice:device
                                        inputFeatureChannels:kInputArrayFeatureChannels
                                         magnificationFactor:2];
    return @{
      kPNKTemporaryImageExamplesKernel: nearestNeighborUpsampler,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesOutputChannels: @(kInputArrayFeatureChannels)
    };
  });
});

DeviceSpecEnd

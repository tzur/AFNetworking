// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKCrop.h"

#import <LTEngine/LTOpenCVExtensions.h>

#import "MPSImage+Factory.h"
#import "PNKPaddingSize.h"

DeviceSpecBegin(PNKCrop)

static const NSUInteger kInputWidth = 20;
static const NSUInteger kInputHeight = 30;
static const NSUInteger kInputFeatureChannels = 4;
static const NSUInteger kInputArrayFeatureChannels = 12;
static const pnk::PaddingSize kMargins = {1, 2, 3, 4};
static const NSUInteger kOutputWidth = kInputWidth - kMargins.left - kMargins.right;
static const NSUInteger kOutputHeight = kInputHeight - kMargins.top - kMargins.bottom;

__block id<MTLDevice> device;
__block PNKCrop *crop;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
});

context(@"kernel input verification", ^{
  __block id<MTLCommandBuffer> commandBuffer;

  beforeEach(^{
    crop = [[PNKCrop alloc] initWithDevice:device margins:kMargins];
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];
  });

  afterEach(^{
    crop = nil;
    commandBuffer = nil;
  });

  it(@"should raise when input and output width do not match", ^{
    auto inputImage = [MPSImage pnk_float16ImageWithDevice:device width:kInputWidth
                                                    height:kInputHeight
                                                  channels:kInputFeatureChannels];
    auto outputImage = [MPSImage pnk_float16ImageWithDevice:device width:kOutputWidth + 1
                                                     height:kOutputHeight
                                                   channels:kInputFeatureChannels];

    expect(^{
      [crop encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when input and output height do not match", ^{
    auto inputImage = [MPSImage pnk_float16ImageWithDevice:device width:kInputWidth
                                                    height:kInputHeight
                                                  channels:kInputFeatureChannels];
    auto outputImage = [MPSImage pnk_float16ImageWithDevice:device width:kOutputWidth
                                                     height:kOutputHeight + 1
                                                   channels:kInputFeatureChannels];

    expect(^{
      [crop encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when input and output feature channel count do not match", ^{
    auto inputImage = [MPSImage pnk_float16ImageWithDevice:device width:kInputWidth
                                                    height:kInputHeight
                                                  channels:kInputFeatureChannels + 1];
    auto outputImage = [MPSImage pnk_float16ImageWithDevice:device width:kOutputWidth
                                                     height:kOutputHeight
                                                   channels:kInputFeatureChannels];

    expect(^{
      [crop encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"kernel output size", ^{
  beforeEach(^{
    crop = [[PNKCrop alloc] initWithDevice:device margins:kMargins];
  });

  it(@"should calculate output size correctly", ^{
    auto inputSize = MTLSizeMake(kInputWidth, kInputHeight, kInputFeatureChannels);
    MTLSize expectedOutputSize = MTLSizeMake(kOutputWidth, kOutputHeight, kInputFeatureChannels);
    MTLSize outputSize = [crop outputSizeForInputSize:inputSize];

    expect($(outputSize)).to.equalMTLSize($(expectedOutputSize));
  });

  it(@"should calculate input region correctly", ^{
    MTLSize outputSize = MTLSizeMake(kOutputWidth, kOutputHeight, kInputFeatureChannels);
    MTLSize expectedInputSize = outputSize;
    MTLSize inputSize = [crop inputRegionForOutputSize:outputSize].size;

    expect($(inputSize)).to.equalMTLSize($(expectedInputSize));
  });
});

context(@"crop correctness", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    crop = [[PNKCrop alloc] initWithDevice:device margins:kMargins];
    auto inputMat = PNKFillMatrix(kInputHeight, kInputWidth, kInputFeatureChannels);

    cv::Rect cropRect(kMargins.left, kMargins.top, kOutputWidth, kOutputHeight);
    auto expectedMat = inputMat(cropRect).clone();
    return @{
      kPNKKernelExamplesKernel: crop,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(kInputFeatureChannels),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat),
      kPNKKernelExamplesInputImageSizeFromInputMat: @(YES)
    };
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    crop = [[PNKCrop alloc] initWithDevice:device margins:kMargins];
    auto inputMat = PNKFillMatrix(kInputHeight, kInputWidth, kInputArrayFeatureChannels);

    cv::Rect cropRect(kMargins.left, kMargins.top, kOutputWidth, kOutputHeight);
    auto expectedMat = inputMat(cropRect).clone();
    return @{
      kPNKKernelExamplesKernel: crop,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(kInputArrayFeatureChannels),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat),
      kPNKKernelExamplesInputImageSizeFromInputMat: @(YES)
    };
  });
});

context(@"PNKUnaryKernel with MPSTemporaryImage", ^{
  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    crop = [[PNKCrop alloc] initWithDevice:device margins:{0, 0, 0, 0}];

    return @{
      kPNKTemporaryImageExamplesKernel: crop,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @(kInputFeatureChannels)
    };
  });
});

DeviceSpecEnd

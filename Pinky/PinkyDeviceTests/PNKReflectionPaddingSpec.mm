// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKReflectionPadding.h"

#import <LTEngine/LTOpenCVExtensions.h>

#import "PNKPaddingSize.h"

DeviceSpecBegin(PNKReflectionPadding)

static const NSUInteger kInputWidth = 8;
static const NSUInteger kInputHeight = 8;
static const NSUInteger kInputFeatureChannels = 4;
static const NSUInteger kInputArrayFeatureChannels = 12;

static const pnk::PaddingSize kPadding = {2, 3, 4, 5};
static const NSUInteger kOutputWidth = kInputWidth + kPadding.left + kPadding.right;
static const NSUInteger kOutputHeight = kInputHeight + kPadding.top + kPadding.bottom;

__block id<MTLDevice> device;
__block PNKReflectionPadding *reflectionPadding;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  reflectionPadding = [[PNKReflectionPadding alloc] initWithDevice:device paddingSize:kPadding];
});

afterEach(^{
  device = nil;
  reflectionPadding = nil;
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

  it(@"should raise an exception when input feature channels mismatch", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth, kOutputHeight,
                                         kInputFeatureChannels * 2);
    expect(^{
      [reflectionPadding encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                   outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input width is smaller than left padding", ^{
    auto inputImage = PNKImageMakeUnorm(device, kPadding.left - 1, kInputHeight,
                                        kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, 2 * kPadding.left + kPadding.right - 1,
                                         kOutputHeight, kInputFeatureChannels);
    expect(^{
      [reflectionPadding encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                   outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input width is smaller than right padding", ^{
    auto inputImage = PNKImageMakeUnorm(device, kPadding.right - 1, kInputHeight,
                                        kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kPadding.left + 2 * kPadding.right - 1,
                                         kOutputHeight, kInputFeatureChannels);
    expect(^{
      [reflectionPadding encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                   outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input height is smaller than top padding", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kPadding.top - 1,
                                        kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth,
                                         2 * kPadding.top + kPadding.bottom - 1,
                                         kInputFeatureChannels);
    expect(^{
      [reflectionPadding encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                   outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input height is smaller than bottom padding", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kPadding.bottom - 1,
                                        kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth,
                                         kPadding.top + 2 * kPadding.bottom - 1,
                                         kInputFeatureChannels);
    expect(^{
      [reflectionPadding encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                   outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when output width is incorrect", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth + 1, kOutputHeight,
                                         kInputFeatureChannels);
    expect(^{
      [reflectionPadding encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                   outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when output height is incorrect", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth, kOutputHeight + 1,
                                         kInputFeatureChannels);
    expect(^{
      [reflectionPadding encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                   outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"kernel input region", ^{
  it(@"should calculate input region correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kInputFeatureChannels};
    MTLSize outputSize = {kOutputWidth, kOutputHeight, kInputFeatureChannels};
    MTLRegion inputRegion = [reflectionPadding inputRegionForOutputSize:outputSize];

    expect($(inputRegion.size)).to.equalMTLSize($(inputSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kInputFeatureChannels};
    MTLSize expectedSize = {kOutputWidth, kOutputHeight, kInputFeatureChannels};
    MTLSize outputSize = [reflectionPadding outputSizeForInputSize:inputSize];
    expect($(outputSize)).to.equalMTLSize($(expectedSize));
  });
});

context(@"reflection padding with Unorm8 channel format", ^{
  __block id<MTLCommandBuffer> commandBuffer;
  __block cv::Mat4b inputMat;
  __block cv::Mat4b expected;

  beforeEach(^{
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];

    inputMat = LTLoadMat([self class], @"Lena128.png");
    expected = cv::Mat4b(inputMat.rows + (int)kPadding.top + (int)kPadding.bottom,
                         inputMat.cols + (int)kPadding.left + (int)kPadding.right);
    cv::copyMakeBorder(inputMat, expected, (int)kPadding.top, (int)kPadding.bottom,
                       (int)kPadding.left, (int)kPadding.right, cv::BORDER_REFLECT_101);
  });

  afterEach(^{
    commandBuffer = nil;
  });

  it(@"should do reflection correctly for non-array textures", ^{
    reflectionPadding = [[PNKReflectionPadding alloc] initWithDevice:device paddingSize:kPadding];

    auto inputImage = PNKImageMakeUnorm(device, inputMat.cols, inputMat.rows,
                                        kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, expected.cols, expected.rows,
                                         kInputFeatureChannels);

    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    [reflectionPadding encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                 outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto output = PNKMatFromMTLTexture(outputImage.texture);
    expect($(output)).to.equalMat($(expected));
  });

  it(@"should add inputs correctly for array textures", ^{
    reflectionPadding = [[PNKReflectionPadding alloc] initWithDevice:device paddingSize:kPadding];

    auto inputImage = PNKImageMakeUnorm(device, inputMat.cols, inputMat.rows,
                                        kInputArrayFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, expected.cols, expected.rows,
                                         kInputArrayFeatureChannels);

    for (NSUInteger i = 0; i < kInputArrayFeatureChannels / 4; ++i) {
      PNKCopyMatToMTLTexture(inputImage.texture, inputMat, i);
    }

    [reflectionPadding encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                 outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    for (NSUInteger i = 0; i < kInputArrayFeatureChannels / 4; ++i) {
      auto outputSlice = PNKMatFromMTLTexture(outputImage.texture, i);
      expect($(outputSlice)).to.equalMat($(expected));
    }
  });
});

context(@"tensorflow golden standard", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    NSBundle *bundle = NSBundle.lt_testBundle;

    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
         @"reflection_padding_input_15x16x32.tensor");
    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
         @"reflection_padding_output_23x22x32.tensor");

    return @{
      kPNKKernelExamplesKernel: reflectionPadding,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(expectedMat.channels()),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat),
      kPNKKernelExamplesInputImageSizeFromInputMat: @(YES)
    };
  });
});

DeviceSpecEnd

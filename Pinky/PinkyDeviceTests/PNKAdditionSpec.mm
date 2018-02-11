// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKAddition.h"

DeviceSpecBegin(PNKAddition)

static const NSUInteger kInputWidth = 5;
static const NSUInteger kInputHeight = 5;
static const NSUInteger kInputFeatureChannels = 4;
static const NSUInteger kInputArrayFeatureChannels = 12;

__block id<MTLDevice> device;
__block PNKAddition *additionOp;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  additionOp = [[PNKAddition alloc] initWithDevice:device];
});

afterEach(^{
  device = nil;
  additionOp = nil;
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
    auto inputAImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto inputBImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight,
                                         kInputFeatureChannels * 2);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    expect(^{
      [additionOp encodeToCommandBuffer:commandBuffer primaryInputImage:inputAImage
                  secondaryInputImage:inputBImage outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input width mismatch", ^{
    auto inputAImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto inputBImage = PNKImageMakeUnorm(device, kInputWidth * 2, kInputHeight,
                                         kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    expect(^{
      [additionOp encodeToCommandBuffer:commandBuffer primaryInputImage:inputAImage
                    secondaryInputImage:inputBImage outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input height mismatch", ^{
    auto inputAImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto inputBImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight * 2,
                                         kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    expect(^{
      [additionOp encodeToCommandBuffer:commandBuffer primaryInputImage:inputAImage
                    secondaryInputImage:inputBImage outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"kernel input region", ^{
  it(@"should calculate primary input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, kInputArrayFeatureChannels};
    MTLRegion primaryInputRegion = [additionOp primaryInputRegionForOutputSize:outputSize];

    expect($(primaryInputRegion.size)).to.equalMTLSize($(outputSize));
  });

  it(@"should calculate secondary input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, kInputArrayFeatureChannels};
    MTLRegion secondaryInputRegion = [additionOp secondaryInputRegionForOutputSize:outputSize];

    expect($(secondaryInputRegion.size)).to.equalMTLSize($(outputSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kInputArrayFeatureChannels};
    MTLSize outputSize = [additionOp outputSizeForPrimaryInputSize:inputSize
                                                secondaryInputSize:inputSize];

    expect($(outputSize)).to.equalMTLSize($(inputSize));
  });
});

context(@"addition operation with Unorm8 channel format", ^{
  static const cv::Vec4b kInputAValue(0, 1, 2, 3);
  static const cv::Vec4b kInputBValue(3, 4, 5, 6);
  static const cv::Vec4b kOutputValue(3, 5, 7, 9);

  __block id<MTLCommandBuffer> commandBuffer;
  __block cv::Mat4b inputAMat;
  __block cv::Mat4b inputBMat;
  __block cv::Mat4b expected;

  beforeEach(^{
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];

    inputAMat = cv::Mat4b(kInputWidth, kInputHeight, kInputAValue);
    inputBMat = cv::Mat4b(kInputWidth, kInputHeight, kInputBValue);
    expected = cv::Mat4b(kInputWidth, kInputHeight, kOutputValue);
  });

  afterEach(^{
    commandBuffer = nil;
  });

  it(@"should add inputs correctly for non-array textures", ^{
    auto inputAImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto inputBImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);

    PNKCopyMatToMTLTexture(inputAImage.texture, inputAMat);
    PNKCopyMatToMTLTexture(inputBImage.texture, inputBMat);

    [additionOp encodeToCommandBuffer:commandBuffer primaryInputImage:inputAImage
                  secondaryInputImage:inputBImage outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto output = PNKMatFromMTLTexture(outputImage.texture);
    expect($(output)).to.equalMat($(expected));
  });

  it(@"should add inputs correctly for array textures", ^{
    auto inputAImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight,
                                         kInputArrayFeatureChannels);
    auto inputBImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight,
                                         kInputArrayFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight,
                                         kInputArrayFeatureChannels);

    for (NSUInteger i = 0; i < kInputArrayFeatureChannels / 4; ++i) {
      PNKCopyMatToMTLTexture(inputAImage.texture, inputAMat, i);
      PNKCopyMatToMTLTexture(inputBImage.texture, inputBMat, i);
    }

    [additionOp encodeToCommandBuffer:commandBuffer primaryInputImage:inputAImage
                  secondaryInputImage:inputBImage outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    for (NSUInteger i = 0; i < kInputArrayFeatureChannels / 4; ++i) {
      auto outputSlice = PNKMatFromMTLTexture(outputImage.texture, i);
      expect($(outputSlice)).to.equalMat($(expected));
    }
  });
});

context(@"addition operation with Float16 channel format", ^{
  static const cv::Vec4hf kInputAValue(half_float::half(0), half_float::half(1),
                                       half_float::half(2), half_float::half(3));
  static const cv::Vec4hf kInputBValue(half_float::half(3), half_float::half(4),
                                       half_float::half(5), half_float::half(6));
  static const cv::Vec4hf kOutputValue(half_float::half(3), half_float::half(5),
                                       half_float::half(7), half_float::half(9));

  __block id<MTLCommandBuffer> commandBuffer;
  __block cv::Mat4hf inputAMat;
  __block cv::Mat4hf inputBMat;
  __block cv::Mat4hf expected;

  beforeEach(^{
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];

    inputAMat = cv::Mat4hf(kInputWidth, kInputHeight);
    inputAMat.setTo(kInputAValue);
    inputBMat = cv::Mat4hf(kInputWidth, kInputHeight);
    inputBMat.setTo(kInputBValue);
    expected = cv::Mat4hf(kInputWidth, kInputHeight);
    expected.setTo(kOutputValue);
  });

  afterEach(^{
    commandBuffer = nil;
  });

  it(@"should add inputs correctly for non-array textures", ^{
    auto inputAImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                    kInputHeight, kInputFeatureChannels);
    auto inputBImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                    kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                    kInputHeight, kInputFeatureChannels);

    PNKCopyMatToMTLTexture(inputAImage.texture, inputAMat);
    PNKCopyMatToMTLTexture(inputBImage.texture, inputBMat);

    [additionOp encodeToCommandBuffer:commandBuffer primaryInputImage:inputAImage
                  secondaryInputImage:inputBImage outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto output = PNKMatFromMTLTexture(outputImage.texture);
    expect($(output)).to.equalMat($(expected));
  });

  it(@"should add inputs correctly for array textures", ^{
    auto inputAImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                    kInputHeight, kInputArrayFeatureChannels);
    auto inputBImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                    kInputHeight, kInputArrayFeatureChannels);
    auto outputImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                    kInputHeight, kInputArrayFeatureChannels);

    for (NSUInteger i = 0; i < kInputArrayFeatureChannels / 4; ++i) {
      PNKCopyMatToMTLTexture(inputAImage.texture, inputAMat, i);
      PNKCopyMatToMTLTexture(inputBImage.texture, inputBMat, i);
    }

    [additionOp encodeToCommandBuffer:commandBuffer primaryInputImage:inputAImage
                  secondaryInputImage:inputBImage outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    for (NSUInteger i = 0; i < kInputArrayFeatureChannels / 4; ++i) {
      auto outputSlice = PNKMatFromMTLTexture(outputImage.texture, i);
      expect($(outputSlice)).to.equalMat($(expected));
    }
  });
});

context(@"PNKBinaryKernel with MPSTemporaryImage", ^{
  itShouldBehaveLike(kPNKTemporaryImageBinaryExamples, ^{
    return @{
      kPNKTemporaryImageExamplesKernel: additionOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @(kInputFeatureChannels)
    };
  });

  itShouldBehaveLike(kPNKTemporaryImageBinaryExamples, ^{
    return @{
      kPNKTemporaryImageExamplesKernel: additionOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @(kInputArrayFeatureChannels)
    };
  });
});

DeviceSpecEnd

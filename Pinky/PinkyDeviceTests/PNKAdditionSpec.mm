// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKAddition.h"

static const NSUInteger kInputWidth = 5;
static const NSUInteger kInputHeight = 5;

template <typename T>
static NSDictionary *PNKBuildDataForKernelExamples(id<MTLDevice> device, NSUInteger channels) {
  auto kernel = [[PNKAddition alloc] initWithDevice:device];

  std::vector<T> primaryInputValues(channels);
  for (NSUInteger i = 0; i < channels; ++i) {
    primaryInputValues[i] = (T)(i + 1);
  }

  auto primaryInputMat = PNKGenerateChannelwiseConstantMatrix<T>(kInputHeight, kInputWidth,
                                                                 primaryInputValues);

  std::vector<T> secondaryInputValues(channels);
  for (NSUInteger i = 0; i < channels; ++i) {
    secondaryInputValues[i] = (T)(i + 2);
  }
  auto secondaryInputMat = PNKGenerateChannelwiseConstantMatrix<T>(kInputHeight, kInputWidth,
                                                                   secondaryInputValues);

  std::vector<T> expectedValues(channels);
  for (NSUInteger i = 0; i < channels; ++i) {
    expectedValues[i] = primaryInputValues[i] + secondaryInputValues[i];
  }
  cv::Mat expectedMat = PNKGenerateChannelwiseConstantMatrix<T>(kInputHeight, kInputWidth,
                                                                expectedValues);

  return @{
    kPNKKernelExamplesKernel: kernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(PNKFeatureChannelFormatFromCVType(cv::DataType<T>::type)),
    kPNKKernelExamplesPrimaryInputChannels: @(channels),
    kPNKKernelExamplesSecondaryInputChannels: @(channels),
    kPNKKernelExamplesOutputChannels: @(channels),
    kPNKKernelExamplesOutputWidth: @(kInputWidth),
    kPNKKernelExamplesOutputHeight: @(kInputHeight),
    kPNKKernelExamplesPrimaryInputMat: $(primaryInputMat),
    kPNKKernelExamplesSecondaryInputMat: $(secondaryInputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat)
  };
}

DeviceSpecBegin(PNKAddition)

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
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, kInputFeatureChannels);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, kInputArrayFeatureChannels);
  });
});

context(@"addition operation with Float16 channel format", ^{
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, kInputFeatureChannels);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, kInputArrayFeatureChannels);
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

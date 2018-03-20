// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKArithmetic.h"

static const NSUInteger kInputWidth = 5;
static const NSUInteger kInputHeight = 5;

template <typename T>
static NSDictionary *PNKBuildDataForKernelExamples(id<MTLDevice> device, NSUInteger channels,
                                                   pnk::ArithmeticOperation operation) {
  auto kernel = [[PNKArithmetic alloc] initWithDevice:device operation:operation];

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
    switch (operation) {
      case pnk::ArithmeticOperationAddition:
        expectedValues[i] = primaryInputValues[i] + secondaryInputValues[i];
        break;
      case pnk::ArithmeticOperationSubstraction:
        expectedValues[i] = primaryInputValues[i] - secondaryInputValues[i];
        break;
      case pnk::ArithmeticOperationMultiplication:
        expectedValues[i] = primaryInputValues[i] * secondaryInputValues[i];
        break;
      case pnk::ArithmeticOperationDivision:
        expectedValues[i] = primaryInputValues[i] / secondaryInputValues[i];
        break;
    }
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

DeviceSpecBegin(PNKArithmetic)

static const NSUInteger kInputFeatureChannels = 4;
static const NSUInteger kInputArrayFeatureChannels = 12;

__block id<MTLDevice> device;
__block PNKArithmetic *additionOp;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  additionOp = [[PNKArithmetic alloc] initWithDevice:device
                                           operation:pnk::ArithmeticOperationAddition];
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
    return PNKBuildDataForKernelExamples<uchar>(device, kInputFeatureChannels,
                                                pnk::ArithmeticOperationAddition);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, kInputArrayFeatureChannels,
                                                pnk::ArithmeticOperationAddition);
  });
});

context(@"arithmetic operations with Float16 channel format", ^{
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, kInputFeatureChannels,
                                                           pnk::ArithmeticOperationAddition);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, kInputArrayFeatureChannels,
                                                           pnk::ArithmeticOperationAddition);
  });
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, kInputFeatureChannels,
                                                           pnk::ArithmeticOperationSubstraction);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, kInputArrayFeatureChannels,
                                                           pnk::ArithmeticOperationSubstraction);
  });
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, kInputFeatureChannels,
                                                           pnk::ArithmeticOperationMultiplication);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, kInputArrayFeatureChannels,
                                                           pnk::ArithmeticOperationMultiplication);
  });
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, kInputFeatureChannels,
                                                           pnk::ArithmeticOperationDivision);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, kInputArrayFeatureChannels,
                                                           pnk::ArithmeticOperationDivision);
  });
});

context(@"tensorflow golden standard", ^{
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    NSBundle *bundle = NSBundle.lt_testBundle;

    auto primaryInputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"add_primary_input_15x16x32.tensor");
    auto secondaryInputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"add_secondary_input_15x16x32.tensor");
    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"add_output_15x16x32.tensor");
    return @{
      kPNKKernelExamplesKernel: additionOp,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesPrimaryInputChannels: @(primaryInputMat.channels()),
      kPNKKernelExamplesSecondaryInputChannels: @(secondaryInputMat.channels()),
      kPNKKernelExamplesOutputChannels: @(expectedMat.channels()),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(primaryInputMat),
      kPNKKernelExamplesSecondaryInputMat: $(secondaryInputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
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

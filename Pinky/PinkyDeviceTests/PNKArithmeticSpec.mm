// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKArithmetic.h"

static const NSUInteger kInputWidth = 5;
static const NSUInteger kInputHeight = 5;

template <typename T>
static NSDictionary *PNKBuildDataForKernelExamples(id<MTLDevice> device, NSUInteger primaryChannels,
                                                   NSUInteger secondaryChannels,
                                                   pnk::ArithmeticOperation operation) {
  auto kernel = [[PNKArithmetic alloc] initWithDevice:device operation:operation];

  std::vector<T> primaryInputValues(primaryChannels);
  for (NSUInteger i = 0; i < primaryChannels; ++i) {
    primaryInputValues[i] = (T)(i + 1);
  }

  auto primaryInputMat = PNKGenerateChannelwiseConstantMatrix<T>(kInputHeight, kInputWidth,
                                                                 primaryInputValues);

  std::vector<T> secondaryInputValues(secondaryChannels);
  for (NSUInteger i = 0; i < secondaryChannels; ++i) {
    secondaryInputValues[i] = (T)(i + 2);
  }
  auto secondaryInputMat = PNKGenerateChannelwiseConstantMatrix<T>(kInputHeight, kInputWidth,
                                                                   secondaryInputValues);
  auto outputChannels = std::max(primaryChannels, secondaryChannels);
  std::vector<T> expectedValues(outputChannels);
  for (NSUInteger i = 0; i < outputChannels; ++i) {
    NSUInteger primaryIndex = std::min(i, primaryChannels - 1);
    NSUInteger secondaryIndex = std::min(i, secondaryChannels - 1);

    switch (operation) {
      case pnk::ArithmeticOperationAddition:
        expectedValues[i] = primaryInputValues[primaryIndex] + secondaryInputValues[secondaryIndex];
        break;
      case pnk::ArithmeticOperationSubstraction:
        expectedValues[i] = primaryInputValues[primaryIndex] - secondaryInputValues[secondaryIndex];
        break;
      case pnk::ArithmeticOperationMultiplication:
        expectedValues[i] = primaryInputValues[primaryIndex] * secondaryInputValues[secondaryIndex];
        break;
      case pnk::ArithmeticOperationDivision:
        expectedValues[i] = primaryInputValues[primaryIndex] / secondaryInputValues[secondaryIndex];
        break;
    }
  }
  cv::Mat expectedMat = PNKGenerateChannelwiseConstantMatrix<T>(kInputHeight, kInputWidth,
                                                                expectedValues);

  return @{
    kPNKKernelExamplesKernel: kernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(PNKFeatureChannelFormatFromCVType(cv::DataType<T>::type)),
    kPNKKernelExamplesPrimaryInputChannels: @(primaryChannels),
    kPNKKernelExamplesSecondaryInputChannels: @(secondaryChannels),
    kPNKKernelExamplesOutputChannels: @(outputChannels),
    kPNKKernelExamplesOutputWidth: @(kInputWidth),
    kPNKKernelExamplesOutputHeight: @(kInputHeight),
    kPNKKernelExamplesPrimaryInputMat: $(primaryInputMat),
    kPNKKernelExamplesSecondaryInputMat: $(secondaryInputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat)
  };
}

DeviceSpecBegin(PNKArithmetic)

static const NSUInteger kSingleChannel = 1;
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
                                                kInputFeatureChannels,
                                                pnk::ArithmeticOperationAddition);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, kInputArrayFeatureChannels,
                                                kInputArrayFeatureChannels,
                                                pnk::ArithmeticOperationAddition);
  });
});

context(@"arithmetic operations with Float16 channel format", ^{
  for (NSUInteger primaryChannels = 1; primaryChannels <= 7; primaryChannels += 3) {
    for (NSUInteger secondaryChannels = 1; secondaryChannels <= 7; secondaryChannels += 3) {
      if (primaryChannels != 1 && secondaryChannels != 1 && primaryChannels != secondaryChannels) {
        continue;
      }

      for (ushort opcode = pnk::ArithmeticOperationAddition;
           opcode <= pnk::ArithmeticOperationDivision; ++opcode) {
        auto operation = (pnk::ArithmeticOperation)opcode;
        itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
          return PNKBuildDataForKernelExamples<half_float::half>(device, primaryChannels,
                                                                 secondaryChannels, operation);
        });
      }
    }
  }
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

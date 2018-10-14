// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKConcatenation.h"

static const NSUInteger kInputWidth = 5;
static const NSUInteger kInputHeight = 5;

template <typename T>
static NSDictionary *PNKBuildDataForKernelExamples(id<MTLDevice> device,
                                                   NSUInteger primaryChannels,
                                                   NSUInteger secondaryChannels) {
  auto kernel = [[PNKConcatenation alloc] initWithDevice:device];

  std::vector<T> primaryInputValues(primaryChannels);
  for (NSUInteger i = 0; i < primaryChannels; ++i) {
    primaryInputValues[i] = (T)(i + 1);
  }
  auto primaryInputMat = PNKGenerateChannelwiseConstantMatrix<T>(kInputHeight, kInputWidth,
                                                                 primaryInputValues);

  std::vector<T> secondaryInputValues(secondaryChannels);
  for (NSUInteger i = 0; i < primaryChannels; ++i) {
    secondaryInputValues[i] = (T)(i + 2);
  }
  auto secondaryInputMat = PNKGenerateChannelwiseConstantMatrix<T>(kInputHeight, kInputWidth,
                                                                   secondaryInputValues);

  std::vector<T> expectedValues = primaryInputValues;
  expectedValues.insert(expectedValues.end(), secondaryInputValues.begin(),
                        secondaryInputValues.end());
  auto expectedMat = PNKGenerateChannelwiseConstantMatrix<T>(kInputHeight, kInputWidth,
                                                             expectedValues);
  return @{
    kPNKKernelExamplesKernel: kernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(PNKFeatureChannelFormatFromCVType(cv::DataType<T>::type)),
    kPNKKernelExamplesPrimaryInputChannels: @(primaryChannels),
    kPNKKernelExamplesSecondaryInputChannels: @(secondaryChannels),
    kPNKKernelExamplesOutputChannels: @(primaryChannels + secondaryChannels),
    kPNKKernelExamplesOutputWidth: @(kInputWidth),
    kPNKKernelExamplesOutputHeight: @(kInputHeight),
    kPNKKernelExamplesPrimaryInputMat: $(primaryInputMat),
    kPNKKernelExamplesSecondaryInputMat: $(secondaryInputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat)
  };
}

DeviceSpecBegin(PNKConcatenation)

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
});

context(@"kernel input region", ^{
  static const NSUInteger kChannelsCount = 3;
  static const NSUInteger kSecondaryChannelsCount = 15;

  __block PNKConcatenation *concatOp;

  beforeEach(^{
    concatOp = [[PNKConcatenation alloc] initWithDevice:device];
  });

  afterEach(^{
    concatOp = nil;
  });

  it(@"should calculate primary input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, kChannelsCount};
    MTLRegion primaryInputRegion = [concatOp primaryInputRegionForOutputSize:outputSize];
    expect($(primaryInputRegion.size)).to.equalMTLSize($(outputSize));
  });

  it(@"should calculate secondary input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, kChannelsCount};
    MTLRegion secondaryInputRegion = [concatOp secondaryInputRegionForOutputSize:outputSize];
    expect($(secondaryInputRegion.size)).to.equalMTLSize($(outputSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize primaryInputSize = {kInputWidth, kInputHeight, kChannelsCount};
    MTLSize secondaryInputSize = {kInputWidth, kInputHeight, kSecondaryChannelsCount};
    MTLSize expectedSize = {kInputWidth, kInputHeight, kChannelsCount + kSecondaryChannelsCount};
    MTLSize outputSize = [concatOp outputSizeForPrimaryInputSize:primaryInputSize
                                              secondaryInputSize:secondaryInputSize];

    expect($(outputSize)).to.equalMTLSize($(expectedSize));
  });
});

context(@"concatenation operation with Unorm8 channel format", ^{
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, 1, 1);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, 2, 2);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, 3, 3);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, 3, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, 4, 3);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, 4, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, 5, 2);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, 5, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, 5, 5);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, 5, 8);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<uchar>(device, 8, 5);
  });
});

context(@"concatenation operation with Float16 channel format", ^{
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, 2, 2);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, 3, 3);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, 3, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, 4, 3);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, 4, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, 5, 2);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, 5, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, 4, 5);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, 5, 5);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, 5, 8);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForKernelExamples<half_float::half>(device, 8, 5);
  });
});

context(@"tensorflow golden standard", ^{
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    auto concatenationOp = [[PNKConcatenation alloc] initWithDevice:device];
    NSBundle *bundle = NSBundle.lt_testBundle;

    auto primaryInputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"concat_primary_input_15x16x32.tensor");
    auto secondaryInputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"concat_secondary_input_15x16x32.tensor");
    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"concat_output_15x16x64.tensor");
    return @{
      kPNKKernelExamplesKernel: concatenationOp,
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

DeviceSpecEnd

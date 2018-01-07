// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKConcatenation.h"

static const NSUInteger kInputWidth = 5;
static const NSUInteger kInputHeight = 5;

static NSDictionary *PNKBuildUnormDataForKernelExamples(id<MTLDevice> device,
                                                        NSUInteger primaryChannels,
                                                        NSUInteger secondaryChannels) {
  auto kernel = [[PNKConcatenation alloc] initWithDevice:device];

  std::vector<uchar> primaryInputValues(primaryChannels);
  for (NSUInteger i = 0; i < primaryChannels; ++i) {
    primaryInputValues[i] = (uchar)(i + 1);
  }
  cv::Mat primaryInputMat = PNKGenerateChannelwiseConstantUcharMatrix(kInputHeight, kInputWidth,
                                                                      primaryInputValues);

  std::vector<uchar> secondaryInputValues(secondaryChannels);
  for (NSUInteger i = 0; i < primaryChannels; ++i) {
    secondaryInputValues[i] = (uchar)(i + 2);
  }
  cv::Mat secondaryInputMat = PNKGenerateChannelwiseConstantUcharMatrix(kInputHeight, kInputWidth,
                                                                        secondaryInputValues);

  std::vector<uchar> expectedValues = primaryInputValues;
  expectedValues.insert(expectedValues.end(), secondaryInputValues.begin(),
                        secondaryInputValues.end());
  cv::Mat expectedMat = PNKGenerateChannelwiseConstantUcharMatrix(kInputHeight, kInputWidth,
                                                                  expectedValues);
  return @{
    kPNKKernelExamplesKernel: kernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatUnorm8),
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

static NSDictionary *PNKBuildHalfFloatDataForKernelExamples(id<MTLDevice> device,
                                                            NSUInteger primaryChannels,
                                                            NSUInteger secondaryChannels) {
  auto kernel = [[PNKConcatenation alloc] initWithDevice:device];

  std::vector<half_float::half> primaryInputValues(primaryChannels);
  for (NSUInteger i = 0; i < primaryChannels; ++i) {
    primaryInputValues[i] = (half_float::half)(i + 1);
  }
  cv::Mat primaryInputMat = PNKGenerateChannelwiseConstantHalfFloatMatrix(kInputHeight, kInputWidth,
                                                                          primaryInputValues);

  std::vector<half_float::half> secondaryInputValues(secondaryChannels);
  for (NSUInteger i = 0; i < primaryChannels; ++i) {
    secondaryInputValues[i] = (half_float::half)(i + 2);
  }
  cv::Mat secondaryInputMat = PNKGenerateChannelwiseConstantHalfFloatMatrix(kInputHeight,
                                                                            kInputWidth,
                                                                            secondaryInputValues);

  std::vector<half_float::half> expectedValues = primaryInputValues;
  expectedValues.insert(expectedValues.end(), secondaryInputValues.begin(),
                        secondaryInputValues.end());
  cv::Mat expectedMat = PNKGenerateChannelwiseConstantHalfFloatMatrix(kInputHeight, kInputWidth,
                                                                      expectedValues);

  return @{
    kPNKKernelExamplesKernel: kernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
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

SpecBegin(PNKConcatenation)

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

context(@"kernel input region", ^{
  static const NSUInteger kChannelsCount = 3;

  __block PNKConcatenation *concatOp;

  beforeEach(^{
    concatOp = [[PNKConcatenation alloc] initWithDevice:device];
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
    MTLSize inputSize = {kInputWidth, kInputHeight, kChannelsCount};
    MTLSize expectedSize = {kInputWidth, kInputHeight, 2 * kChannelsCount};
    MTLSize outputSize = [concatOp outputSizeForPrimaryInputSize:inputSize
                                              secondaryInputSize:inputSize];

    expect($(outputSize)).to.equalMTLSize($(expectedSize));
  });
});

context(@"concatenation operation with Unorm8 channel format", ^{
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 1, 1);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 2, 2);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 3, 3);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 3, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 4, 3);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 4, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 5, 2);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 5, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 5, 5);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 5, 8);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 8, 5);
  });
});

context(@"concatenation operation with Float16 channel format", ^{
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 2, 2);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 3, 3);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 3, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 4, 3);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 4, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 5, 2);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 5, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 4, 5);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 5, 5);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 5, 8);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 8, 5);
  });
});

context(@"PNKTemporaryImageExamples", ^{
  itShouldBehaveLike(kPNKTemporaryImageBinaryExamples, ^{
    auto concatenationOp = [[PNKConcatenation alloc] initWithDevice:device];
    return @{
      kPNKTemporaryImageExamplesKernel: concatenationOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesOutputChannels: @(2)
    };
  });

  itShouldBehaveLike(kPNKTemporaryImageBinaryExamples, ^{
    auto concatenationOp = [[PNKConcatenation alloc] initWithDevice:device];
    return @{
      kPNKTemporaryImageExamplesKernel: concatenationOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesOutputChannels: @(16)
    };
  });
});

SpecEnd

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

context(@"PNKTemporaryImageExamples", ^{
  itShouldBehaveLike(kPNKTemporaryImageBinaryExamples, ^{
    auto concatenationOp = [[PNKConcatenation alloc] initWithDevice:device];
    return @{
      kPNKTemporaryImageExamplesKernel: concatenationOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @(2)
    };
  });

  itShouldBehaveLike(kPNKTemporaryImageBinaryExamples, ^{
    auto concatenationOp = [[PNKConcatenation alloc] initWithDevice:device];
    return @{
      kPNKTemporaryImageExamplesKernel: concatenationOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @(16)
    };
  });
});

DeviceSpecEnd

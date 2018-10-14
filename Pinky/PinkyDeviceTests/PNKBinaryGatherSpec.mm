// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKBinaryGather.h"

static const NSUInteger kInputWidth = 5;
static const NSUInteger kInputHeight = 5;

static NSDictionary *PNKBuildDataForExamples(id<MTLDevice> device, NSUInteger primaryInputChannels,
                                             const std::vector<ushort> &primaryChannelIndices,
                                             NSUInteger secondaryInputChannels,
                                             const std::vector<ushort> &secondaryChannelIndices) {
  auto kernel = [[PNKBinaryGather alloc] initWithDevice:device
                            primaryInputFeatureChannels:primaryInputChannels
                           primaryFeatureChannelIndices:primaryChannelIndices
                          secondaryInputFeatureChannels:secondaryInputChannels
                         secondaryFeatureChannelIndices:secondaryChannelIndices];

  std::vector<uchar> primaryInputValues(primaryInputChannels);
  for (NSUInteger i = 0; i < primaryInputChannels; ++i) {
    primaryInputValues[i] = (uchar)(i + 1);
  }

  std::vector<uchar> secondaryInputValues(secondaryInputChannels);
  for (NSUInteger i = 0; i < secondaryInputChannels; ++i) {
    secondaryInputValues[i] = (uchar)(i + primaryInputChannels + 10);
  }

  std::vector<uchar> outputValues(primaryChannelIndices.size() + secondaryChannelIndices.size());
  for (NSUInteger i = 0; i < outputValues.size(); ++i) {
    outputValues[i] = (i < primaryChannelIndices.size()) ?
        primaryInputValues[primaryChannelIndices[i]] :
        secondaryInputValues[secondaryChannelIndices[i - primaryChannelIndices.size()]];
  }

  auto primaryInputMat = PNKGenerateChannelwiseConstantMatrix(kInputHeight, kInputWidth,
                                                              primaryInputValues);
  auto secondaryInputMat = PNKGenerateChannelwiseConstantMatrix(kInputHeight, kInputWidth,
                                                                secondaryInputValues);

  auto expectedMat = PNKGenerateChannelwiseConstantMatrix(kInputHeight, kInputWidth,
                                                          outputValues);

  return @{
    kPNKKernelExamplesKernel: kernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatUnorm8),
    kPNKKernelExamplesPrimaryInputChannels: @(primaryInputChannels),
    kPNKKernelExamplesSecondaryInputChannels: @(secondaryInputChannels),
    kPNKKernelExamplesOutputChannels: @(outputValues.size()),
    kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
    kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
    kPNKKernelExamplesPrimaryInputMat: $(primaryInputMat),
    kPNKKernelExamplesSecondaryInputMat: $(secondaryInputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat)
  };
}

DeviceSpecBegin(PNKBinaryGather)

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
});

context(@"parameter tests", ^{
  context(@"initialization", ^{
    __block PNKBinaryGather *gather;

    it(@"should raise when primary channels list contains too large indices", ^{
      expect(^{
        gather = [[PNKBinaryGather alloc] initWithDevice:device
                             primaryInputFeatureChannels:2
                            primaryFeatureChannelIndices:{2}
                           secondaryInputFeatureChannels:1
                          secondaryFeatureChannelIndices:{0}];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when secondary channels list contains too large indices", ^{
      expect(^{
        gather = [[PNKBinaryGather alloc] initWithDevice:device
                             primaryInputFeatureChannels:2
                            primaryFeatureChannelIndices:{1}
                           secondaryInputFeatureChannels:1
                          secondaryFeatureChannelIndices:{1}];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"encoding", ^{
    static const NSUInteger kPrimaryInputFeatureChannels = 4;
    static const std::vector<ushort> kPrimaryFeatureChannelIndices = {0, 1};
    static const NSUInteger kSecondaryInputFeatureChannels = 5;
    static const std::vector<ushort> kSecondaryFeatureChannelIndices = {4};
    static const NSUInteger kOutputChannels = (NSUInteger)(kPrimaryFeatureChannelIndices.size() +
                                                           kSecondaryFeatureChannelIndices.size());

    __block PNKBinaryGather *gather;
    __block id<MTLCommandBuffer> commandBuffer;

    beforeEach(^{
      gather = [[PNKBinaryGather alloc] initWithDevice:device
                           primaryInputFeatureChannels:kPrimaryInputFeatureChannels
                          primaryFeatureChannelIndices:kPrimaryFeatureChannelIndices
                         secondaryInputFeatureChannels:kSecondaryInputFeatureChannels
                        secondaryFeatureChannelIndices:kSecondaryFeatureChannelIndices];
      auto commandQueue = [device newCommandQueue];
      commandBuffer = [commandQueue commandBuffer];
    });

    afterEach(^{
      gather = nil;
      commandBuffer = nil;
    });

    it(@"should raise when primary input image width does not fit output image width", ^{
      MTLSize primaryInputSize{kInputWidth + 1, kInputHeight, kPrimaryInputFeatureChannels};
      MTLSize secondaryInputSize{kInputWidth, kInputHeight, kSecondaryInputFeatureChannels};
      MTLSize outputSize{kInputWidth, kInputHeight, kOutputChannels};
      auto primaryInputImage = [MPSImage mtb_float16ImageWithDevice:device size:primaryInputSize];
      auto secondaryInputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                                 size:secondaryInputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [gather encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
                  secondaryInputImage:secondaryInputImage outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when primary input image height does not fit output image height", ^{
      MTLSize primaryInputSize{kInputWidth, kInputHeight + 1, kPrimaryInputFeatureChannels};
      MTLSize secondaryInputSize{kInputWidth, kInputHeight, kSecondaryInputFeatureChannels};
      MTLSize outputSize{kInputWidth, kInputHeight, kOutputChannels};
      auto primaryInputImage = [MPSImage mtb_float16ImageWithDevice:device size:primaryInputSize];
      auto secondaryInputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                                 size:secondaryInputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [gather encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
                  secondaryInputImage:secondaryInputImage outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when secondary input image width does not fit output image width", ^{
      MTLSize primaryInputSize{kInputWidth, kInputHeight, kPrimaryInputFeatureChannels};
      MTLSize secondaryInputSize{kInputWidth + 1, kInputHeight, kSecondaryInputFeatureChannels};
      MTLSize outputSize{kInputWidth, kInputHeight, kOutputChannels};
      auto primaryInputImage = [MPSImage mtb_float16ImageWithDevice:device size:primaryInputSize];
      auto secondaryInputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                                 size:secondaryInputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [gather encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
                  secondaryInputImage:secondaryInputImage outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when secondary input image height does not fit output image height", ^{
      MTLSize primaryInputSize{kInputWidth, kInputHeight, kPrimaryInputFeatureChannels};
      MTLSize secondaryInputSize{kInputWidth, kInputHeight + 1, kSecondaryInputFeatureChannels};
      MTLSize outputSize{kInputWidth, kInputHeight, kOutputChannels};
      auto primaryInputImage = [MPSImage mtb_float16ImageWithDevice:device size:primaryInputSize];
      auto secondaryInputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                                 size:secondaryInputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [gather encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
                  secondaryInputImage:secondaryInputImage outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when primary input image has wrong number of channels", ^{
      MTLSize primaryInputSize{kInputWidth, kInputHeight, kPrimaryInputFeatureChannels + 1};
      MTLSize secondaryInputSize{kInputWidth, kInputHeight, kSecondaryInputFeatureChannels};
      MTLSize outputSize{kInputWidth, kInputHeight, kOutputChannels};
      auto primaryInputImage = [MPSImage mtb_float16ImageWithDevice:device size:primaryInputSize];
      auto secondaryInputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                                 size:secondaryInputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [gather encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
                  secondaryInputImage:secondaryInputImage outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when secondary input image has wrong number of channels", ^{
      MTLSize primaryInputSize{kInputWidth, kInputHeight, kPrimaryInputFeatureChannels};
      MTLSize secondaryInputSize{kInputWidth, kInputHeight, kSecondaryInputFeatureChannels + 1};
      MTLSize outputSize{kInputWidth, kInputHeight, kOutputChannels};
      auto primaryInputImage = [MPSImage mtb_float16ImageWithDevice:device size:primaryInputSize];
      auto secondaryInputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                                 size:secondaryInputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [gather encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
                  secondaryInputImage:secondaryInputImage outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when output image has wrong number of channels", ^{
      MTLSize primaryInputSize{kInputWidth, kInputHeight, kPrimaryInputFeatureChannels};
      MTLSize secondaryInputSize{kInputWidth, kInputHeight, kSecondaryInputFeatureChannels};
      MTLSize outputSize{kInputWidth, kInputHeight, kOutputChannels + 1};
      auto primaryInputImage = [MPSImage mtb_float16ImageWithDevice:device size:primaryInputSize];
      auto secondaryInputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                                 size:secondaryInputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [gather encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
                  secondaryInputImage:secondaryInputImage outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"kernel input region", ^{
  static const NSUInteger kPrimaryInputFeatureChannels = 4;
  static const std::vector<ushort> kPrimaryFeatureChannelIndices = {0, 1};
  static const NSUInteger kSecondaryInputFeatureChannels = 5;
  static const std::vector<ushort> kSecondaryFeatureChannelIndices = {4};
  static const NSUInteger kOutputChannels = (NSUInteger)(kPrimaryFeatureChannelIndices.size() +
                                                         kSecondaryFeatureChannelIndices.size());

  __block PNKBinaryGather *gather;

  beforeEach(^{
    gather = [[PNKBinaryGather alloc] initWithDevice:device
                         primaryInputFeatureChannels:kPrimaryInputFeatureChannels
                        primaryFeatureChannelIndices:kPrimaryFeatureChannelIndices
                       secondaryInputFeatureChannels:kSecondaryInputFeatureChannels
                      secondaryFeatureChannelIndices:kSecondaryFeatureChannelIndices];
  });

  afterEach(^{
    gather = nil;
  });

  it(@"should calculate primary input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, kOutputChannels};
    MTLSize expectedSize = {kInputWidth, kInputHeight, kPrimaryInputFeatureChannels};
    MTLRegion primaryInputRegion = [gather primaryInputRegionForOutputSize:outputSize];
    expect($(primaryInputRegion.size)).to.equalMTLSize($(expectedSize));
  });

  it(@"should calculate secondary input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, kOutputChannels};
    MTLSize expectedSize = {kInputWidth, kInputHeight, kSecondaryInputFeatureChannels};
    MTLRegion secondaryInputRegion = [gather secondaryInputRegionForOutputSize:outputSize];
    expect($(secondaryInputRegion.size)).to.equalMTLSize($(expectedSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize primaryInputSize = {kInputWidth, kInputHeight, kPrimaryInputFeatureChannels};
    MTLSize secondaryInputSize = {kInputWidth, kInputHeight, kSecondaryInputFeatureChannels};
    MTLSize expectedSize = {kInputWidth, kInputHeight, kOutputChannels};
    MTLSize outputSize = [gather outputSizeForPrimaryInputSize:primaryInputSize
                                            secondaryInputSize:secondaryInputSize];
    expect($(outputSize)).to.equalMTLSize($(expectedSize));
  });
});

context(@"gather", ^{
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForExamples(device, 4, {0, 2}, 3, {1, 1});
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForExamples(device, 4, {0, 2, 1}, 3, {2, 1, 0});
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForExamples(device, 4, {0, 2}, 5, {4, 1});
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForExamples(device, 4, {0, 2}, 5, {4, 1, 2});
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForExamples(device, 8, {1}, 4, {2});
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForExamples(device, 8, {0, 2, 5, 1}, 4, {3});
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForExamples(device, 8, {5}, 12, {9});
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildDataForExamples(device, 12, {0, 1, 4, 9}, 16, {2, 3, 5, 7, 11, 13});
  });
});

DeviceSpecEnd

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKGather.h"

static const NSUInteger kInputWidth = 5;
static const NSUInteger kInputHeight = 5;

static NSDictionary *PNKBuildUcharDataForKernelExamples(id<MTLDevice> device,
    NSUInteger inputChannels, const std::vector<ushort> &outputChannelIndices) {
  auto gatherKernel = [[PNKGather alloc] initWithDevice:device inputFeatureChannels:inputChannels
                            outputFeatureChannelIndices:outputChannelIndices];

  std::vector<uchar> inputValues(inputChannels);
  for (NSUInteger i = 0; i < inputChannels; ++i) {
    inputValues[i] = (uchar)(i + 1);
  }

  std::vector<uchar> outputValues(outputChannelIndices.size());
  for (NSUInteger i = 0; i < outputChannelIndices.size(); ++i) {
    outputValues[i] = inputValues[outputChannelIndices[i]];
  }

  auto inputMat = PNKGenerateChannelwiseConstantUcharMatrix(kInputHeight, kInputWidth, inputValues);

  auto expectedMat = PNKGenerateChannelwiseConstantUcharMatrix(kInputHeight, kInputWidth,
                                                               outputValues);

  return @{
    kPNKKernelExamplesKernel: gatherKernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatUnorm8),
    kPNKKernelExamplesOutputChannels: @(outputValues.size()),
    kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
    kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
    kPNKKernelExamplesPrimaryInputMat: $(inputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat)
  };
}

DeviceSpecBegin(PNKGather)

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

context(@"parameter tests", ^{
  context(@"initialization", ^{
    __block PNKGather *gather;

    it(@"should initialize correctly with correct parameters", ^{
      expect(^{
        gather = [[PNKGather alloc] initWithDevice:device inputFeatureChannels:4
                       outputFeatureChannelIndices:{1, 0}];
      }).notTo.raiseAny();
    });

    it(@"should raise when output channels list contains too large indices", ^{
      expect(^{
        gather = [[PNKGather alloc] initWithDevice:device inputFeatureChannels:2
                       outputFeatureChannelIndices:{2}];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"encoding", ^{
    static const NSUInteger kInputChannels = 4;
    static const NSUInteger kOutputChannels = 2;

    __block PNKGather *gather;
    __block id<MTLCommandBuffer> commandBuffer;

    beforeEach(^{
      device = MTLCreateSystemDefaultDevice();
      gather = [[PNKGather alloc] initWithDevice:device inputFeatureChannels:kInputChannels
                     outputFeatureChannelIndices:{0, 1}];
      auto commandQueue = [device newCommandQueue];
      commandBuffer = [commandQueue commandBuffer];
    });

    it(@"should not raise when called with correct parameters", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, kInputChannels};
      MTLSize outputSize{kInputWidth, kInputHeight, kOutputChannels};

      auto inputImage = [MPSImage pnk_imageWithDevice:device
                                               format:MPSImageFeatureChannelFormatFloat16
                                                 size:inputSize];
      auto outputImage = [MPSImage pnk_imageWithDevice:device
                                                format:MPSImageFeatureChannelFormatFloat16
                                                  size:outputSize];
      expect(^{
        [gather encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
      }).notTo.raiseAny();
    });

    it(@"should raise when input image size does not fit output image size", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, kInputChannels};
      MTLSize outputSize{kInputWidth + 1, kInputHeight, kOutputChannels};
      auto inputImage = [MPSImage pnk_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [gather encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input image has wrong number of channels", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, kInputChannels + 1};
      MTLSize outputSize{kInputWidth, kInputHeight, kOutputChannels};
      auto inputImage = [MPSImage pnk_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [gather encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when output image has wrong number of channels", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, kInputChannels};
      MTLSize outputSize{kInputWidth, kInputHeight, kOutputChannels + 1};
      auto inputImage = [MPSImage pnk_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [gather encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"gather", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildUcharDataForKernelExamples(device, 4, {0, 2});
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildUcharDataForKernelExamples(device, 8, {1, 5});
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildUcharDataForKernelExamples(device, 17, {1, 4, 9, 16});
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildUcharDataForKernelExamples(device, 3, {0, 1, 2, 0, 1, 2});
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildUcharDataForKernelExamples(device, 8, {7, 6, 5, 4, 3, 2, 1});
  });
});

context(@"PNKTemporaryImageExamples", ^{
  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    PNKGather *gather = [[PNKGather alloc] initWithDevice:device inputFeatureChannels:4
                              outputFeatureChannelIndices:{0, 1}];
    return @{
      kPNKTemporaryImageExamplesKernel: gather,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesOutputChannels: @2
    };
  });
});

DeviceSpecEnd

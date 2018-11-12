// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKDilatedConvolutionInternalLayer.h"

#import "PNKConvolutionTestUtils.h"

static const NSUInteger kStrideX = 1;
static const NSUInteger kStrideY = 1;

static NSDictionary *PNKBuildHalfFloatDataForKernelExamples(id<MTLDevice> device,
                                                            NSUInteger imageWidth,
                                                            NSUInteger imageHeight,
                                                            NSUInteger kernelWidth,
                                                            NSUInteger kernelHeight,
                                                            NSUInteger inputChannels,
                                                            NSUInteger outputChannels,
                                                            NSUInteger groups,
                                                            NSUInteger dilationX,
                                                            NSUInteger dilationY,
                                                            pnk::PaddingType paddingType) {
  auto convolutionModel = PNKBuildConvolutionModel(kernelWidth, kernelHeight, inputChannels,
                                                   outputChannels, groups, dilationX, dilationY,
                                                   kStrideX, kStrideY, paddingType);

  auto convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                            initWithDevice:device convolutionModel:convolutionModel];

  auto inputMat = PNKFillMatrix((int)imageHeight, (int)imageWidth, (int)inputChannels);

  auto expectedMat = PNKCalculateConvolution(paddingType, inputMat, convolutionModel.kernelWeights,
                                             (int)dilationX, (int)dilationY, (int)kStrideX,
                                             (int)kStrideY, pnk::ActivationTypeIdentity,
                                             cv::Mat1f(), cv::Mat1f());

  return @{
    kPNKKernelExamplesKernel: convolutionKernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
    kPNKKernelExamplesOutputChannels: @(outputChannels),
    kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
    kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
    kPNKKernelExamplesPrimaryInputMat: $(inputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat)
  };
}

DeviceSpecBegin(PNKDilatedConvolutionInternalLayer)

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
});

context(@"parameter tests", ^{
  __block pnk::ConvolutionKernelModel convolutionKernelModel;

  beforeEach(^{
    convolutionKernelModel = PNKBuildConvolutionModel(3, 3, 1, 1, 1, 2, 2, 1, 1,
                                                      pnk::PaddingTypeSame);
  });

  context(@"instantiation", ^{
    __block PNKDilatedConvolutionInternalLayer *convolutionKernel;

    it(@"should instantiate correctly with correct parameters", ^{
      expect(^{
        convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                             initWithDevice:device
                             convolutionModel:convolutionKernelModel];
      }).notTo.raiseAny();
    });

    it(@"should raise when groups is not one", ^{
      convolutionKernelModel.groups = 4;
      expect(^{
        convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                             initWithDevice:device
                             convolutionModel:convolutionKernelModel];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when given invalid padding type", ^{
      convolutionKernelModel.padding = (pnk::PaddingType)10;
      expect(^{
        convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                             initWithDevice:device
                             convolutionModel:convolutionKernelModel];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"encodeToCommandBuffer", ^{
    static const NSUInteger kInputWidth = 32;
    static const NSUInteger kInputHeight = 32;

    __block PNKDilatedConvolutionInternalLayer *convolutionKernel;
    __block id<MTLCommandBuffer> commandBuffer;

    beforeEach(^{
      convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                           initWithDevice:device
                           convolutionModel:convolutionKernelModel];
      auto commandQueue = [device newCommandQueue];
      commandBuffer = [commandQueue commandBuffer];
    });

    afterEach(^{
      convolutionKernel = nil;
      commandBuffer = nil;
    });

    it(@"should not raise when called with correct parameters", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, 1};
      MTLSize outputSize{kInputWidth, kInputHeight, 1};

      auto inputImage = [MPSImage mtb_imageWithDevice:device
                                               format:MPSImageFeatureChannelFormatFloat16
                                                 size:inputSize];
      auto outputImage = [MPSImage mtb_imageWithDevice:device
                                                format:MPSImageFeatureChannelFormatFloat16
                                                  size:outputSize];
      expect(^{
        [convolutionKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                     outputImage:outputImage];
      }).notTo.raiseAny();
    });

    it(@"should raise when input image size does not fit output image size", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, 1};
      MTLSize outputSize{kInputWidth + 1, kInputHeight, 1};

      auto inputImage = [MPSImage mtb_imageWithDevice:device
                                               format:MPSImageFeatureChannelFormatFloat16
                                                 size:inputSize];
      auto outputImage = [MPSImage mtb_imageWithDevice:device
                                                format:MPSImageFeatureChannelFormatFloat16
                                                  size:outputSize];
      expect(^{
        [convolutionKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                     outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input image has wrong number of channels", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, 2};
      MTLSize outputSize{kInputWidth, kInputHeight, 1};

      auto inputImage = [MPSImage mtb_imageWithDevice:device
                                               format:MPSImageFeatureChannelFormatFloat16
                                                 size:inputSize];
      auto outputImage = [MPSImage mtb_imageWithDevice:device
                                                format:MPSImageFeatureChannelFormatFloat16
                                                  size:outputSize];
      expect(^{
        [convolutionKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                     outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when output image has wrong number of channels", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, 1};
      MTLSize outputSize{kInputWidth, kInputHeight, 2};

      auto inputImage = [MPSImage mtb_imageWithDevice:device
                                               format:MPSImageFeatureChannelFormatFloat16
                                                 size:inputSize];
      auto outputImage = [MPSImage mtb_imageWithDevice:device
                                                format:MPSImageFeatureChannelFormatFloat16
                                                  size:outputSize];
      expect(^{
        [convolutionKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                     outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"kernel input region", ^{
  static const NSUInteger kInputWidth = 32;
  static const NSUInteger kInputHeight = 32;
  static const NSUInteger kInputChannels = 32;
  static const NSUInteger kOutputChannels = 16;
  static const NSUInteger kStrideX = 2;
  static const NSUInteger kStrideY = 2;

  __block PNKDilatedConvolutionInternalLayer *convolutionKernel;

  beforeEach(^{
    auto convolutionModel = PNKBuildConvolutionModel(3, 3, kInputChannels, kOutputChannels, 1, 1, 1,
                                                     kStrideX, kStrideY, pnk::PaddingTypeSame);
    convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                         initWithDevice:device convolutionModel:convolutionModel];
  });

  afterEach(^{
    convolutionKernel = nil;
  });

  it(@"should calculate input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, kOutputChannels};
    MTLRegion inputRegion = [convolutionKernel inputRegionForOutputSize:outputSize];
    MTLSize expectedSize = {
      (outputSize.width - 1) * kStrideX + 1,
      (outputSize.height - 1) * kStrideY + 1,
      kInputChannels
    };

    expect($(inputRegion.size)).to.equalMTLSize($(expectedSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kInputChannels};
    MTLSize expectedSize = {
      (inputSize.width - 1) / kStrideX + 1,
      (inputSize.height - 1) / kStrideY + 1,
      kOutputChannels
    };
    MTLSize outputSize = [convolutionKernel outputSizeForInputSize:inputSize];

    expect($(outputSize)).to.equalMTLSize($(expectedSize));
  });
});

context(@"dilated convolution", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1, 1, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1, 2, 2,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 64, 32, 3, 3, 1, 1, 1, 2, 2,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 31, 33, 3, 3, 1, 1, 1, 2, 2,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1, 3, 3,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 2, 2, 1, 4, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 8, 8, 8, 4, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 3, 3, 1, 8, 8,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 3, 5, 1, 4, 4,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 8, 8, 1, 4, 4,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1, 2, 2,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 5, 1, 1, 1, 2, 2,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1, 4, 2,
                                                  pnk::PaddingTypeValid);
  });
});

DeviceSpecEnd

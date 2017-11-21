// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKConvolutionLayer.h"

#import "PNKNeuralNetworkModel.h"
#import "PNKTestUtils.h"

DeviceSpecBegin(PNKConvolutionLayer)

static const NSUInteger kInputWidth = 15;
static const NSUInteger kInputHeight = 16;
static const NSUInteger kInputRGBFeatureChannels = 3;
static const NSUInteger kInputArrayFeatureChannels = 32;
static const NSUInteger kOutputArrayFeatureChannels = 16;

static const NSUInteger kNoStride = 1;
static const NSUInteger kKernelSide = 3;

__block id<MTLDevice> device;
__block id<MTLCommandBuffer> commandBuffer;
__block PNKConvolutionLayer *convolutionOp;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  auto commandQueue = [device newCommandQueue];
  commandBuffer = [commandQueue commandBuffer];
});

context(@"kernel input region", ^{
  __block NSUInteger stride;
  __block NSUInteger kernelSide;
  __block NSUInteger inputChannels;
  __block NSUInteger outputChannels;
  __block pnk::PaddingType padding;

  beforeEach(^{
    stride = kNoStride;
    kernelSide = kKernelSide;
    inputChannels = kInputRGBFeatureChannels;
    outputChannels = kOutputArrayFeatureChannels;
    padding = pnk::PaddingTypeSame;

    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };

    pnk::ConvolutionKernelModel convolutionModel = {
      .kernelWidth = kernelSide,
      .kernelHeight = kernelSide,
      .kernelChannels = inputChannels,
      .groups = 1,
      .inputFeatureChannels = inputChannels,
      .outputFeatureChannels = outputChannels,
      .strideX = stride,
      .strideY = stride,
      .dilationX = 1,
      .dilationY = 1,
      .padding = padding,
      .isDeconvolution = NO,
      .hasBias = NO,
      .deconvolutionOutputSize = CGSizeNull,
      .kernelWeights = cv::Mat1f(1, (int)(kKernelSide * kKernelSide * inputChannels *
                                          outputChannels))
    };
    convolutionOp = [[PNKConvolutionLayer alloc] initWithDevice:device
                                               convolutionModel:convolutionModel
                                                activationModel:activationModel];
  });

  it(@"should calculate primary input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, outputChannels};
    MTLRegion inputRegion = [convolutionOp inputRegionForOutputSize:outputSize];
    MTLSize inputSize = {
      (outputSize.width - 1) * stride + kernelSide,
      (outputSize.height - 1) * stride + kernelSide,
      inputChannels};

    expect($(inputRegion.size)).to.equalMTLSize($(inputSize));
  });
});

context(@"convolution operation with Float16 channel format", ^{
  it(@"should convolve input correctly for array textures", ^{
    NSUInteger stride = kNoStride;
    NSUInteger kernelSide = kKernelSide;
    NSUInteger inputChannels = kInputArrayFeatureChannels;
    NSUInteger outputChannels = kOutputArrayFeatureChannels;
    pnk::PaddingType padding = pnk::PaddingTypeSame;

    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };

    NSBundle *bundle = [NSBundle bundleForClass:[PNKConvolutionLayerSpec class]];

    pnk::ConvolutionKernelModel convolutionModel = {
      .kernelWidth = kernelSide,
      .kernelHeight = kernelSide,
      .kernelChannels = outputChannels,
      .groups = 1,
      .inputFeatureChannels = inputChannels,
      .outputFeatureChannels = outputChannels,
      .strideX = stride,
      .strideY = stride,
      .dilationX = 1,
      .dilationY = 1,
      .padding = padding,
      .isDeconvolution = NO,
      .hasBias = YES,
      .deconvolutionOutputSize = CGSizeNull,
      .kernelWeights = PNKLoadFloatTensorFromBundleResource(bundle, @"conv2d_kernel.weights"),
      .biasWeights = PNKLoadFloatTensorFromBundleResource(bundle, @"conv2d_bias.weights")
    };

    convolutionOp = [[PNKConvolutionLayer alloc] initWithDevice:device
                                               convolutionModel:convolutionModel
                                                activationModel:activationModel];

    auto inputImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                    kInputHeight, inputChannels);
    auto outputImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                    kInputHeight, outputChannels);
    auto expectedImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                      kInputHeight, outputChannels);

    auto inputMat = PNKLoadHalfFloatTensorFromBundleResource(bundle, @"conv2d_input.tensor");
    auto elementsPerSlice = inputImage.width * inputImage.height * 4;
    for (NSUInteger i = 0; i < inputImage.texture.arrayLength; ++i) {
      cv::Rect roi((int)(i * elementsPerSlice), 0, (int)elementsPerSlice, 1);
      PNKCopyMatToMTLTexture(inputImage.texture, inputMat(roi).reshape(4, kInputHeight), i);
    }

    auto expectedMat = PNKLoadHalfFloatTensorFromBundleResource(bundle, @"conv2d_output.tensor");
    elementsPerSlice = expectedImage.width * expectedImage.height * 4;
    for (NSUInteger i = 0; i < expectedImage.texture.arrayLength; ++i) {
      cv::Rect roi((int)(i * elementsPerSlice), 0, (int)elementsPerSlice, 1);
      PNKCopyMatToMTLTexture(expectedImage.texture, expectedMat(roi).reshape(4, kInputHeight), i);
    }

    [convolutionOp encodeToCommandBuffer:commandBuffer inputImage:inputImage
                             outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    for (NSUInteger i = 0; i < outputChannels / 4; ++i) {
      auto outputSlice = PNKMatFromMTLTexture(outputImage.texture, i);
      auto expectedSlice = PNKMatFromMTLTexture(expectedImage.texture, i);
      expect($(outputSlice)).to.beCloseToMatWithin($(expectedSlice), @(5e-2));
    }
  });
});

context(@"PNKUnaryKernel with MPSTemporaryImage", ^{
  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    pnk::ConvolutionKernelModel convolutionModel = {
      .kernelWidth = kKernelSide,
      .kernelHeight = kKernelSide,
      .kernelChannels = kInputRGBFeatureChannels,
      .groups = 1,
      .inputFeatureChannels = kInputRGBFeatureChannels,
      .outputFeatureChannels = kInputRGBFeatureChannels,
      .strideX = kNoStride,
      .strideY = kNoStride,
      .dilationX = 1,
      .dilationY = 1,
      .padding = pnk::PaddingTypeSame,
      .isDeconvolution = NO,
      .hasBias = NO,
      .deconvolutionOutputSize = CGSizeNull,
      .kernelWeights = cv::Mat1f(1, (int)(kKernelSide * kKernelSide * kInputRGBFeatureChannels *
                                          kInputRGBFeatureChannels))
    };
    convolutionOp = [[PNKConvolutionLayer alloc] initWithDevice:device
                                               convolutionModel:convolutionModel];

    return @{
      kPNKTemporaryImageExamplesKernel: convolutionOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @(kInputRGBFeatureChannels)
    };
  });

  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    pnk::ConvolutionKernelModel convolutionModel = {
      .kernelWidth = kKernelSide,
      .kernelHeight = kKernelSide,
      .kernelChannels = kInputArrayFeatureChannels,
      .groups = 1,
      .inputFeatureChannels = kInputArrayFeatureChannels,
      .outputFeatureChannels = kInputArrayFeatureChannels,
      .strideX = kNoStride,
      .strideY = kNoStride,
      .dilationX = 1,
      .dilationY = 1,
      .padding = pnk::PaddingTypeSame,
      .isDeconvolution = NO,
      .hasBias = NO,
      .deconvolutionOutputSize = CGSizeNull,
      .kernelWeights = cv::Mat1f(1, (int)(kKernelSide * kKernelSide * kInputArrayFeatureChannels *
                                          kInputArrayFeatureChannels))
    };
    convolutionOp = [[PNKConvolutionLayer alloc] initWithDevice:device
                                               convolutionModel:convolutionModel];

    return @{
      kPNKTemporaryImageExamplesKernel: convolutionOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @(kInputArrayFeatureChannels)
    };
  });
});

DeviceSpecEnd

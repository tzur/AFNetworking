// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKConvolutionLayer.h"

#import "PNKConvolutionTestUtils.h"
#import "PNKNeuralNetworkModel.h"
#import "PNKTestUtils.h"

static NSDictionary *PNKBuildDataForExamples(id<MTLDevice> device, NSUInteger imageWidth,
                                             NSUInteger imageHeight,  NSUInteger kernelWidth,
                                             NSUInteger kernelHeight, NSUInteger inputChannels,
                                             NSUInteger outputChannels, NSUInteger dilationX,
                                             NSUInteger dilationY, NSUInteger strideX,
                                             NSUInteger strideY, pnk::PaddingType paddingType,
                                             pnk::ActivationType activationType =
                                                 pnk::ActivationTypeIdentity) {
  auto convolutionModel = PNKBuildConvolutionModel(kernelWidth, kernelHeight, inputChannels,
                                                   outputChannels, dilationX, dilationY,
                                                   strideX, strideY, paddingType);
  auto activationModel = PNKBuildActivationModel(outputChannels, activationType);

  auto convolutionKernel = [[PNKConvolutionLayer alloc] initWithDevice:device
                                                      convolutionModel:convolutionModel
                                                       activationModel:activationModel];

  auto inputMat = PNKFillMatrix((int)imageHeight, (int)imageWidth, (int)inputChannels);

  auto expectedMat = PNKCalculateConvolution(paddingType, inputMat, convolutionModel.kernelWeights,
                                             (int)dilationX, (int)dilationY, (int)strideX,
                                             (int)strideY, activationType, activationModel.alpha,
                                             activationModel.beta);

  return @{
    kPNKKernelExamplesKernel: convolutionKernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
    kPNKKernelExamplesOutputChannels: @(outputChannels),
    kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
    kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
    kPNKKernelExamplesPrimaryInputMat: $(inputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat),
    kPNKKernelExamplesInputImageSizeFromInputMat: @(YES)
  };
}

DeviceSpecBegin(PNKConvolutionLayer)

static const NSUInteger kInputHeight = 15;
static const NSUInteger kInputWidth = 16;
static const NSUInteger kInputRGBFeatureChannels = 3;
static const NSUInteger kInputArrayFeatureChannels = 32;
static const NSUInteger kOutputArrayFeatureChannels = 8;

static const NSUInteger kNoStride = 1;
static const NSUInteger kNoDilation = 1;
static const NSUInteger kKernelSide = 3;

__block id<MTLDevice> device;
__block PNKConvolutionLayer *convolutionOp;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
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
      (outputSize.width - 1) * stride + 1,
      (outputSize.height - 1) * stride + 1,
      inputChannels};

    expect($(inputRegion.size)).to.equalMTLSize($(inputSize));
  });
});

context(@"tensorflow golden standard", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    NSUInteger inputChannels = kInputArrayFeatureChannels;
    NSUInteger outputChannels = kOutputArrayFeatureChannels;

    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };

    pnk::ConvolutionKernelModel convolutionModel =
        PNKBuildConvolutionModel(kKernelSide, kKernelSide, inputChannels, outputChannels,
                                 kNoDilation, kNoDilation, kNoStride, kNoStride,
                                 pnk::PaddingTypeSame);

    NSBundle *bundle = NSBundle.lt_testBundle;
    convolutionModel.kernelWeights =
        PNKLoadFloatTensorFromBundleResource(bundle, @"conv_basic_kernel_8x3x3x32.weights");
    convolutionModel.biasWeights =
        PNKLoadFloatTensorFromBundleResource(bundle, @"conv_basic_bias_8.weights");

    convolutionOp = [[PNKConvolutionLayer alloc] initWithDevice:device
                                               convolutionModel:convolutionModel
                                                activationModel:activationModel];
    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"conv_basic_input_15x16x32.tensor");

    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"conv_basic_output_15x16x8.tensor");

    return @{
      kPNKKernelExamplesKernel: convolutionOp,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(outputChannels),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    NSUInteger strideX = 2;
    NSUInteger strideY = 2;
    NSUInteger inputChannels = kInputArrayFeatureChannels;
    NSUInteger outputChannels = kOutputArrayFeatureChannels;

    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };

    pnk::ConvolutionKernelModel convolutionModel =
        PNKBuildConvolutionModel(kKernelSide, kKernelSide, inputChannels, outputChannels,
                                 kNoDilation, kNoDilation, strideX, strideY, pnk::PaddingTypeSame);

    NSBundle *bundle = NSBundle.lt_testBundle;
    convolutionModel.kernelWeights =
        PNKLoadFloatTensorFromBundleResource(bundle, @"conv_stride_kernel_8x3x3x32.weights");
    convolutionModel.biasWeights =
        PNKLoadFloatTensorFromBundleResource(bundle, @"conv_stride_bias_8.weights");

    convolutionOp = [[PNKConvolutionLayer alloc] initWithDevice:device
                                               convolutionModel:convolutionModel
                                                activationModel:activationModel];
    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"conv_stride_input_15x16x32.tensor");
    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"conv_stride_output_8x8x8.tensor");

    return @{
      kPNKKernelExamplesKernel: convolutionOp,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(outputChannels),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat),
      kPNKKernelExamplesInputImageSizeFromInputMat: @(YES)
    };
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    NSUInteger dilationX = 3;
    NSUInteger dilationY = 3;
    NSUInteger inputChannels = kInputArrayFeatureChannels;
    NSUInteger outputChannels = kOutputArrayFeatureChannels;

    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };

    pnk::ConvolutionKernelModel convolutionModel =
        PNKBuildConvolutionModel(kKernelSide, kKernelSide, inputChannels, outputChannels,
                                 dilationX, dilationY, kNoStride, kNoStride, pnk::PaddingTypeSame);

    NSBundle *bundle = NSBundle.lt_testBundle;
    convolutionModel.kernelWeights =
        PNKLoadFloatTensorFromBundleResource(bundle, @"conv_dilation_kernel_8x3x3x32.weights");
    convolutionModel.biasWeights =
        PNKLoadFloatTensorFromBundleResource(bundle, @"conv_dilation_bias_8.weights");

    convolutionOp = [[PNKConvolutionLayer alloc] initWithDevice:device
                                               convolutionModel:convolutionModel
                                                activationModel:activationModel];
    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"conv_dilation_input_15x16x32.tensor");

    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"conv_dilation_output_15x16x8.tensor");

    return @{
      kPNKKernelExamplesKernel: convolutionOp,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(outputChannels),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });
});

context(@"convolution", ^{
  for (ushort paddingType = pnk::PaddingTypeValid; paddingType <= pnk::PaddingTypeSame;
       ++paddingType) {
    for (NSUInteger kernelWidth = 2; kernelWidth <= 3; ++kernelWidth) {
      for (NSUInteger kernelHeight = 2; kernelHeight <= 3; ++kernelHeight) {
        for (NSUInteger strideX = 1; strideX <= 2; ++strideX) {
          for (NSUInteger strideY = 1; strideY <= 2; ++strideY) {
            for (NSUInteger dilationX = 1; dilationX <= 2; ++dilationX) {
              for (NSUInteger dilationY = 1; dilationY <= 2; ++dilationY) {
                itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
                  return PNKBuildDataForExamples(device, 32, 32, kernelWidth, kernelHeight, 1, 1,
                                                 dilationX, dilationY, strideX, strideY,
                                                 (pnk::PaddingType)paddingType);
                });
              }
            }
          }
        }
      }
    }
  }
});

context(@"activation", ^{
  for (ushort activationType = pnk::ActivationTypeIdentity;
       activationType <= pnk::ActivationTypeParametricSoftplus; ++activationType) {
    for (NSUInteger dilation = 1; dilation <= 2; ++dilation) {
      itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
        return PNKBuildDataForExamples(device, 32, 32, 3, 3, 8, 8, dilation, dilation, 1, 1,
                                       pnk::PaddingTypeSame, (pnk::ActivationType)activationType);
      });
    }
  }
});

DeviceSpecEnd

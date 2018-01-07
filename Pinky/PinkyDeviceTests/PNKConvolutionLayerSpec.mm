// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKConvolutionLayer.h"

#import "MPSImage+Factory.h"
#import "PNKConvolutionTestUtils.h"
#import "PNKNeuralNetworkModel.h"
#import "PNKTestUtils.h"

static NSDictionary *PNKBuildHalfFloatDataForKernelExamples(id<MTLDevice> device,
                                                            NSUInteger imageWidth,
                                                            NSUInteger imageHeight,
                                                            NSUInteger kernelWidth,
                                                            NSUInteger kernelHeight,
                                                            NSUInteger inputChannels,
                                                            NSUInteger outputChannels,
                                                            NSUInteger dilationX,
                                                            NSUInteger dilationY,
                                                            NSUInteger strideX,
                                                            NSUInteger strideY,
                                                            pnk::PaddingType paddingType) {
  auto convolutionModel = PNKBuildConvolutionModel(kernelWidth, kernelHeight, inputChannels,
                                                   outputChannels, dilationX, dilationY,
                                                   strideX, strideY, paddingType);

  auto convolutionKernel = [[PNKConvolutionLayer alloc]
                            initWithDevice:device convolutionModel:convolutionModel];

  auto inputMat = PNKFillMatrix((int)imageHeight, (int)imageWidth, (int)inputChannels);

  auto expectedMat = PNKCalculateConvolution(paddingType, inputMat, convolutionModel.kernelWeights,
                                             (int)dilationX, (int)dilationY, (int)strideX,
                                             (int)strideY);

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
static const NSUInteger kOutputArrayFeatureChannels = 16;

static const NSUInteger kNoStride = 1;
static const NSUInteger kNoDilation = 1;
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
        PNKLoadFloatTensorFromBundleResource(bundle, @"conv_basic_kernel_16x3x3x32.weights");
    convolutionModel.biasWeights =
        PNKLoadFloatTensorFromBundleResource(bundle, @"conv_basic_bias_16.weights");

    convolutionOp = [[PNKConvolutionLayer alloc] initWithDevice:device
                                               convolutionModel:convolutionModel
                                                activationModel:activationModel];
    auto inputMatSingleRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"conv_basic_input_15x16x32.tensor");
    auto inputMat = inputMatSingleRow.reshape((int)inputChannels, kInputHeight);

    auto expectedMatSingleRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"conv_basic_output_15x16x16.tensor");
    auto expectedMat = expectedMatSingleRow.reshape((int)outputChannels, kInputHeight);

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
    NSUInteger outputHeight = (kInputHeight - 1) / strideY + 1;

    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };

    pnk::ConvolutionKernelModel convolutionModel =
        PNKBuildConvolutionModel(kKernelSide, kKernelSide, inputChannels, outputChannels,
                                 kNoDilation, kNoDilation, strideX, strideY, pnk::PaddingTypeSame);

    NSBundle *bundle = NSBundle.lt_testBundle;
    convolutionModel.kernelWeights =
        PNKLoadFloatTensorFromBundleResource(bundle, @"conv_stride_kernel_16x3x3x32.weights");
    convolutionModel.biasWeights =
        PNKLoadFloatTensorFromBundleResource(bundle, @"conv_stride_bias_16.weights");

    convolutionOp = [[PNKConvolutionLayer alloc] initWithDevice:device
                                               convolutionModel:convolutionModel
                                                activationModel:activationModel];
    auto inputMatSingleRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"conv_stride_input_15x16x32.tensor");
    auto inputMat = inputMatSingleRow.reshape((int)inputChannels, kInputHeight);

    auto expectedMatSingleRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"conv_stride_output_8x8x16.tensor");
    auto expectedMat = expectedMatSingleRow.reshape((int)outputChannels, (int)outputHeight);

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
        PNKLoadFloatTensorFromBundleResource(bundle, @"conv_dilation_kernel_16x3x3x32.weights");
    convolutionModel.biasWeights =
        PNKLoadFloatTensorFromBundleResource(bundle, @"conv_dilation_bias_16.weights");

    convolutionOp = [[PNKConvolutionLayer alloc] initWithDevice:device
                                               convolutionModel:convolutionModel
                                                activationModel:activationModel];
    auto inputMatSingleRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"conv_dilation_input_15x16x32.tensor");
    auto inputMat = inputMatSingleRow.reshape((int)inputChannels, kInputHeight);

    auto expectedMatSingleRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"conv_dilation_output_15x16x16.tensor");
    auto expectedMat = expectedMatSingleRow.reshape((int)outputChannels, kInputHeight);

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
      kPNKTemporaryImageExamplesOutputChannels: @(kInputRGBFeatureChannels)
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
      kPNKTemporaryImageExamplesOutputChannels: @(kInputArrayFeatureChannels)
    };
  });
});

context(@"convolution", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1, 1, 1, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 2, 2, 1, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1, 1, 5, 5,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 2, 1, 1, 2, 2, 1, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, 4, 1, 1, 2, 2, 1, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 2, 1, 1, 6, 6, 1, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, 4, 1, 1, 6, 6, 1, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 2, 1, 1, 2, 2, 1, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 1, 1, 1, 3, 1, 1, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 1, 1, 1, 3, 1, 1, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 2, 1, 1, 5, 5, 1, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, 4, 1, 1, 3, 3, 1, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 2, 2, 5, 5,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 2, 1, 1, 4, 5, 6, 7,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 4, 1, 1, 3, 3, 2, 52,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, 7, 1, 1, 3, 1, 1, 3,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1, 2, 3, 4,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, 2, 4, 4, 3, 5, 2, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 5, 3, 2, 4,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 2, 1, 1, 2, 2, 2, 2,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 3, 3, 7, 7,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1, 1, 1, 1,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 2, 2, 1, 1,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1, 1, 5, 5,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 2, 1, 1, 2, 2, 1, 1,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, 4, 1, 1, 2, 2, 1, 1,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 2, 1, 1, 6, 6, 1, 1,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, 4, 1, 1, 6, 6, 1, 1,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 2, 1, 1, 2, 2, 1, 1,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 1, 1, 1, 3, 1, 1, 1,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 1, 1, 1, 3, 1, 1, 1,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 2, 1, 1, 5, 5, 1, 1,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, 4, 1, 1, 3, 3, 1, 1,
                                                  pnk::PaddingTypeValid);
  });
});

DeviceSpecEnd

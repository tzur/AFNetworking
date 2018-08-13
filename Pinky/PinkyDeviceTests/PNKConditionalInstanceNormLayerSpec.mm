// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKConditionalInstanceNormLayer.h"

#import "PNKNeuralNetworkModel.h"

DeviceSpecBegin(PNKConditionalInstanceNormLayer)

static const NSUInteger kInputWidth = 16;
static const NSUInteger kInputHeight = 15;
static const NSUInteger kInputRGBFeatureChannels = 3;
static const NSUInteger kInputArrayFeatureChannels = 32;

__block id<MTLDevice> device;
__block PNKConditionalInstanceNormLayer *ciNormOp;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
});

context(@"kernel input region", ^{
  __block NSUInteger inputChannels;

  beforeEach(^{
    inputChannels = kInputRGBFeatureChannels;

    pnk::ActivationKernelModel activationModel {
      .activationType = pnk::ActivationTypeIdentity
    };

    pnk::NormalizationKernelModel normalizationModel {
      .instanceNormalization = YES,
      .inputFeatureChannels = inputChannels,
      .scale = cv::Mat1f(1, (int)inputChannels),
      .shift = cv::Mat1f(1, (int)inputChannels)
    };

    ciNormOp = [[PNKConditionalInstanceNormLayer alloc] initWithDevice:device
                                                    normalizationModel:normalizationModel
                                                       activationModel:activationModel];
  });

  it(@"should calculate primary input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, inputChannels};
    MTLRegion inputRegion = [ciNormOp inputRegionForOutputSize:outputSize];
    expect($(inputRegion.size)).to.equalMTLSize($(outputSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, inputChannels};
    MTLSize outputSize = [ciNormOp outputSizeForInputSize:inputSize];
    expect($(outputSize)).to.equalMTLSize($(inputSize));
  });
});

context(@"encoding parameters checking", ^{
  it(@"should raise when trying to set a condition out of bounds", ^{
    NSUInteger conditionsCount = 3;

    pnk::ActivationKernelModel activationModel {
      .activationType = pnk::ActivationTypeIdentity
    };

    pnk::NormalizationKernelModel normalizationModel {
      .instanceNormalization = YES,
      .inputFeatureChannels = kInputRGBFeatureChannels,
      .scale = cv::Mat1f(1, (int)(kInputRGBFeatureChannels * conditionsCount)),
      .shift = cv::Mat1f(1, (int)(kInputRGBFeatureChannels * conditionsCount))
    };

    ciNormOp = [[PNKConditionalInstanceNormLayer alloc] initWithDevice:device
                                                    normalizationModel:normalizationModel
                                                       activationModel:activationModel];

    auto inputImage = [MPSImage mtb_float16ImageWithDevice:device width:kInputWidth
                                                    height:kInputHeight
                                                  channels:kInputRGBFeatureChannels];

    auto outputImage = [MPSImage mtb_float16ImageWithDevice:device width:kInputWidth
                                                     height:kInputHeight
                                                   channels:kInputRGBFeatureChannels];

    auto commandQueue = [device newCommandQueue];
    auto commandBuffer = [commandQueue commandBuffer];
    auto inputParameters = @{@"condition": @(conditionsCount)};
    expect(^{
      [ciNormOp encodeToCommandBuffer:commandBuffer inputImage:inputImage
                      inputParameters:inputParameters outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"conditional instance normalization kPNKParametricUnaryKernelExamples encoding", ^{
  __block NSBundle *bundle;

  beforeEach(^{
    bundle = NSBundle.lt_testBundle;
  });

  itShouldBehaveLike(kPNKParametricUnaryKernelExamples, ^{
    NSUInteger inputChannels = 3;

    pnk::ActivationKernelModel activationModel {
      .activationType = pnk::ActivationTypeIdentity
    };

    pnk::NormalizationKernelModel normalizationModel {
      .instanceNormalization = YES,
      .inputFeatureChannels = inputChannels,
      .scale = PNKLoadFloatTensorFromBundleResource(bundle,
           @"instance_normalization_single_texture_gamma_3.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle,
          @"instance_normalization_single_texture_beta_3.weights")
    };

    PNKConditionalInstanceNormLayer *kernel =
        [[PNKConditionalInstanceNormLayer alloc] initWithDevice:device
                                             normalizationModel:normalizationModel
                                                activationModel:activationModel];

    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"instance_normalization_single_texture_input_15x16x3.tensor");

    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"instance_normalization_single_texture_output_15x16x3.tensor");

    return @{
      kPNKKernelExamplesKernel: kernel,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(inputChannels),
      kPNKKernelExamplesOutputWidth: @(kInputWidth),
      kPNKKernelExamplesOutputHeight: @(kInputHeight),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesInputParameters: @{@"condition": @0},
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });

  itShouldBehaveLike(kPNKParametricUnaryKernelExamples, ^{
    NSUInteger inputChannels = kInputArrayFeatureChannels;

    pnk::ActivationKernelModel activationModel {
      .activationType = pnk::ActivationTypeIdentity
    };
    pnk::NormalizationKernelModel normalizationModel {
      .instanceNormalization = YES,
      .inputFeatureChannels = inputChannels,
      .scale = PNKLoadFloatTensorFromBundleResource(bundle,
          @"instance_normalization_basic_gamma_32.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle,
          @"instance_normalization_basic_beta_32.weights")
    };

    PNKConditionalInstanceNormLayer *kernel =
        [[PNKConditionalInstanceNormLayer alloc] initWithDevice:device
                                             normalizationModel:normalizationModel
                                                activationModel:activationModel];

    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"instance_normalization_basic_input_15x16x32.tensor");

    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"instance_normalization_basic_output_15x16x32.tensor");

    return @{
      kPNKKernelExamplesKernel: kernel,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(inputChannels),
      kPNKKernelExamplesOutputWidth: @(kInputWidth),
      kPNKKernelExamplesOutputHeight: @(kInputHeight),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesInputParameters: @{@"condition": @0},
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });

  itShouldBehaveLike(kPNKParametricUnaryKernelExamples, ^{
    NSUInteger inputChannels = kInputArrayFeatureChannels;

    pnk::ActivationKernelModel activationModel {
      .activationType = pnk::ActivationTypeReLU
    };
    pnk::NormalizationKernelModel normalizationModel {
      .instanceNormalization = YES,
      .inputFeatureChannels = inputChannels,
      .scale = PNKLoadFloatTensorFromBundleResource(bundle,
          @"instance_normalization_relu_gamma_32.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle,
          @"instance_normalization_relu_beta_32.weights")
    };

    PNKConditionalInstanceNormLayer *kernel =
        [[PNKConditionalInstanceNormLayer alloc] initWithDevice:device
                                             normalizationModel:normalizationModel
                                                activationModel:activationModel];

    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"instance_normalization_relu_input_15x16x32.tensor");

    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"instance_normalization_relu_output_15x16x32.tensor");

    return @{
      kPNKKernelExamplesKernel: kernel,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(inputChannels),
      kPNKKernelExamplesOutputWidth: @(kInputWidth),
      kPNKKernelExamplesOutputHeight: @(kInputHeight),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesInputParameters: @{@"condition": @0},
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });
});

context(@"PNKUnaryKernel with MPSTemporaryImage", ^{
  itShouldBehaveLike(kPNKTemporaryImageParametricUnaryExamples, ^{
    pnk::ActivationKernelModel activationModel {
      .activationType = pnk::ActivationTypeIdentity
    };
    pnk::NormalizationKernelModel normalizationModel {
      .instanceNormalization = YES,
      .inputFeatureChannels = kInputRGBFeatureChannels,
      .scale = cv::Mat1f(1, (int)kInputRGBFeatureChannels),
      .shift = cv::Mat1f(1, (int)kInputRGBFeatureChannels)
    };

    ciNormOp = [[PNKConditionalInstanceNormLayer alloc] initWithDevice:device
                                                    normalizationModel:normalizationModel
                                                       activationModel:activationModel];

    return @{
      kPNKTemporaryImageExamplesKernel: ciNormOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @(kInputRGBFeatureChannels),
      kPNKTemporaryImageExamplesInputParameters: @{@"condition": @0}
    };
  });

  itShouldBehaveLike(kPNKTemporaryImageParametricUnaryExamples, ^{
    pnk::ActivationKernelModel activationModel {
      .activationType = pnk::ActivationTypeIdentity
    };
    pnk::NormalizationKernelModel normalizationModel {
      .instanceNormalization = YES,
      .inputFeatureChannels = kInputArrayFeatureChannels,
      .scale = cv::Mat1f(1, (int)kInputArrayFeatureChannels),
      .shift = cv::Mat1f(1, (int)kInputArrayFeatureChannels)
    };

    ciNormOp = [[PNKConditionalInstanceNormLayer alloc] initWithDevice:device
                                                    normalizationModel:normalizationModel
                                                       activationModel:activationModel];

    return @{
      kPNKTemporaryImageExamplesKernel: ciNormOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @(kInputArrayFeatureChannels),
      kPNKTemporaryImageExamplesInputParameters: @{@"condition": @0}
    };
  });
});

DeviceSpecEnd

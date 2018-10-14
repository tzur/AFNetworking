// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKInstanceNormLayer.h"

#import "PNKNeuralNetworkModel.h"

DeviceSpecBegin(PNKInstanceNormLayer)

static const NSUInteger kInputWidth = 15;
static const NSUInteger kInputHeight = 16;
static const NSUInteger kInputRGBFeatureChannels = 3;
static const NSUInteger kInputArrayFeatureChannels = 32;

__block id<MTLDevice> device;
__block PNKInstanceNormLayer *instanceNormOp;

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

    instanceNormOp = [[PNKInstanceNormLayer alloc] initWithDevice:device
                                               normalizationModel:normalizationModel
                                                  activationModel:activationModel];
  });

  it(@"should calculate input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, inputChannels};
    MTLRegion inputRegion = [instanceNormOp inputRegionForOutputSize:outputSize];
    expect($(inputRegion.size)).to.equalMTLSize($(outputSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, inputChannels};
    MTLSize outputSize = [instanceNormOp outputSizeForInputSize:inputSize];
    expect($(outputSize)).to.equalMTLSize($(inputSize));
  });
});

context(@"instance normalization operation with Float16 channel format", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };

    NSBundle *bundle = NSBundle.lt_testBundle;

    pnk::NormalizationKernelModel normalizationModel = {
      .instanceNormalization = YES,
      .inputFeatureChannels = kInputArrayFeatureChannels,
      .scale = PNKLoadFloatTensorFromBundleResource(bundle,
          @"instance_normalization_basic_gamma_32.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle,
          @"instance_normalization_basic_beta_32.weights")
    };

    instanceNormOp = [[PNKInstanceNormLayer alloc] initWithDevice:device
                                               normalizationModel:normalizationModel
                                                  activationModel:activationModel];

    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"instance_normalization_basic_input_15x16x32.tensor");

    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"instance_normalization_basic_output_15x16x32.tensor");

    return @{
      kPNKKernelExamplesKernel: instanceNormOp,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(kInputArrayFeatureChannels),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };

    NSBundle *bundle = NSBundle.lt_testBundle;

    pnk::NormalizationKernelModel normalizationModel = {
      .instanceNormalization = YES,
      .inputFeatureChannels = kInputRGBFeatureChannels,
      .scale = PNKLoadFloatTensorFromBundleResource(bundle,
          @"instance_normalization_single_texture_gamma_3.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle,
          @"instance_normalization_single_texture_beta_3.weights")
    };

    instanceNormOp = [[PNKInstanceNormLayer alloc] initWithDevice:device
                                               normalizationModel:normalizationModel
                                                  activationModel:activationModel];

    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"instance_normalization_single_texture_input_15x16x3.tensor");

    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"instance_normalization_single_texture_output_15x16x3.tensor");

    return @{
      kPNKKernelExamplesKernel: instanceNormOp,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(kInputRGBFeatureChannels),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeReLU
    };

    NSBundle *bundle = NSBundle.lt_testBundle;

    pnk::NormalizationKernelModel normalizationModel = {
      .instanceNormalization = YES,
      .inputFeatureChannels = kInputArrayFeatureChannels,
      .scale = PNKLoadFloatTensorFromBundleResource(bundle,
          @"instance_normalization_relu_gamma_32.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle,
          @"instance_normalization_relu_beta_32.weights")
    };

    instanceNormOp = [[PNKInstanceNormLayer alloc] initWithDevice:device
                                               normalizationModel:normalizationModel
                                                  activationModel:activationModel];

    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"instance_normalization_relu_input_15x16x32.tensor");

    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"instance_normalization_relu_output_15x16x32.tensor");

    return @{
      kPNKKernelExamplesKernel: instanceNormOp,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(kInputArrayFeatureChannels),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });
});

DeviceSpecEnd

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKConditionalInstanceNormLayer.h"

#import "PNKNeuralNetworkModel.h"

SpecBegin(PNKConditionalInstanceNormLayer)

static const NSUInteger kInputWidth = 15;
static const NSUInteger kInputHeight = 16;
static const NSUInteger kInputRGBFeatureChannels = 3;
static const NSUInteger kInputArrayFeatureChannels = 32;

__block id<MTLDevice> device;
__block id<MTLCommandBuffer> commandBuffer;
__block PNKConditionalInstanceNormLayer *ciNormOp;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  auto commandQueue = [device newCommandQueue];
  commandBuffer = [commandQueue commandBuffer];
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
});

context(@"set conditions", ^{
  __block NSUInteger conditionsCount;

  beforeEach(^{
    conditionsCount = 3;

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
  });

  it(@"raise when trying to set a condition out of bounds", ^{
    expect(^{
      [ciNormOp setSingleCondition:conditionsCount];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"set condition correctly when setting a condition in bounds", ^{
    expect(^{
      [ciNormOp setSingleCondition:conditionsCount - 1];
    }).toNot.raiseAny();
  });
});

context(@"conditional instance normalization PNKUnaryKernel encoding", ^{
  __block NSBundle *bundle;

  beforeEach(^{
    bundle = [NSBundle bundleForClass:[PNKConditionalInstanceNormLayerSpec class]];
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    NSUInteger inputChannels = 4;

    pnk::ActivationKernelModel activationModel {
      .activationType = pnk::ActivationTypeIdentity
    };
    pnk::NormalizationKernelModel normalizationModel {
      .instanceNormalization = YES,
      .inputFeatureChannels = inputChannels,
      .scale = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_nonarray_scale.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_nonarray_shift.weights")
    };

    PNKConditionalInstanceNormLayer *kernel =
        [[PNKConditionalInstanceNormLayer alloc] initWithDevice:device
                                             normalizationModel:normalizationModel
                                                activationModel:activationModel];

    auto inputMat =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_nonarray_input.tensor");
    auto expectedMat =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_nonarray_output.tensor");

    return @{
      kPNKKernelExamplesKernel: kernel,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(inputChannels),
      kPNKKernelExamplesOutputWidth: @(kInputWidth),
      kPNKKernelExamplesOutputHeight: @(kInputHeight),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    NSUInteger inputChannels = kInputArrayFeatureChannels;

    pnk::ActivationKernelModel activationModel {
      .activationType = pnk::ActivationTypeIdentity
    };
    pnk::NormalizationKernelModel normalizationModel {
      .instanceNormalization = YES,
      .inputFeatureChannels = inputChannels,
      .scale = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_scale.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_shift.weights")
    };

    PNKConditionalInstanceNormLayer *kernel =
        [[PNKConditionalInstanceNormLayer alloc] initWithDevice:device
                                             normalizationModel:normalizationModel
                                                activationModel:activationModel];

    auto inputMat = PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_input.tensor");
    auto expectedMat = PNKLoadHalfFloatTensorFromBundleResource(bundle,
                                                                @"instanceNorm_output.tensor");

    return @{
      kPNKKernelExamplesKernel: kernel,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(inputChannels),
      kPNKKernelExamplesOutputWidth: @(kInputWidth),
      kPNKKernelExamplesOutputHeight: @(kInputHeight),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    NSUInteger inputChannels = kInputArrayFeatureChannels;

    pnk::ActivationKernelModel activationModel {
      .activationType = pnk::ActivationTypeReLU
    };
    pnk::NormalizationKernelModel normalizationModel {
      .instanceNormalization = YES,
      .inputFeatureChannels = inputChannels,
      .scale = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_relu_scale.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_relu_shift.weights")
    };

    PNKConditionalInstanceNormLayer *kernel =
        [[PNKConditionalInstanceNormLayer alloc] initWithDevice:device
                                             normalizationModel:normalizationModel
                                                activationModel:activationModel];

    auto inputMat = PNKLoadHalfFloatTensorFromBundleResource(bundle,
                                                             @"instanceNorm_relu_input.tensor");
    auto expectedMat = PNKLoadHalfFloatTensorFromBundleResource(bundle,
                                                                @"instanceNorm_relu_output.tensor");

    return @{
      kPNKKernelExamplesKernel: kernel,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(inputChannels),
      kPNKKernelExamplesOutputWidth: @(kInputWidth),
      kPNKKernelExamplesOutputHeight: @(kInputHeight),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });
});

context(@"PNKUnaryKernel with MPSTemporaryImage", ^{
  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
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
      kPNKTemporaryImageExamplesInputChannels: @(kInputRGBFeatureChannels)
    };
  });

  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
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
      kPNKTemporaryImageExamplesInputChannels: @(kInputArrayFeatureChannels)
    };
  });
});

SpecEnd

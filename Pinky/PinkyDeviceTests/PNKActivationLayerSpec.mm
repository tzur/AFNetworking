// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKActivationLayer.h"

#import "PNKConvolutionTestUtils.h"
#import "PNKNeuralNetworkModel.h"

static NSDictionary *PNKBuildDataForExamples(id<MTLDevice> device, NSUInteger imageWidth,
                                             NSUInteger imageHeight, NSUInteger featureChannels,
                                             pnk::ActivationType activationType) {
  auto activationModel = PNKBuildActivationModel(featureChannels, activationType);

  auto neuron = [[PNKActivationLayer alloc] initWithDevice:device activationModel:activationModel];

  auto inputMat = PNKFillMatrix((int)imageHeight, (int)imageWidth, (int)featureChannels);

  auto expectedMat = PNKCalculateActivation(inputMat, activationType, activationModel.alpha,
                                            activationModel.beta);

  return @{
    kPNKKernelExamplesKernel: neuron,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
    kPNKKernelExamplesOutputChannels: @(featureChannels),
    kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
    kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
    kPNKKernelExamplesPrimaryInputMat: $(inputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat),
    kPNKKernelExamplesInputImageSizeFromInputMat: @(YES)
  };
}

DeviceSpecBegin(PNKActivationLayer)

static const NSUInteger kInputWidth = 15;
static const NSUInteger kInputHeight = 16;
static const NSUInteger kInputRGBFeatureChannels = 3;
static const NSUInteger kInputArrayFeatureChannels = 32;

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = MTLCreateSystemDefaultDevice();
});

context(@"kernel input region", ^{
  __block id<MTLCommandBuffer> commandBuffer;
  __block PNKActivationLayer *neuron;

  beforeEach(^{
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];

    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };
    neuron = [[PNKActivationLayer alloc] initWithDevice:device activationModel:activationModel];
  });

  afterEach(^{
    commandBuffer = nil;
    neuron = nil;
  });

  it(@"should calculate primary input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, kInputArrayFeatureChannels};
    MTLRegion inputRegion = [neuron inputRegionForOutputSize:outputSize];
    expect($(inputRegion.size)).to.equalMTLSize($(outputSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kInputArrayFeatureChannels};
    MTLSize outputSize = [neuron outputSizeForInputSize:inputSize];

    expect($(outputSize)).to.equalMTLSize($(inputSize));
  });
});

context(@"activation", ^{
  for (ushort activationType = pnk::ActivationTypeIdentity;
       activationType <= pnk::ActivationTypeParametricSoftplus; ++activationType) {
    itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
      return PNKBuildDataForExamples(device, kInputWidth, kInputHeight, kInputRGBFeatureChannels,
                                     (pnk::ActivationType)activationType);
    });
    itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
      return PNKBuildDataForExamples(device, kInputWidth, kInputHeight, kInputArrayFeatureChannels,
                                     (pnk::ActivationType)activationType);
    });
  }
});

context(@"tensorflow golden standard", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    auto activationModel = PNKBuildActivationModel(kInputArrayFeatureChannels,
                                                   pnk::ActivationTypeReLU);
    auto neuron = [[PNKActivationLayer alloc] initWithDevice:device
                                             activationModel:activationModel];

    NSBundle *bundle = NSBundle.lt_testBundle;
    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"activation_relu_input_15x16x32.tensor");
    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"activation_relu_output_15x16x32.tensor");

    return @{
      kPNKKernelExamplesKernel: neuron,
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

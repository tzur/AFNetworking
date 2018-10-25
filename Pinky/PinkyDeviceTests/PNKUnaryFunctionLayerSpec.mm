// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "PNKUnaryFunctionLayer.h"

#import <LTEngine/LTOpenCVExtensions.h>

#import "PNKNeuralNetworkModel.h"

DeviceSpecBegin(PNKUnaryFunctionLayer)

static const NSUInteger kInputWidth = 15;
static const NSUInteger kInputHeight = 16;
static const NSUInteger kInputArrayFeatureChannels = 32;

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
});

context(@"kernel input region", ^{
  __block id<MTLCommandBuffer> commandBuffer;
  __block PNKUnaryFunctionLayer *neuron;

  beforeEach(^{
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];

    pnk::UnaryFunctionKernelModel model = {
      .alpha = 1.0,
      .shift = 1.0,
      .scale = 0.5,
      .type = pnk::UnaryTypeThreshold
    };
    neuron = [[PNKUnaryFunctionLayer alloc] initWithDevice:device unaryModel:model];
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

context(@"tensorflow golden standard", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    pnk::UnaryFunctionKernelModel model = {
      .alpha = -6.,
      .shift = 0.0,
      .scale = 1.0,
      .type = pnk::UnaryTypeThreshold
    };
    auto unary = [[PNKUnaryFunctionLayer alloc] initWithDevice:device unaryModel:model];

    cv::Mat1f temp = cv::Mat1f::zeros(1, kInputWidth * kInputHeight * kInputArrayFeatureChannels);
    cv::randu(temp, -100, 100);

    cv::Mat1f tempProcessed = cv::max(model.scale * temp + model.shift, model.alpha);

    cv::Mat inputMat;
    LTConvertMat(temp, &inputMat, CV_16FC1);
    inputMat = inputMat.reshape(kInputArrayFeatureChannels, {kInputHeight, kInputWidth});

    cv::Mat expectedMat;
    LTConvertMat(tempProcessed, &expectedMat, CV_16FC1);
    expectedMat = expectedMat.reshape(kInputArrayFeatureChannels, {kInputHeight, kInputWidth});

    return @{
      kPNKKernelExamplesKernel: unary,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(kInputArrayFeatureChannels),
      kPNKKernelExamplesOutputWidth: @(kInputWidth),
      kPNKKernelExamplesOutputHeight: @(kInputHeight),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });
});

SpecEnd

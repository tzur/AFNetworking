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
__block id<MTLCommandBuffer> commandBuffer;
__block PNKInstanceNormLayer *instanceNormOp;

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

    instanceNormOp = [[PNKInstanceNormLayer alloc] initWithDevice:device
                                               normalizationModel:normalizationModel
                                                  activationModel:activationModel];
  });

  it(@"should calculate primary input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, inputChannels};
    MTLRegion inputRegion = [instanceNormOp inputRegionForOutputSize:outputSize];
    expect($(inputRegion.size)).to.equalMTLSize($(outputSize));
  });
});

context(@"instance normalization operation with Float16 channel format", ^{
  it(@"should normalize input correctly for array textures", ^{
    NSUInteger inputChannels = kInputArrayFeatureChannels;

    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };

    NSBundle *bundle = [NSBundle bundleForClass:[PNKInstanceNormLayerSpec class]];

    pnk::NormalizationKernelModel normalizationModel = {
      .instanceNormalization = YES,
      .inputFeatureChannels = inputChannels,
      .scale = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_scale.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_shift.weights")
    };

    instanceNormOp = [[PNKInstanceNormLayer alloc] initWithDevice:device
                                               normalizationModel:normalizationModel
                                                  activationModel:activationModel];

    auto inputImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                   kInputHeight, inputChannels);
    auto outputImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                    kInputHeight, inputChannels);
    auto expectedImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                      kInputHeight, inputChannels);

    auto inputMat = PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_input.tensor");
    auto elementsPerSlice = inputImage.width * inputImage.height * 4;
    for (NSUInteger i = 0; i < inputImage.texture.arrayLength; ++i) {
      cv::Rect roi((int)(i * elementsPerSlice), 0, (int)elementsPerSlice, 1);
      PNKCopyMatToMTLTexture(inputImage.texture, inputMat(roi).reshape(4, kInputHeight), i);
    }

    auto expectedMat = PNKLoadHalfFloatTensorFromBundleResource(bundle,
                                                                @"instanceNorm_output.tensor");
    elementsPerSlice = expectedImage.width * expectedImage.height * 4;
    for (NSUInteger i = 0; i < expectedImage.texture.arrayLength; ++i) {
      cv::Rect roi((int)(i * elementsPerSlice), 0, (int)elementsPerSlice, 1);
      PNKCopyMatToMTLTexture(expectedImage.texture, expectedMat(roi).reshape(4, kInputHeight), i);
    }

    [instanceNormOp encodeToCommandBuffer:commandBuffer inputImage:inputImage
                              outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    for (NSUInteger i = 0; i < inputChannels / 4; ++i) {
      auto outputSlice = PNKMatFromMTLTexture(outputImage.texture, i);
      auto expectedSlice = PNKMatFromMTLTexture(expectedImage.texture, i);
      expect($(outputSlice)).to.beCloseToMatWithin($(expectedSlice), @(5e-2));
    }
  });

  it(@"should normalize input correctly for non array textures", ^{
    NSUInteger inputChannels = 4;

    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };

    NSBundle *bundle = [NSBundle bundleForClass:[PNKInstanceNormLayerSpec class]];

    pnk::NormalizationKernelModel normalizationModel = {
      .instanceNormalization = YES,
      .inputFeatureChannels = inputChannels,
      .scale = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_nonarray_scale.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_nonarray_shift.weights")
    };

    instanceNormOp = [[PNKInstanceNormLayer alloc] initWithDevice:device
                                               normalizationModel:normalizationModel
                                                  activationModel:activationModel];

    auto inputImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                   kInputHeight, inputChannels);
    auto outputImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                    kInputHeight, inputChannels);
    auto expectedImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                      kInputHeight, inputChannels);

    auto inputMat =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_nonarray_input.tensor");
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat.reshape(4, kInputHeight));

    auto expectedMat =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_nonarray_output.tensor");
    PNKCopyMatToMTLTexture(expectedImage.texture, expectedMat.reshape(4, kInputHeight));

    [instanceNormOp encodeToCommandBuffer:commandBuffer inputImage:inputImage
                              outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto outputSlice = PNKMatFromMTLTexture(outputImage.texture);
    auto expectedSlice = PNKMatFromMTLTexture(expectedImage.texture);
    expect($(outputSlice)).to.beCloseToMatWithin($(expectedSlice), @(5e-2));
  });

  it(@"should normalize input correctly for array textures with ReLU activation", ^{
    NSUInteger inputChannels = kInputArrayFeatureChannels;

    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeReLU
    };

    NSBundle *bundle = [NSBundle bundleForClass:[PNKInstanceNormLayerSpec class]];

    pnk::NormalizationKernelModel normalizationModel = {
      .instanceNormalization = YES,
      .inputFeatureChannels = inputChannels,
      .scale = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_relu_scale.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_relu_shift.weights")
    };

    instanceNormOp = [[PNKInstanceNormLayer alloc] initWithDevice:device
                                               normalizationModel:normalizationModel
                                                  activationModel:activationModel];

    auto inputImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                   kInputHeight, inputChannels);
    auto outputImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                    kInputHeight, inputChannels);
    auto expectedImage = PNKImageMake(device, MPSImageFeatureChannelFormatFloat16, kInputWidth,
                                      kInputHeight, inputChannels);

    auto inputMat =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_relu_input.tensor");
    auto elementsPerSlice = inputImage.width * inputImage.height * 4;
    for (NSUInteger i = 0; i < inputImage.texture.arrayLength; ++i) {
      cv::Rect roi((int)(i * elementsPerSlice), 0, (int)elementsPerSlice, 1);
      PNKCopyMatToMTLTexture(inputImage.texture, inputMat(roi).reshape(4, kInputHeight), i);
    }

    auto expectedMat =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_relu_output.tensor");
    elementsPerSlice = expectedImage.width * expectedImage.height * 4;
    for (NSUInteger i = 0; i < expectedImage.texture.arrayLength; ++i) {
      cv::Rect roi((int)(i * elementsPerSlice), 0, (int)elementsPerSlice, 1);
      PNKCopyMatToMTLTexture(expectedImage.texture, expectedMat(roi).reshape(4, kInputHeight), i);
    }

    [instanceNormOp encodeToCommandBuffer:commandBuffer inputImage:inputImage
                              outputImage:outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    for (NSUInteger i = 0; i < inputChannels / 4; ++i) {
      auto outputSlice = PNKMatFromMTLTexture(outputImage.texture, i);
      auto expectedSlice = PNKMatFromMTLTexture(expectedImage.texture, i);
      expect($(outputSlice)).to.beCloseToMatWithin($(expectedSlice), @(5e-2));
    }
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

    instanceNormOp = [[PNKInstanceNormLayer alloc] initWithDevice:device
                                               normalizationModel:normalizationModel
                                                  activationModel:activationModel];

    return @{
      kPNKTemporaryImageExamplesKernel: instanceNormOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesIsArray: @(NO)
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

    instanceNormOp = [[PNKInstanceNormLayer alloc] initWithDevice:device
                                               normalizationModel:normalizationModel
                                                  activationModel:activationModel];

    return @{
      kPNKTemporaryImageExamplesKernel: instanceNormOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesIsArray: @(YES)
    };
  });
});

DeviceSpecEnd

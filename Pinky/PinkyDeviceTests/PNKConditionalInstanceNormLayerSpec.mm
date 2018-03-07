// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKConditionalInstanceNormLayer.h"

#import "PNKNeuralNetworkModel.h"

static cv::Mat PNKConvertToMultichannelMatrix(cv::Mat matrix, NSUInteger rows, NSUInteger columns,
                                              NSUInteger channels) {
  LTAssert(matrix.channels() == 1);
  LTAssert(matrix.rows == 1);
  LTAssert(matrix.total() == rows * columns * channels);
  LTAssert(channels % 4 == 0);

  int iRows = (int)rows;
  int iColumns = (int)columns;
  int iChannels = (int)channels;
  int type = matrix.type();

  cv::Mat result(iRows * iColumns, iChannels, type);
  for (int chunk = 0; chunk < iChannels / 4; ++chunk) {
    cv::Rect roi(4 * chunk, 0, 4, iRows * iColumns);
    matrix.colRange(iRows * iColumns * 4 * chunk, iRows * iColumns * 4 * (chunk + 1))
    .reshape(1, iRows * iColumns).copyTo(result(roi));
  }

  return result.reshape(iChannels, iRows);
}

DeviceSpecBegin(PNKConditionalInstanceNormLayer)

static const NSUInteger kInputWidth = 15;
static const NSUInteger kInputHeight = 16;
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

    auto inputImage = [MPSImage pnk_float16ImageWithDevice:device width:kInputWidth
                                                    height:kInputHeight
                                                  channels:kInputRGBFeatureChannels];

    auto outputImage = [MPSImage pnk_float16ImageWithDevice:device width:kInputWidth
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

context(@"conditional instance normalization PNKUnaryKernel encoding", ^{
  __block NSBundle *bundle;

  beforeEach(^{
    bundle = NSBundle.lt_testBundle;
  });

  itShouldBehaveLike(kPNKParametricUnaryKernelExamples, ^{
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

    auto inputMatOneRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_nonarray_input.tensor");
    auto inputMat = PNKConvertToMultichannelMatrix(inputMatOneRow, kInputHeight, kInputWidth,
                                                   inputChannels);

    auto expectedMatOneRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_nonarray_output.tensor");
    auto expectedMat = PNKConvertToMultichannelMatrix(expectedMatOneRow, kInputHeight, kInputWidth,
                                                      inputChannels);

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
      .scale = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_scale.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_shift.weights")
    };

    PNKConditionalInstanceNormLayer *kernel =
        [[PNKConditionalInstanceNormLayer alloc] initWithDevice:device
                                             normalizationModel:normalizationModel
                                                activationModel:activationModel];

    auto inputMatOneRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_input.tensor");
    auto inputMat = PNKConvertToMultichannelMatrix(inputMatOneRow, kInputHeight, kInputWidth,
                                                   inputChannels);

    auto expectedMatOneRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_output.tensor");
    auto expectedMat = PNKConvertToMultichannelMatrix(expectedMatOneRow, kInputHeight, kInputWidth,
                                                      inputChannels);

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
      .scale = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_relu_scale.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle, @"instanceNorm_relu_shift.weights")
    };

    PNKConditionalInstanceNormLayer *kernel =
        [[PNKConditionalInstanceNormLayer alloc] initWithDevice:device
                                             normalizationModel:normalizationModel
                                                activationModel:activationModel];

    auto inputMatOneRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_relu_input.tensor");
    auto inputMat = PNKConvertToMultichannelMatrix(inputMatOneRow, kInputHeight, kInputWidth,
                                                   inputChannels);

    auto expectedMatOneRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"instanceNorm_relu_output.tensor");
    auto expectedMat = PNKConvertToMultichannelMatrix(expectedMatOneRow, kInputHeight, kInputWidth,
                                                      inputChannels);

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

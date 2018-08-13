// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKBatchNormalizationLayer.h"

#import "PNKConvolutionTestUtils.h"
#import "PNKNeuralNetworkOperationsModel.h"

static cv::Mat PNKCalculateBatchNorm(const cv::Mat &inputMatrix, const cv::Mat &mean,
                                     const cv::Mat &variance, const cv::Mat &scale,
                                     const cv::Mat &shift, float epsilon,
                                     pnk::ActivationType activationType, const cv::Mat &alpha,
                                     const cv::Mat &beta) {
  int channels = inputMatrix.channels();
  int rows = inputMatrix.rows;
  int columns = inputMatrix.cols;

  cv::Mat correctedScale = scale / (variance + epsilon);
  cv::Mat correctedShift = shift - mean.mul(correctedScale);

  cv::Mat input = inputMatrix.reshape(1, rows * columns);
  cv::Mat1hf output = cv::Mat1hf::zeros(rows * columns, channels);

  for (int outputChannel = 0; outputChannel < channels; ++outputChannel) {
    half_float::half scaleParameter = (half_float::half)correctedScale.at<float>(outputChannel);
    half_float::half shiftParameter = (half_float::half)correctedShift.at<float>(outputChannel);

    for (int pixel = 0; pixel < rows * columns; ++pixel) {
      half_float::half outputValue =
          scaleParameter * input.at<half_float::half>(pixel, outputChannel) + shiftParameter;

      half_float::half activatedValue = PNKActivatedValue(outputValue, outputChannel,
                                                          activationType, alpha, beta);
      output.at<half_float::half>(pixel, outputChannel) = activatedValue;
    }
  }

  cv::Mat outputMat = output.reshape(channels, rows);
  return outputMat;
}

static pnk::NormalizationKernelModel PNKBuildNormalizationModel(NSUInteger featureChannels) {
  cv::Mat1f scale(1, (int)featureChannels);
  cv::Mat1f shift(1, (int)featureChannels);
  cv::Mat1f mean(1, (int)featureChannels);
  cv::Mat1f variance(1, (int)featureChannels);

  cv::randu(scale, 0.5, 2);
  cv::randu(shift, -1, 1);
  cv::randu(mean, -1, 1);
  cv::randu(variance, 0.5, 2);

  return {
    .inputFeatureChannels = featureChannels,
    .computeMeanVar = NO,
    .scale = scale,
    .shift = shift,
    .mean = mean,
    .variance = variance,
    .epsilon = 0.1
  };
};

static NSDictionary *PNKBuildHalfFloatDataForKernelExamples(id<MTLDevice> device,
                                                            NSUInteger imageWidth,
                                                            NSUInteger imageHeight,
                                                            NSUInteger featureChannels,
                                                            pnk::ActivationType activationType) {
  auto normalizationModel = PNKBuildNormalizationModel(featureChannels);
  auto activationModel = PNKBuildActivationModel(featureChannels, activationType);

  auto batchNormOp = [[PNKBatchNormalizationLayer alloc] initWithDevice:device
                                                     normalizationModel:normalizationModel
                                                        activationModel:activationModel];

  auto inputMat = PNKFillMatrix((int)imageHeight, (int)imageWidth, (int)featureChannels);

  auto expectedMat = PNKCalculateBatchNorm(inputMat, normalizationModel.mean,
                                           normalizationModel.variance, normalizationModel.scale,
                                           normalizationModel.shift, normalizationModel.epsilon,
                                           activationModel.activationType, activationModel.alpha,
                                           activationModel.beta);

  return @{
    kPNKKernelExamplesKernel: batchNormOp,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
    kPNKKernelExamplesOutputChannels: @(featureChannels),
    kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
    kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
    kPNKKernelExamplesPrimaryInputMat: $(inputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat)
  };
}

DeviceSpecBegin(PNKBatchNormalizationLayer)

static const NSUInteger kFeatureChannels = 3;

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
});

context(@"parameter tests", ^{
  __block pnk::NormalizationKernelModel normalizationModel;
  __block pnk::ActivationKernelModel activationModel;

  beforeEach(^{
    normalizationModel = PNKBuildNormalizationModel(kFeatureChannels);
    activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };
  });

  context(@"instantiation", ^{
    __block PNKBatchNormalizationLayer *batchNormKernel;

    it(@"should instantiate correctly with correct parameters", ^{
      expect(^{
        batchNormKernel = [[PNKBatchNormalizationLayer alloc] initWithDevice:device
                                                          normalizationModel:normalizationModel
                                                             activationModel:activationModel];
      }).notTo.raiseAny();
    });
  });

  context(@"encodeToCommandBuffer", ^{
    static const NSUInteger kInputWidth = 32;
    static const NSUInteger kInputHeight = 32;

    __block PNKBatchNormalizationLayer *batchNormKernel;
    __block id<MTLCommandBuffer> commandBuffer;

    beforeEach(^{
      batchNormKernel = [[PNKBatchNormalizationLayer alloc] initWithDevice:device
                                                        normalizationModel:normalizationModel
                                                           activationModel:activationModel];
      auto commandQueue = [device newCommandQueue];
      commandBuffer = [commandQueue commandBuffer];
    });

    afterEach(^{
      batchNormKernel = nil;
      commandBuffer = nil;
    });

    it(@"should not raise when called with correct parameters", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, kFeatureChannels};
      MTLSize outputSize{kInputWidth, kInputHeight, kFeatureChannels};

      auto inputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                        size:inputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                         size:outputSize];
      expect(^{
        [batchNormKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                   outputImage:outputImage];
      }).notTo.raiseAny();
    });

    it(@"should raise when input image size does not fit output image size", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, kFeatureChannels};
      MTLSize outputSize{kInputWidth + 1, kInputHeight, kFeatureChannels};

      auto inputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                        size:inputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                         size:outputSize];
      expect(^{
        [batchNormKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                   outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input image has wrong number of channels", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, kFeatureChannels + 1};
      MTLSize outputSize{kInputWidth, kInputHeight, kFeatureChannels};

      auto inputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                        size:inputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                         size:outputSize];
      expect(^{
        [batchNormKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                   outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when output image has wrong number of channels", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, kFeatureChannels};
      MTLSize outputSize{kInputWidth, kInputHeight, kFeatureChannels + 1};

      auto inputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                        size:inputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device
                                                         size:outputSize];
      expect(^{
        [batchNormKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                   outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"kernel input region", ^{
  static const NSUInteger kInputWidth = 32;
  static const NSUInteger kInputHeight = 32;

  __block PNKBatchNormalizationLayer *batchNormKernel;

  beforeEach(^{
    pnk::NormalizationKernelModel normalizationModel = PNKBuildNormalizationModel(kFeatureChannels);
    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };
    batchNormKernel = [[PNKBatchNormalizationLayer alloc] initWithDevice:device
                                                      normalizationModel:normalizationModel
                                                         activationModel:activationModel];
  });

  afterEach(^{
    batchNormKernel = nil;
  });

  it(@"should calculate input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, kFeatureChannels};
    MTLRegion inputRegion = [batchNormKernel inputRegionForOutputSize:outputSize];
    expect($(inputRegion.size)).to.equalMTLSize($(outputSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kFeatureChannels};
    MTLSize outputSize = [batchNormKernel outputSizeForInputSize:inputSize];
    expect($(inputSize)).to.equalMTLSize($(outputSize));
  });
});

context(@"batch normalization", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, pnk::ActivationTypeIdentity);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 12, pnk::ActivationTypeIdentity);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 64, 32, 3, pnk::ActivationTypeIdentity);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 31, 33, 3, pnk::ActivationTypeIdentity);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 9, pnk::ActivationTypeIdentity);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, pnk::ActivationTypeAbsolute);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, pnk::ActivationTypeReLU);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, pnk::ActivationTypeLeakyReLU);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, pnk::ActivationTypeTanh);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, pnk::ActivationTypeScaledTanh);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, pnk::ActivationTypeSigmoid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4,
                                                  pnk::ActivationTypeSigmoidHard);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, pnk::ActivationTypeLinear);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, pnk::ActivationTypePReLU);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, pnk::ActivationTypeELU);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, pnk::ActivationTypeSoftsign);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4, pnk::ActivationTypeSoftplus);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 4,
                                                  pnk::ActivationTypeParametricSoftplus);
  });
});

context(@"tensorflow golden standard", ^{
  static const NSUInteger kInputChannels = 32;

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    pnk::ActivationKernelModel activationModel = {
      .activationType = pnk::ActivationTypeIdentity
    };

    NSBundle *bundle = NSBundle.lt_testBundle;

    pnk::NormalizationKernelModel normalizationModel = {
      .inputFeatureChannels = kInputChannels,
      .computeMeanVar = NO,
      .scale = PNKLoadFloatTensorFromBundleResource(bundle,
                                                    @"batch_normalization_gamma_32.weights"),
      .shift = PNKLoadFloatTensorFromBundleResource(bundle, @"batch_normalization_beta_32.weights"),
      .mean = cv::Mat1f::zeros(1, kInputChannels),
      .variance = cv::Mat1f::ones(1, kInputChannels)
    };

    auto batchNormOp = [[PNKBatchNormalizationLayer alloc] initWithDevice:device
                                                       normalizationModel:normalizationModel
                                                          activationModel:activationModel];
    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"batch_normalization_input_15x16x32.tensor");

    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"batch_normalization_output_15x16x32.tensor");

    return @{
      kPNKKernelExamplesKernel: batchNormOp,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(kInputChannels),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });
});

context(@"PNKTemporaryImageExamples", ^{
  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    auto normalizationModel = PNKBuildNormalizationModel(kFeatureChannels);
    auto activationModel = pnk::ActivationKernelModel{
      .activationType = pnk::ActivationTypeIdentity
    };

    auto batchNormKernel = [[PNKBatchNormalizationLayer alloc] initWithDevice:device
                                                           normalizationModel:normalizationModel
                                                              activationModel:activationModel];
    return @{
      kPNKTemporaryImageExamplesKernel: batchNormKernel,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @(normalizationModel.inputFeatureChannels)
    };
  });
});

DeviceSpecEnd

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKUpsampling.h"

#import <LTEngine/LTOpenCVExtensions.h>

/// Performs 2x bilinear upsampling with non-aligned corners. Produces same results as
/// <tt>tf.image.resize_images(method=ResizeMethod.BILINEAR, align_corners=False)</tt>. See
/// https://www.tensorflow.org/api_docs/python/tf/image/resize_images for more details.
cv::Mat PNKBilinearUpsampling(const cv::Mat &inputMatrix) {
  int inputRows = inputMatrix.rows;
  int inputColumns = inputMatrix.cols;
  int channels = inputMatrix.channels();
  int outputRows = inputRows * 2;
  int outputColumns = inputColumns * 2;

  cv::Mat1hf input = inputMatrix.reshape(1, inputRows * inputColumns);
  cv::Mat1hf output = cv::Mat1hf::zeros(outputRows * outputColumns, channels);

  for (int outputRow = 0; outputRow < outputRows; ++outputRow) {
    for (int outputColumn = 0; outputColumn < outputColumns; ++outputColumn) {
      int inputRow0 = outputRow / 2;
      int inputRow1 = std::min((outputRow + 1) / 2, inputRows - 1);
      int inputColumn0 = outputColumn / 2;
      int inputColumn1 = std::min((outputColumn + 1) / 2, inputColumns - 1);

      for (int channel = 0; channel < channels; ++channel) {
        output.at<half_float::half>(outputRow * outputColumns + outputColumn, channel) = 0.25 * (
            input(inputRow0 * inputColumns + inputColumn0, channel) +
            input(inputRow0 * inputColumns + inputColumn1, channel) +
            input(inputRow1 * inputColumns + inputColumn0, channel) +
            input(inputRow1 * inputColumns + inputColumn1, channel));
      }
    }
  }

  cv::Mat outputMat = output.reshape(channels, outputRows);
  return outputMat;
}

/// Performs 2x bilinear upsampling with aligned corners. Produces same results as
/// <tt>tf.image.resize_images(method=ResizeMethod.BILINEAR, align_corners=True)</tt>. See
/// https://www.tensorflow.org/api_docs/python/tf/image/resize_images for more details.
cv::Mat PNKBilinearAlignedUpsampling(const cv::Mat &inputMatrix) {
  int inputRows = inputMatrix.rows;
  int inputColumns = inputMatrix.cols;
  int channels = inputMatrix.channels();
  int outputRows = inputRows * 2;
  int outputColumns = inputColumns * 2;

  cv::Mat1hf input = inputMatrix.reshape(1, inputRows * inputColumns);
  cv::Mat1hf output = cv::Mat1hf::zeros(outputRows * outputColumns, channels);

  float inputToOutputWidthRatio = (float)(inputColumns - 1) / (float)(outputColumns - 1);
  float inputToOutputHeightRatio = (float)(inputRows - 1) / (float)(outputRows - 1);

  for (int outputRow = 0; outputRow < outputRows; ++outputRow) {
    for (int outputColumn = 0; outputColumn < outputColumns; ++outputColumn) {
      float inputX = outputColumn * inputToOutputWidthRatio;
      float inputY = outputRow * inputToOutputHeightRatio;
      int inputRow0 = (int)inputY;
      int inputRow1 = std::min(inputRow0 + 1, inputRows - 1);
      int inputColumn0 = (int)inputX;
      int inputColumn1 = std::min((outputColumn + 1) / 2, inputColumns - 1);

      half_float::half coeffX = (half_float::half)(inputX - inputColumn0);
      half_float::half coeffY = (half_float::half)(inputY - inputRow0);

      for (int channel = 0; channel < channels; ++channel) {
        output.at<half_float::half>(outputRow * outputColumns + outputColumn, channel) =
            (1 - coeffX) * (1 - coeffY) * input(inputRow0 * inputColumns + inputColumn0, channel) +
            coeffX * (1 - coeffY) * input(inputRow0 * inputColumns + inputColumn1, channel) +
            (1 - coeffX) * coeffY * input(inputRow1 * inputColumns + inputColumn0, channel) +
            coeffX * coeffY * input(inputRow1 * inputColumns + inputColumn1, channel);
      }
    }
  }

  cv::Mat outputMat = output.reshape(channels, outputRows);
  return outputMat;
}

/// Build test data for \c kPNKUnaryKernelExamples with given parameters.
static NSDictionary *PNKBuildDataForExamples(id<MTLDevice> device, PNKUpsamplingType upsamplingType,
                                             NSUInteger imageWidth, NSUInteger imageHeight,
                                             NSUInteger featureChannels) {
  auto upsamplingKernel = [[PNKUpsampling alloc] initWithDevice:device
                                                 upsamplingType:upsamplingType];

  auto inputMat = PNKFillMatrix((int)imageHeight, (int)imageWidth, (int)featureChannels);

  cv::Mat expectedMat;

  switch (upsamplingType) {
    case PNKUpsamplingTypeNearestNeighbor:
      cv::resize(inputMat, expectedMat, cv::Size(0, 0), 2, 2, cv::INTER_NEAREST);
      break;
    case PNKUpsamplingTypeBilinear:
      expectedMat = PNKBilinearUpsampling(inputMat);
      break;
    case PNKUpsamplingTypeBilinearAligned:
      expectedMat = PNKBilinearAlignedUpsampling(inputMat);
      break;
  }
  return @{
    kPNKKernelExamplesKernel: upsamplingKernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
    kPNKKernelExamplesOutputChannels: @(featureChannels),
    kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
    kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
    kPNKKernelExamplesPrimaryInputMat: $(inputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat)
  };
}

DeviceSpecBegin(PNKUpsampling)

static const NSUInteger kInputWidth = 4;
static const NSUInteger kInputHeight = 4;
static const NSUInteger kInputFeatureChannels = 4;
static const NSUInteger kInputArrayFeatureChannels = 12;

static const NSUInteger kOutputWidth = kInputWidth * 2;
static const NSUInteger kOutputHeight = kInputHeight * 2;

__block id<MTLDevice> device;
__block PNKUpsampling *nearestNeighborUpsampler;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  nearestNeighborUpsampler = [[PNKUpsampling alloc] initWithDevice:device
                              upsamplingType:PNKUpsamplingTypeNearestNeighbor];
});

afterEach(^{
  device = nil;
  nearestNeighborUpsampler = nil;
});

context(@"kernel input verification", ^{
  __block id<MTLCommandBuffer> commandBuffer;

  beforeEach(^{
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];
  });

  afterEach(^{
    commandBuffer = nil;
  });

  it(@"should raise an exception when input and output array length mismatch", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth, kOutputHeight,
                                         kInputArrayFeatureChannels);
    expect(^{
      [nearestNeighborUpsampler encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                          outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when output width is incorrect", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth * 2, kOutputHeight,
                                         kInputFeatureChannels);
    expect(^{
      [nearestNeighborUpsampler encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                          outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when output height is incorrect", ^{
    auto inputImage = PNKImageMakeUnorm(device, kInputWidth, kInputHeight, kInputFeatureChannels);
    auto outputImage = PNKImageMakeUnorm(device, kOutputWidth, kOutputHeight * 2,
                                         kInputFeatureChannels);
    expect(^{
      [nearestNeighborUpsampler encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                          outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"kernel output size", ^{
  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kInputFeatureChannels};
    MTLSize expectedOutputSize = {kOutputWidth, kOutputHeight, kInputFeatureChannels};
    MTLSize outputSize = [nearestNeighborUpsampler outputSizeForInputSize:inputSize];

    expect($(outputSize)).to.equalMTLSize($(expectedOutputSize));
  });

  it(@"should calculate input region correctly", ^{
    MTLSize outputSize = {kOutputWidth, kOutputHeight, kInputFeatureChannels};
    MTLSize expectedInputSize = {kInputWidth, kInputHeight, kInputFeatureChannels};
    MTLSize inputSize = [nearestNeighborUpsampler inputRegionForOutputSize:outputSize].size;

    expect($(inputSize)).to.equalMTLSize($(expectedInputSize));
  });
});

context(@"upsampling correctness", ^{
  for (ushort upsamplingType = PNKUpsamplingTypeNearestNeighbor;
       upsamplingType <= PNKUpsamplingTypeBilinearAligned; ++upsamplingType) {
    for (NSUInteger imageWidth = 4; imageWidth <= 5; ++imageWidth) {
      for (NSUInteger imageHeight = 4; imageHeight <= 5; ++imageHeight) {
        for (NSUInteger featureChannels = 4; featureChannels <= 8; featureChannels += 4) {
          itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
            return PNKBuildDataForExamples(device, (PNKUpsamplingType)upsamplingType, imageWidth,
                                           imageHeight, featureChannels);
          });
        }
      }
    }
  }
});

context(@"tensorflow golden standard", ^{
  static const NSUInteger kGoldenStandardFeatureChannels = 32;

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    NSBundle *bundle = NSBundle.lt_testBundle;

    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"upsample_nearest_neighbor_input_15x16x32.tensor");

    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"upsample_nearest_neighbor_output_30x32x32.tensor");

    return @{
      kPNKKernelExamplesKernel: nearestNeighborUpsampler,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(kGoldenStandardFeatureChannels),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    __block PNKUpsampling *bilinearUpsampler = [[PNKUpsampling alloc] initWithDevice:device
                                                upsamplingType:PNKUpsamplingTypeBilinear];

    NSBundle *bundle = NSBundle.lt_testBundle;

    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"upsample_bilinear_input_15x16x32.tensor");

    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"upsample_bilinear_output_30x32x32.tensor");

    return @{
      kPNKKernelExamplesKernel: bilinearUpsampler,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(kGoldenStandardFeatureChannels),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    __block PNKUpsampling *bilinearAlignedUpsampler =
        [[PNKUpsampling alloc] initWithDevice:device
                               upsamplingType:PNKUpsamplingTypeBilinearAligned];

    NSBundle *bundle = NSBundle.lt_testBundle;

    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"upsample_bilinear_aligned_input_15x16x32.tensor");

    auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
        @"upsample_bilinear_aligned_output_30x32x32.tensor");

    return @{
      kPNKKernelExamplesKernel: bilinearAlignedUpsampler,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(1),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });
});

DeviceSpecEnd

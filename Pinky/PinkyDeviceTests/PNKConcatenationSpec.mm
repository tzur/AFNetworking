// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKConcatenation.h"

static const NSUInteger kInputWidth = 5;
static const NSUInteger kInputHeight = 5;
static const cv::Vec4b kInputPrimaryValue(1, 2, 3, 4);
static const cv::Vec4b kInputSecondaryValue(5, 6, 7, 8);

static cv::Mat PNKGenerateInputMatrix(int channels, cv::Vec4b value) {
  int alignedChannels = ((channels + 3) / 4) * 4;
  cv::Mat matrix = cv::Mat1b(kInputWidth * kInputHeight, alignedChannels);

  for (int i = 0; i < matrix.rows; i++) {
    for (int j = 0; j < channels; j++) {
      matrix.at<uchar>(i, j) = value[j % 4];
    }
    for (int j = channels; j < alignedChannels; j++) {
      matrix.at<uchar>(i, j) = 0;
    }
  }

  return matrix.reshape(alignedChannels, kInputHeight);
}

static cv::Mat PNKGenerateOutputMatrix(int primaryChannels, cv::Vec4b primaryValue,
                                       int secondaryChannels, cv::Vec4b secondaryValue) {
  int outputChannels = primaryChannels + secondaryChannels;
  int alignedOutputChannels = ((outputChannels + 3) / 4) * 4;
  cv::Mat matrix = cv::Mat1b(kInputWidth * kInputHeight, alignedOutputChannels);

  for (int i = 0; i < matrix.rows; i++) {
    for (int j = 0; j < primaryChannels; j++) {
      matrix.at<uchar>(i, j) = primaryValue[j % 4];
    }
    for (int j = primaryChannels; j < outputChannels; j++) {
      matrix.at<uchar>(i, j) = secondaryValue[(j - primaryChannels) % 4];
    }
    for (int j = outputChannels; j < alignedOutputChannels; j++) {
      matrix.at<uchar>(i, j) = 0;
    }
  }

  return matrix.reshape(alignedOutputChannels, kInputHeight);
}

static NSDictionary *PNKBuildUnormDataForKernelExamples(id<MTLDevice> device,
                                                        NSUInteger primaryChannels,
                                                        NSUInteger secondaryChannels) {
  auto kernel = [[PNKConcatenation alloc] initWithDevice:device
                             primaryInputFeatureChannels:primaryChannels
                           secondaryInputFeatureChannels:secondaryChannels];

  cv::Mat primaryInputMat = PNKGenerateInputMatrix((int)primaryChannels, kInputPrimaryValue);
  cv::Mat secondaryInputMat = PNKGenerateInputMatrix((int)secondaryChannels, kInputSecondaryValue);
  cv::Mat expectedMat = PNKGenerateOutputMatrix((int)primaryChannels, kInputPrimaryValue,
                                                (int)secondaryChannels, kInputSecondaryValue);
  return @{
    kPNKKernelExamplesKernel: kernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatUnorm8),
    kPNKKernelExamplesPrimaryInputChannels: @(primaryChannels),
    kPNKKernelExamplesSecondaryInputChannels: @(secondaryChannels),
    kPNKKernelExamplesOutputChannels: @(primaryChannels + secondaryChannels),
    kPNKKernelExamplesOutputWidth: @(kInputWidth),
    kPNKKernelExamplesOutputHeight: @(kInputHeight),
    kPNKKernelExamplesPrimaryInputMat: $(primaryInputMat),
    kPNKKernelExamplesSecondaryInputMat: $(secondaryInputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat)
  };
}

static NSDictionary *PNKBuildHalfFloatDataForKernelExamples(id<MTLDevice> device,
                                                            NSUInteger primaryChannels,
                                                            NSUInteger secondaryChannels) {
  auto kernel = [[PNKConcatenation alloc] initWithDevice:device
                             primaryInputFeatureChannels:primaryChannels
                           secondaryInputFeatureChannels:secondaryChannels];

  cv::Mat primaryInputMat = PNKGenerateInputMatrix((int)primaryChannels, kInputPrimaryValue);
  primaryInputMat.convertTo(primaryInputMat, CV_16F);

  cv::Mat secondaryInputMat = PNKGenerateInputMatrix((int)secondaryChannels, kInputSecondaryValue);
  secondaryInputMat.convertTo(secondaryInputMat, CV_16F);

  cv::Mat expectedMat = PNKGenerateOutputMatrix((int)primaryChannels, kInputPrimaryValue,
                                                (int)secondaryChannels, kInputSecondaryValue);
  expectedMat.convertTo(expectedMat, CV_16F);

  return @{
    kPNKKernelExamplesKernel: kernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
    kPNKKernelExamplesPrimaryInputChannels: @(primaryChannels),
    kPNKKernelExamplesSecondaryInputChannels: @(secondaryChannels),
    kPNKKernelExamplesOutputChannels: @(primaryChannels + secondaryChannels),
    kPNKKernelExamplesOutputWidth: @(kInputWidth),
    kPNKKernelExamplesOutputHeight: @(kInputHeight),
    kPNKKernelExamplesPrimaryInputMat: $(primaryInputMat),
    kPNKKernelExamplesSecondaryInputMat: $(secondaryInputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat)
  };
}

SpecBegin(PNKConcatenation)

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

context(@"concatenation operation with Unorm8 channel format", ^{
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 1, 1);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 2, 2);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 3, 3);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 3, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 4, 3);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 4, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 5, 2);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 5, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 5, 5);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 5, 8);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 8, 5);
  });
});

context(@"concatenation operation with Float16 channel format", ^{
  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 2, 2);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 2, 2);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 3, 3);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 3, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 4, 3);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 4, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 5, 2);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 5, 4);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 5, 5);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 5, 8);
  });

  itShouldBehaveLike(kPNKBinaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 8, 5);
  });
});

context(@"concatenation operation with Unorm8 channel format with PNKBinaryImageKernel protocol", ^{
  itShouldBehaveLike(kPNKBinaryImageKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 2, 2);
  });

  itShouldBehaveLike(kPNKBinaryImageKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 3, 3);
  });

  itShouldBehaveLike(kPNKBinaryImageKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 3, 4);
  });

  itShouldBehaveLike(kPNKBinaryImageKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 4, 3);
  });

  itShouldBehaveLike(kPNKBinaryImageKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 4, 4);
  });

  itShouldBehaveLike(kPNKBinaryImageKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 5, 2);
  });

  itShouldBehaveLike(kPNKBinaryImageKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 5, 4);
  });

  itShouldBehaveLike(kPNKBinaryImageKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 5, 5);
  });

  itShouldBehaveLike(kPNKBinaryImageKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 5, 8);
  });

  itShouldBehaveLike(kPNKBinaryImageKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 8, 5);
  });
});

context(@"PNKTemporaryImageExamples", ^{
  itShouldBehaveLike(kPNKTemporaryImageBinaryExamples, ^{
    auto concatenationOp = [[PNKConcatenation alloc] initWithDevice:device
                                        primaryInputFeatureChannels:1
                                      secondaryInputFeatureChannels:1];
    return @{
      kPNKTemporaryImageExamplesKernel: concatenationOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesOutputChannels: @(2)
    };
  });

  itShouldBehaveLike(kPNKTemporaryImageBinaryExamples, ^{
    auto concatenationOp = [[PNKConcatenation alloc] initWithDevice:device
                                        primaryInputFeatureChannels:8
                                      secondaryInputFeatureChannels:8];
    return @{
      kPNKTemporaryImageExamplesKernel: concatenationOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesOutputChannels: @(16)
    };
  });
});

SpecEnd

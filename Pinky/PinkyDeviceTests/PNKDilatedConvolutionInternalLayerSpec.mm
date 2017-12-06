// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKDilatedConvolutionInternalLayer.h"

#import "PNKNeuralNetworkOperationsModel.h"

static cv::Mat PNKFillKernel(int kernelWidth, int kernelHeight, int inputChannels,
                             int outputChannels) {
  int dims[] = {outputChannels, kernelHeight, kernelWidth, inputChannels};
  cv::Mat1f kernel(4, dims);

  for (int i = 0; i < outputChannels; ++i) {
    for (int j = 0; j < kernelHeight; ++j) {
      for (int k = 0; k < kernelWidth; ++k) {
        for (int m = 0; m < inputChannels; ++m) {
          int index[] = {i, j, k, m};
          kernel.at<float>(index) = (i + j + k + m) % 5 - 2;
        }
      }
    }
  }

   return kernel;
}

static cv::Mat PNKCalculateConvolution(cv::Mat inputMatrix, cv::Mat kernel, int dilationX,
                                       int dilationY) {
  LTAssert(kernel.dims == 4);
  cv::MatSize kernelSize = kernel.size;

  int outputChannels = kernelSize[0];
  int kernelHeight = kernelSize[1];
  int kernelWidth = kernelSize[2];
  int inputChannels = kernelSize[3];
  LTAssert(inputChannels == inputMatrix.channels());

  int rows = inputMatrix.rows;
  int columns = inputMatrix.cols;

  cv::Mat input = inputMatrix.reshape(1, rows * columns);
  cv::Mat1hf output = cv::Mat1hf::zeros(rows * columns, outputChannels);

  for (int outputChannel = 0; outputChannel < outputChannels; ++outputChannel) {
    for (int kernelY = 0; kernelY < kernelHeight; ++kernelY) {
      for (int kernelX = 0; kernelX < kernelWidth; ++kernelX) {
        for (int inputChannel = 0; inputChannel < inputChannels; ++inputChannel) {
          int indexInKernel[] = {outputChannel, kernelY, kernelX, inputChannel};
          float weight = (float)kernel.at<float>(indexInKernel);

          for (int outputRow = 0; outputRow < rows; ++outputRow) {
            for (int outputColumn = 0; outputColumn < columns; ++outputColumn) {
              int inputRow = outputRow - (kernelHeight / 2 - kernelY) * dilationY;
              int inputColumn = outputColumn - (kernelWidth / 2 - kernelX) * dilationX;
              if (inputRow < 0 || inputRow >= rows || inputColumn < 0 || inputColumn >= columns) {
                continue;
              }

              output.at<half_float::half>(outputRow * columns + outputColumn, outputChannel) +=
                  weight * input.at<half_float::half>(inputRow * columns + inputColumn,
                                                      inputChannel);
            }
          }
        }
      }
    }
  }

  cv::Mat outputMat = output.reshape(outputChannels, rows);
  return outputMat;
}

static pnk::ConvolutionKernelModel PNKBuildConvolutionModel(NSUInteger kernelWidth,
                                                            NSUInteger kernelHeight,
                                                            NSUInteger inputChannels,
                                                            NSUInteger outputChannels,
                                                            NSUInteger dilationX,
                                                            NSUInteger dilationY,
                                                            pnk::PaddingType paddingType) {
  cv::Mat kernelWeights = PNKFillKernel((int)kernelWidth, (int)kernelHeight, (int)inputChannels,
                                        (int)outputChannels);

  return {
    .kernelWidth = kernelWidth,
    .kernelHeight = kernelHeight,
    .kernelChannels = inputChannels,
    .groups = 1,
    .inputFeatureChannels = inputChannels,
    .outputFeatureChannels = outputChannels,
    .strideX = 1,
    .strideY = 1,
    .dilationX = dilationX,
    .dilationY = dilationY,
    .padding = paddingType,
    .isDeconvolution = NO,
    .hasBias = NO,
    .deconvolutionOutputSize = CGSizeNull,
    .kernelWeights = kernelWeights
  };
};

static NSDictionary *PNKBuildHalfFloatDataForKernelExamples(id<MTLDevice> device,
                                                            NSUInteger imageWidth,
                                                            NSUInteger imageHeight,
                                                            NSUInteger kernelWidth,
                                                            NSUInteger kernelHeight,
                                                            NSUInteger inputChannels,
                                                            NSUInteger outputChannels,
                                                            NSUInteger dilationX,
                                                            NSUInteger dilationY,
                                                            pnk::PaddingType paddingType) {
  auto convolutionModel = PNKBuildConvolutionModel(kernelWidth, kernelHeight, inputChannels,
                                                   outputChannels, dilationX, dilationY,
                                                   paddingType);

  auto convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                            initWithDevice:device convolutionModel:convolutionModel];

  auto inputMat = PNKFillMatrix((int)imageHeight, (int)imageWidth, (int)inputChannels);

  auto expectedMat = PNKCalculateConvolution(inputMat, convolutionModel.kernelWeights,
                                             (int)dilationX, (int)dilationY);

  if (paddingType == pnk::PaddingTypeValid) {
    cv::Rect roi((int)(dilationX * (kernelWidth / 2)), (int)(dilationY * (kernelHeight / 2)),
                 (int)(expectedMat.cols - 2 * dilationX * (kernelWidth / 2)),
                 (int)(expectedMat.rows - 2 * dilationY * (kernelHeight / 2)));
    expectedMat = expectedMat(roi).clone();
  }

  return @{
    kPNKKernelExamplesKernel: convolutionKernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
    kPNKKernelExamplesOutputChannels: @(outputChannels),
    kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
    kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
    kPNKKernelExamplesPrimaryInputMat: $(inputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat)
  };
}

DeviceSpecBegin(PNKDilatedConvolutionInternalLayer)

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

context(@"parameter tests", ^{
  __block pnk::ConvolutionKernelModel convolutionKernelModel;

  beforeEach(^{
    convolutionKernelModel = PNKBuildConvolutionModel(3, 3, 1, 1, 2, 2, pnk::PaddingTypeSame);
  });

  context(@"instantiation", ^{
    __block PNKDilatedConvolutionInternalLayer *convolutionKernel;

    it(@"should instantiate correctly with correct parameters", ^{
      expect(^{
        convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                             initWithDevice:device
                             convolutionModel:convolutionKernelModel];
      }).notTo.raiseAny();
    });

    it(@"should raise when strideX is not one", ^{
      convolutionKernelModel.strideX = 2;
      expect(^{
        convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                             initWithDevice:device
                             convolutionModel:convolutionKernelModel];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when strideY is not one", ^{
      convolutionKernelModel.strideY = 3;
      expect(^{
        convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                             initWithDevice:device
                             convolutionModel:convolutionKernelModel];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when groups is not one", ^{
      convolutionKernelModel.groups = 4;
      expect(^{
        convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                             initWithDevice:device
                             convolutionModel:convolutionKernelModel];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when kernel width is even", ^{
      convolutionKernelModel.kernelWidth = 4;
      convolutionKernelModel.kernelWeights = cv::Mat1f::ones(3, 4);
      expect(^{
        convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                             initWithDevice:device
                             convolutionModel:convolutionKernelModel];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when kernel height is even", ^{
      convolutionKernelModel.kernelHeight = 6;
      convolutionKernelModel.kernelWeights = cv::Mat1f::ones(6, 3);
      expect(^{
        convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                             initWithDevice:device
                             convolutionModel:convolutionKernelModel];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when given invalid padding type", ^{
      convolutionKernelModel.padding = (pnk::PaddingType)10;
      expect(^{
        convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                             initWithDevice:device
                             convolutionModel:convolutionKernelModel];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"encodeToCommandBuffer", ^{
    static const NSUInteger kInputWidth = 32;
    static const NSUInteger kInputHeight = 32;

    __block PNKDilatedConvolutionInternalLayer *convolutionKernel;
    __block id<MTLCommandQueue> commandQueue;
    __block id<MTLCommandBuffer> commandBuffer;

    beforeEach(^{
      device = MTLCreateSystemDefaultDevice();
      convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                           initWithDevice:device
                           convolutionModel:convolutionKernelModel];
      commandQueue = [device newCommandQueue];
      commandBuffer = [commandQueue commandBuffer];
    });

    it(@"should not raise when called with correct parameters", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, 1};
      MTLSize outputSize{kInputWidth, kInputHeight, 1};

      auto inputImage = [MPSImage pnk_imageWithDevice:device
                                               format:MPSImageFeatureChannelFormatFloat16
                                                 size:inputSize];
      auto outputImage = [MPSImage pnk_imageWithDevice:device
                                                format:MPSImageFeatureChannelFormatFloat16
                                                  size:outputSize];
      expect(^{
        [convolutionKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                     outputImage:outputImage];
      }).notTo.raiseAny();
    });

    it(@"should raise when input image size does not fit output image size", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, 1};
      MTLSize outputSize{kInputWidth + 1, kInputHeight, 1};

      auto inputImage = [MPSImage pnk_imageWithDevice:device
                                               format:MPSImageFeatureChannelFormatFloat16
                                                 size:inputSize];
      auto outputImage = [MPSImage pnk_imageWithDevice:device
                                                format:MPSImageFeatureChannelFormatFloat16
                                                  size:outputSize];
      expect(^{
        [convolutionKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                     outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input image has wrong number of channels", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, 2};
      MTLSize outputSize{kInputWidth, kInputHeight, 1};

      auto inputImage = [MPSImage pnk_imageWithDevice:device
                                               format:MPSImageFeatureChannelFormatFloat16
                                                 size:inputSize];
      auto outputImage = [MPSImage pnk_imageWithDevice:device
                                                format:MPSImageFeatureChannelFormatFloat16
                                                  size:outputSize];
      expect(^{
        [convolutionKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                     outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when output image has wrong number of channels", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, 1};
      MTLSize outputSize{kInputWidth, kInputHeight, 2};

      auto inputImage = [MPSImage pnk_imageWithDevice:device
                                               format:MPSImageFeatureChannelFormatFloat16
                                                 size:inputSize];
      auto outputImage = [MPSImage pnk_imageWithDevice:device
                                                format:MPSImageFeatureChannelFormatFloat16
                                                  size:outputSize];
      expect(^{
        [convolutionKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                     outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"dilated convolution", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 2, 2,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 64, 32, 3, 3, 1, 1, 2, 2,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 31, 33, 3, 3, 1, 1, 2, 2,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 3, 3,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 2, 2, 4, 1,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 3, 3, 8, 8,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 3, 5, 4, 4,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 8, 8, 4, 4,
                                                  pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 2, 2,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 5, 1, 1, 2, 2,
                                                  pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 4, 2,
                                                  pnk::PaddingTypeValid);
  });
});

context(@"PNKTemporaryImageExamples", ^{
  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    pnk::ConvolutionKernelModel convolutionKernelModel =
        PNKBuildConvolutionModel(3, 3, 1, 1, 2, 2, pnk::PaddingTypeSame);

    auto convolutionKernel = [[PNKDilatedConvolutionInternalLayer alloc]
                              initWithDevice:device
                              convolutionModel:convolutionKernelModel];
    return @{
      kPNKTemporaryImageExamplesKernel: convolutionKernel,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesOutputChannels: @(convolutionKernelModel.outputFeatureChannels)
    };
  });
});

DeviceSpecEnd

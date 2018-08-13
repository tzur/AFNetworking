// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKPoolingLayer.h"

#import "PNKNeuralNetworkOperationsModel.h"

static cv::Mat PNKCalculatePooling(pnk::PoolingType pooling, pnk::PaddingType padding,
                                   cv::Mat inputMatrix, int kernelWidth,
                                   int kernelHeight, int strideX, int strideY) {
  int channels = inputMatrix.channels();
  int inputRows = inputMatrix.rows;
  int inputColumns = inputMatrix.cols;
  int outputRows, outputColumns;
  if (padding == pnk::PaddingTypeSame) {
    outputRows = (inputRows - 1) / strideY + 1;
    outputColumns = (inputColumns - 1) / strideX + 1;
  } else {
    outputRows = (inputRows - kernelHeight) / strideY + 1;
    outputColumns = (inputColumns - kernelWidth) / strideX + 1;
  }

  cv::Mat input = inputMatrix.reshape(1, inputRows * inputColumns);
  cv::Mat1hf output = cv::Mat1hf::zeros(outputRows * outputColumns, channels);

  int paddingLeft, paddingTop;
  if (padding == pnk::PaddingTypeSame) {
    int strideResidualX = (inputColumns - 1) % strideX + 1;
    paddingLeft = std::max(kernelWidth - strideResidualX, 0) / 2;
    int strideResidualY = (inputRows - 1) % strideY + 1;
    paddingTop = std::max(kernelHeight - strideResidualY, 0) / 2;
  } else {
    paddingLeft = 0;
    paddingTop = 0;
  }

  for (int channel = 0; channel < channels; ++channel) {
    for (int outputRow = 0; outputRow < outputRows; ++outputRow) {
      for (int outputColumn = 0; outputColumn < outputColumns; ++outputColumn) {
        half_float::half sum = (half_float::half)0;
        half_float::half sumOfSquares = (half_float::half)0;
        int count = 0;
        half_float::half max = std::numeric_limits<half_float::half>::lowest();
        for (int kernelY = 0; kernelY < kernelHeight; ++kernelY) {
          for (int kernelX = 0; kernelX < kernelWidth; ++kernelX) {
            int inputRow = outputRow * strideY - paddingTop + kernelY;
            int inputColumn = outputColumn * strideX - paddingLeft + kernelX;
            if (inputRow < 0 || inputRow >= inputRows || inputColumn < 0 ||
                inputColumn >= inputColumns) {
              continue;
            }
            half_float::half pixel =
                input.at<half_float::half>(inputRow * inputColumns + inputColumn, channel);
            sum += pixel;
            sumOfSquares += pixel * pixel;
            max = std::max(max, pixel);
            ++count;
          }
        }

        half_float::half result;
        switch (pooling) {
          case pnk::PoolingTypeMax:
            result = max;
            break;
          case pnk::PoolingTypeAverage:
            result = sum / (half_float::half)count;
            break;
          case pnk::PoolingTypeL2:
            result = std::sqrt(sumOfSquares);
            break;
        }
        output.at<half_float::half>(outputRow * outputColumns + outputColumn, channel) = result;
      }
    }
  }

  cv::Mat outputMat = output.reshape(channels, outputRows);
  return outputMat;
}

static NSDictionary *PNKBuildHalfFloatDataForKernelExamples(id<MTLDevice> device,
                                                            NSUInteger inputWidth,
                                                            NSUInteger inputHeight,
                                                            NSUInteger kernelWidth,
                                                            NSUInteger kernelHeight,
                                                            NSUInteger channels,
                                                            NSUInteger strideX,
                                                            NSUInteger strideY,
                                                            pnk::PoolingType pooling,
                                                            pnk::PaddingType padding) {
  pnk::PoolingKernelModel poolingModel = {
    .pooling = pooling,
    .kernelWidth = kernelWidth,
    .kernelHeight = kernelHeight,
    .strideX = strideX,
    .strideY = strideY,
    .padding = padding,
    .averagePoolExcludePadding = YES,
    .globalPooling = NO
  };

  auto poolingKernel = [[PNKPoolingLayer alloc] initWithDevice:device poolingModel:poolingModel];

  auto inputMat = PNKFillMatrix((int)inputHeight, (int)inputWidth, (int)channels);

  cv::Mat expectedMat = PNKCalculatePooling(pooling, padding, inputMat, (int)kernelWidth,
                                            (int)kernelHeight, (int)strideX, (int)strideY);

  return @{
    kPNKKernelExamplesKernel: poolingKernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
    kPNKKernelExamplesOutputChannels: @(channels),
    kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
    kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
    kPNKKernelExamplesPrimaryInputMat: $(inputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat),
    kPNKKernelExamplesInputImageSizeFromInputMat: @(YES)
  };
}

static NSDictionary *PNKBuildDataForGoldenStandardExamples(id<MTLDevice> device,
                                                           NSString *inputName,
                                                           NSString *outputName,
                                                           NSUInteger kernelWidth,
                                                           NSUInteger kernelHeight,
                                                           NSUInteger strideX, NSUInteger strideY,
                                                           pnk::PoolingType pooling,
                                                           pnk::PaddingType padding) {
  pnk::PoolingKernelModel poolingModel = {
    .pooling = pooling,
    .kernelWidth = kernelWidth,
    .kernelHeight = kernelHeight,
    .strideX = strideX,
    .strideY = strideY,
    .padding = padding,
    .averagePoolExcludePadding = YES,
    .globalPooling = NO
  };

  auto poolingKernel = [[PNKPoolingLayer alloc] initWithDevice:device poolingModel:poolingModel];

  NSBundle *bundle = NSBundle.lt_testBundle;

  auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle, inputName);
  auto expectedMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle, outputName);

  return @{
    kPNKKernelExamplesKernel: poolingKernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
    kPNKKernelExamplesOutputChannels: @(expectedMat.channels()),
    kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
    kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
    kPNKKernelExamplesPrimaryInputMat: $(inputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat),
    kPNKKernelExamplesInputImageSizeFromInputMat: @(YES)
  };
}

DeviceSpecBegin(PNKPoolingLayer)

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
});

context(@"parameter checks", ^{
  __block pnk::PoolingKernelModel poolingModel;

  beforeEach(^{
    poolingModel = {
      .pooling = pnk::PoolingTypeAverage,
      .kernelWidth = 3,
      .kernelHeight = 3,
      .strideX = 1,
      .strideY = 1,
      .padding = pnk::PaddingTypeSame,
      .averagePoolExcludePadding = YES,
      .globalPooling = NO
    };
  });

  context(@"instantiation", ^{
    __block PNKPoolingLayer *poolingKernel;

    it(@"should instantiate correctly with default parameters", ^{
      expect(^{
        poolingKernel = [[PNKPoolingLayer alloc] initWithDevice:device poolingModel:poolingModel];
      }).notTo.raiseAny();
    });

    it(@"should raise when given invalid padding type", ^{
      poolingModel.padding = (pnk::PaddingType)10;
      expect(^{
        poolingKernel = [[PNKPoolingLayer alloc] initWithDevice:device poolingModel:poolingModel];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when given pooling type L2", ^{
      poolingModel.pooling = pnk::PoolingTypeL2;
      expect(^{
        poolingKernel = [[PNKPoolingLayer alloc] initWithDevice:device poolingModel:poolingModel];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when given invalid pooling type", ^{
      poolingModel.pooling = (pnk::PoolingType)10;
      expect(^{
        poolingKernel = [[PNKPoolingLayer alloc] initWithDevice:device poolingModel:poolingModel];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"encodeToCommandBuffer", ^{
    static const NSUInteger kInputWidth = 32;
    static const NSUInteger kInputHeight = 32;

    __block PNKPoolingLayer *poolingKernel;
    __block id<MTLCommandQueue> commandQueue;
    __block id<MTLCommandBuffer> commandBuffer;

    beforeEach(^{
      poolingKernel = [[PNKPoolingLayer alloc] initWithDevice:device poolingModel:poolingModel];
      commandQueue = [device newCommandQueue];
      commandBuffer = [commandQueue commandBuffer];
    });

    it(@"should not raise when called with default parameters", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, 1};
      MTLSize outputSize{kInputWidth, kInputHeight, 1};

      auto inputImage = PNKImageMakeAndClearHalf(device, inputSize);
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [poolingKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                 outputImage:outputImage];
      }).notTo.raiseAny();
    });

    it(@"should raise when input image size does not fit output image size", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, 1};
      MTLSize outputSize{kInputWidth + 1, kInputHeight, 1};

      auto inputImage = PNKImageMakeAndClearHalf(device, inputSize);
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [poolingKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                 outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input and output image have different number of channels", ^{
      MTLSize inputSize{kInputWidth, kInputHeight, 2};
      MTLSize outputSize{kInputWidth, kInputHeight, 1};

      auto inputImage = PNKImageMakeAndClearHalf(device, inputSize);
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [poolingKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                 outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"kernel input region", ^{
  static const NSUInteger kInputWidth = 32;
  static const NSUInteger kInputHeight = 32;
  static const NSUInteger kChannels = 15;
  static const NSUInteger kStrideX = 2;
  static const NSUInteger kStrideY = 2;

  __block PNKPoolingLayer *poolingKernel;

  beforeEach(^{
    pnk::PoolingKernelModel poolingModel = {
      .pooling = pnk::PoolingTypeAverage,
      .kernelWidth = 3,
      .kernelHeight = 3,
      .strideX = kStrideX,
      .strideY = kStrideY,
      .padding = pnk::PaddingTypeSame,
      .averagePoolExcludePadding = YES,
      .globalPooling = NO
    };

    poolingKernel = [[PNKPoolingLayer alloc] initWithDevice:device poolingModel:poolingModel];
  });

  afterEach(^{
    poolingKernel = nil;
  });

  it(@"should calculate input region correctly", ^{
    MTLSize outputSize = {kInputWidth, kInputHeight, kChannels};
    MTLRegion inputRegion = [poolingKernel inputRegionForOutputSize:outputSize];
    MTLSize expectedSize = {
      (outputSize.width - 1) * kStrideX + 1,
      (outputSize.height - 1) * kStrideY + 1,
      kChannels
    };

    expect($(inputRegion.size)).to.equalMTLSize($(expectedSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kInputWidth, kInputHeight, kChannels};
    MTLSize expectedSize = {
      (inputSize.width - 1) / kStrideX + 1,
      (inputSize.height - 1) / kStrideY + 1,
      kChannels
    };
    MTLSize outputSize = [poolingKernel outputSizeForInputSize:inputSize];

    expect($(outputSize)).to.equalMTLSize($(expectedSize));
  });
});

context(@"tensorflow golden standard", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildDataForGoldenStandardExamples(device,
                                                 @"pooling_basic_input_15x16x32.tensor",
                                                 @"pooling_basic_output_15x16x32.tensor", 3, 3, 1,
                                                 1, pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildDataForGoldenStandardExamples(device,
                                                 @"pooling_stride_input_15x16x32.tensor",
                                                 @"pooling_stride_output_8x8x32.tensor", 3, 3, 2, 2,
                                                 pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildDataForGoldenStandardExamples(device,
                                                 @"pooling_valid_input_15x16x32.tensor",
                                                 @"pooling_valid_output_13x14x32.tensor", 3, 3, 1,
                                                 1, pnk::PoolingTypeAverage, pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildDataForGoldenStandardExamples(device,
                                                 @"pooling_max_input_15x16x32.tensor",
                                                 @"pooling_max_output_15x16x32.tensor", 3, 3, 1, 1,
                                                 pnk::PoolingTypeMax, pnk::PaddingTypeSame);
  });
});

context(@"pooling", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1,
                                                  pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 4, 1, 1,
                                                  pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 2, 2,
                                                  pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 3, 3,
                                                  pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 5, 1, 1,
                                                  pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 64, 32, 3, 3, 1, 1, 1,
                                                  pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 31, 33, 3, 3, 1, 1, 1,
                                                  pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 4, 4, 2, 2, 1, 1, 1,
                                                  pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 2, 1, 2, 2,
                                                  pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 4, 4, 4, 3, 1, 2, 2,
                                                  pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 2, 2, 1, 4, 3,
                                                  pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 7, 1, 5, 9,
                                                  pnk::PoolingTypeAverage, pnk::PaddingTypeSame);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1,
                                                  pnk::PoolingTypeAverage, pnk::PaddingTypeValid);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildHalfFloatDataForKernelExamples(device, 32, 32, 3, 3, 1, 1, 1,
                                                  pnk::PoolingTypeMax, pnk::PaddingTypeSame);
  });
});

context(@"PNKTemporaryImageExamples", ^{
  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    pnk::PoolingKernelModel poolingModel = {
      .pooling = pnk::PoolingTypeAverage,
      .kernelWidth = 3,
      .kernelHeight = 3,
      .strideX = 1,
      .strideY = 1,
      .padding = pnk::PaddingTypeSame,
      .averagePoolExcludePadding = YES,
      .globalPooling = NO
    };

    auto poolingKernel = [[PNKPoolingLayer alloc] initWithDevice:device poolingModel:poolingModel];
    return @{
      kPNKTemporaryImageExamplesKernel: poolingKernel,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @1
    };
  });
});

DeviceSpecEnd

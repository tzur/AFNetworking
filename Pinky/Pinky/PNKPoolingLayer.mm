// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKPoolingLayer.h"

#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKPoolingLayer ()

/// Undelying pooling kernel used for performing the operation.
@property (readonly, nonatomic) MPSCNNPooling *poolingKernel;

/// Padding type used in the pooling.
@property (readonly, nonatomic) pnk::PaddingType padding;

@end

@implementation PNKPoolingLayer

@synthesize kernelWidth = _kernelWidth;
@synthesize kernelHeight = _kernelHeight;
@synthesize inputFeatureChannels = _inputFeatureChannels;
@synthesize outputFeatureChannels = _outputFeatureChannels;
@synthesize strideX = _strideX;
@synthesize strideY = _strideY;
@synthesize groups = _groups;

- (instancetype)initWithDevice:(id<MTLDevice>)device
                  poolingModel:(const pnk::PoolingKernelModel &)poolingModel {
  if (self = [super init]) {
    [self updatePropertiesWithPoolingModel:poolingModel];
    [self createPoolingKernelWithDevice:device poolingModel:poolingModel];
  }
  return self;
}

- (void)updatePropertiesWithPoolingModel:(pnk::PoolingKernelModel)poolingModel {
  LTParameterAssert(poolingModel.padding == pnk::PaddingTypeSame ||
                    poolingModel.padding == pnk::PaddingTypeValid, @"Invalid padding type: %lu",
                    (unsigned long)poolingModel.padding);
  _kernelWidth = poolingModel.kernelWidth;
  _kernelHeight = poolingModel.kernelHeight;
  _inputFeatureChannels = 0;
  _outputFeatureChannels = 0;
  _strideX = poolingModel.strideX;
  _strideY = poolingModel.strideY;
  _groups = 1;
  _padding = poolingModel.padding;
}

- (void)createPoolingKernelWithDevice:(id<MTLDevice>)device
                         poolingModel:(const pnk::PoolingKernelModel &)poolingModel {
  switch (poolingModel.pooling) {
    case pnk::PoolingTypeAverage:
      _poolingKernel = [[MPSCNNPoolingAverage alloc] initWithDevice:device
                                                        kernelWidth:poolingModel.kernelWidth
                                                       kernelHeight:poolingModel.kernelHeight
                                                    strideInPixelsX:poolingModel.strideX
                                                    strideInPixelsY:poolingModel.strideY];
      break;
    case pnk::PoolingTypeMax:
      _poolingKernel = [[MPSCNNPoolingMax alloc] initWithDevice:device
                                                    kernelWidth:poolingModel.kernelWidth
                                                   kernelHeight:poolingModel.kernelHeight
                                                strideInPixelsX:poolingModel.strideX
                                                strideInPixelsY:poolingModel.strideY];
      break;
    default:
      LTParameterAssert(NO, @"Unknown pooling type %lu", (unsigned long)poolingModel.pooling);
  }

  self.poolingKernel.edgeMode = MPSImageEdgeModeClamp;
}

#pragma mark -
#pragma mark PNKUnaryImageKernel
#pragma mark -

/// We calculate offset to fit the Tensor Flow padding scheme. For more details see
/// https://www.tensorflow.org/api_guides/python/nn#Convolution.
- (MPSOffset)calculateOffsetWithInputImage:(MPSImage *)inputImage {
  NSUInteger mpsPaddingLeft = self.kernelWidth / 2;
  NSUInteger mpsPaddingTop = self.kernelHeight / 2;
  NSUInteger tensorFlowPaddingLeft, tensorFlowPaddingTop;
  switch (self.padding) {
    case pnk::PaddingTypeSame: {
      NSUInteger strideResidualX = (inputImage.width - 1) % self.strideX + 1;
      tensorFlowPaddingLeft = (std::max(self.kernelWidth, strideResidualX) - strideResidualX) / 2;
      NSUInteger strideResidualY = (inputImage.height - 1) % self.strideY + 1;
      tensorFlowPaddingTop = (std::max(self.kernelHeight, strideResidualY) - strideResidualY) / 2;
    } break;
    case pnk::PaddingTypeValid:
      tensorFlowPaddingLeft = 0;
      tensorFlowPaddingTop = 0;
      break;
  }

  return {
    .x = static_cast<NSInteger>(mpsPaddingLeft - tensorFlowPaddingLeft),
    .y = static_cast<NSInteger>(mpsPaddingTop - tensorFlowPaddingTop),
    .z = 0
  };
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  MTLSize inputSize = {inputImage.width, inputImage.height, inputImage.featureChannels};
  MTLSize expectedOutputSize = [self outputSizeForInputSize:inputSize];
  LTParameterAssert(outputImage.width == expectedOutputSize.width &&
                    outputImage.height == expectedOutputSize.height &&
                    outputImage.featureChannels == expectedOutputSize.depth,
                    @"Output image must be of size (%lu, %lu, %lu), got: (%lu, %lu, %lu)",
                    expectedOutputSize.width, expectedOutputSize.height, expectedOutputSize.depth,
                    outputImage.width, outputImage.height, outputImage.featureChannels);

  self.poolingKernel.offset = [self calculateOffsetWithInputImage:inputImage];
  [self.poolingKernel encodeToCommandBuffer:commandBuffer sourceImage:inputImage
                           destinationImage:outputImage];
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  switch (self.padding) {
    case pnk::PaddingTypeSame:
      return {
        (inputSize.width + self.strideX - 1) / self.strideX,
        (inputSize.height + self.strideY - 1) / self.strideY,
        inputSize.depth
      };
    case pnk::PaddingTypeValid:
      return {
        (inputSize.width + self.strideX - self.kernelWidth) / self.strideX,
        (inputSize.height + self.strideY - self.kernelHeight) / self.strideY,
        inputSize.depth
      };
  }
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = [self inputSizeForOutputSize:outputSize]
  };
}

- (MTLSize)inputSizeForOutputSize:(MTLSize)outputSize {
  switch (self.padding) {
    case pnk::PaddingTypeSame:
      return {
        (outputSize.width - 1) * self.strideX + 1,
        (outputSize.height - 1) * self.strideY + 1,
        outputSize.depth
      };
    case pnk::PaddingTypeValid:
      return {
        (outputSize.width - 1) * self.strideX + self.kernelWidth,
        (outputSize.height - 1) * self.strideY + self.kernelHeight,
        outputSize.depth
      };
  }
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

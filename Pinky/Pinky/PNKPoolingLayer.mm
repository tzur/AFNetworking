// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKPoolingLayer.h"

#import "PNKConvolutionUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKPoolingLayer ()

/// Underlying pooling kernel used for performing the operation.
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
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  MTLSize inputSize = {inputImage.width, inputImage.height, inputImage.featureChannels};
  MTLSize expectedOutputSize = PNKConvolutionOutputSize(inputSize, self.kernelWidth,
                                                        self.kernelHeight, 1, 1, self.strideX,
                                                        self.strideY, self.padding,
                                                        inputImage.featureChannels);
  LTParameterAssert(outputImage.width == expectedOutputSize.width &&
                    outputImage.height == expectedOutputSize.height &&
                    outputImage.featureChannels == expectedOutputSize.depth,
                    @"Output image must be of size (%lu, %lu, %lu), got: (%lu, %lu, %lu)",
                    (unsigned long)expectedOutputSize.width,
                    (unsigned long)expectedOutputSize.height,
                    (unsigned long)expectedOutputSize.depth, (unsigned long)outputImage.width,
                    (unsigned long)outputImage.height, (unsigned long)outputImage.featureChannels);

  self.poolingKernel.offset = PNKConvolutionOffset(inputImage.width, inputImage.height,
                                                   self.kernelWidth, self.kernelHeight, 1, 1,
                                                   self.strideX, self.strideY, self.padding);

  [self.poolingKernel encodeToCommandBuffer:commandBuffer sourceImage:inputImage
                           destinationImage:outputImage];
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = PNKConvolutionInputSize(outputSize, self.kernelWidth, self.kernelHeight, 1, 1,
                                    self.strideX, self.strideY, self.padding, outputSize.depth)
  };
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return  PNKConvolutionOutputSize(inputSize, self.kernelWidth, self.kernelHeight, 1, 1,
                                   self.strideX, self.strideY, self.padding, inputSize.depth);
}

@end

NS_ASSUME_NONNULL_END

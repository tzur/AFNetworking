// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKConvolutionLayer.h"

#import "MPSCNNConvolution+Factory.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKConvolutionLayer ()

/// Undelying convolution kernel used for performing the operation.
@property (readonly, nonatomic) MPSCNNConvolution *convolutionKernel;

/// Padding type used in the convolution.
@property (readonly, nonatomic) pnk::PaddingType padding;

@end

@implementation PNKConvolutionLayer

@synthesize kernelWidth = _kernelWidth;
@synthesize kernelHeight = _kernelHeight;
@synthesize inputFeatureChannels = _inputFeatureChannels;
@synthesize outputFeatureChannels = _outputFeatureChannels;
@synthesize strideX = _strideX;
@synthesize strideY = _strideY;
@synthesize groups = _groups;

- (instancetype)initWithDevice:(id<MTLDevice>)device
              convolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel
               activationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (self = [super init]) {
    [self updatePropertiesWithConvolutionModel:convolutionModel];
    _convolutionKernel = [MPSCNNConvolution pnk_cnnConvolutionWithDevice:device
                                                        convolutionModel:convolutionModel
                                                         activationModel:activationModel];
  }
  return self;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
              convolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel {
  return [self initWithDevice:device convolutionModel:convolutionModel
              activationModel:{.activationType = pnk::ActivationTypeIdentity}];
}

- (void)updatePropertiesWithConvolutionModel:(pnk::ConvolutionKernelModel)convolutionModel {
  _kernelWidth = convolutionModel.kernelWidth;
  _kernelHeight = convolutionModel.kernelHeight;
  _inputFeatureChannels = convolutionModel.inputFeatureChannels;
  _outputFeatureChannels = convolutionModel.outputFeatureChannels;
  _strideX = convolutionModel.strideX;
  _strideY = convolutionModel.strideY;
  _groups = convolutionModel.groups;
  _padding = convolutionModel.padding;
}

#pragma mark -
#pragma mark PNKUnaryImageKernel
#pragma mark -

- (MPSOffset)calculateOffsetWithInputImage:(MPSImage *)inputImage
                               outputImage:(MPSImage *)outputImage {
  switch (self.padding) {
    case pnk::PaddingTypeSame: {
      NSUInteger padHeight = ((outputImage.height - 1) * self.strideY + self.kernelHeight -
                              inputImage.height);
      NSUInteger padWidth = ((outputImage.width - 1) * self.strideX + self.kernelWidth -
                             inputImage.width);
      return {
        .x = static_cast<NSInteger>(self.kernelWidth - padWidth) / 2,
        .y = static_cast<NSInteger>(self.kernelHeight - padHeight) / 2,
        .z = 0
      };
    }
    case pnk::PaddingTypeValid:
      return {
        .x = static_cast<NSInteger>(self.kernelWidth / 2),
        .y = static_cast<NSInteger>(self.kernelHeight / 2),
        .z = 0
      };
  }
  LTParameterAssert(NO, @"Invalid padding type: %lu", (unsigned long)self.padding);
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  self.convolutionKernel.offset = [self calculateOffsetWithInputImage:inputImage
                                                          outputImage:outputImage];
  [self.convolutionKernel encodeToCommandBuffer:commandBuffer sourceImage:inputImage
                               destinationImage:outputImage];
}

- (MTLSize)inputSizeForOutputSize:(MTLSize)outputSize {
  switch (self.padding) {
    case pnk::PaddingTypeSame:
      return {
        (outputSize.width - 1) * self.strideX + self.kernelWidth,
        (outputSize.height - 1) * self.strideY + self.kernelHeight,
        self.inputFeatureChannels
      };
    case pnk::PaddingTypeValid:
      return {
        (outputSize.width - 1) * self.strideX + 1,
        (outputSize.height - 1) * self.strideY + 1,
        self.inputFeatureChannels
      };
  }
  LTParameterAssert(NO, @"Invalid padding type: %lu", (unsigned long)self.padding);
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = [self inputSizeForOutputSize:outputSize]
  };
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

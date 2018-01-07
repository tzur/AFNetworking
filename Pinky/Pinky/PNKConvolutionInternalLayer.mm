// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKConvolutionInternalLayer.h"

#import "MPSCNNConvolution+Factory.h"
#import "PNKConvolutionUtils.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKConvolutionInternalLayer ()

/// Underlying convolution kernel used for performing the operation.
@property (readonly, nonatomic) MPSCNNConvolution *convolutionKernel;

/// Padding type used in the convolution.
@property (readonly, nonatomic) pnk::PaddingType padding;

/// Kernel dilation in the x dimension.
@property (readonly, nonatomic) NSUInteger dilationX;

/// Kernel dilation in the y dimension.
@property (readonly, nonatomic) NSUInteger dilationY;

@end

@implementation PNKConvolutionInternalLayer

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
  if(@available(iOS 11.0, *)) {
    // On iOS 11 and up MPSCNNConvolution accepts dilation.
  } else {
    LTParameterAssert(convolutionModel.dilationX == 1 && convolutionModel.dilationY == 1,
                      @"PNKConvolutionInternalLayer class cannot perform dilated convolution. "
                      "Please use PNKDilatedConvolutionInternalLayer instead.");
  }
  _kernelWidth = convolutionModel.kernelWidth;
  _kernelHeight = convolutionModel.kernelHeight;
  _inputFeatureChannels = convolutionModel.inputFeatureChannels;
  _outputFeatureChannels = convolutionModel.outputFeatureChannels;
  _strideX = convolutionModel.strideX;
  _strideY = convolutionModel.strideY;
  _dilationX = convolutionModel.dilationX;
  _dilationY = convolutionModel.dilationY;
  _groups = convolutionModel.groups;
  _padding = convolutionModel.padding;
}

#pragma mark -
#pragma mark PNKUnaryImageKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  self.convolutionKernel.offset = PNKConvolutionOffset(inputImage.width, inputImage.height,
                                                       self.kernelWidth, self.kernelHeight,
                                                       self.dilationX, self.dilationY, self.strideX,
                                                       self.strideY, self.padding);
  [self.convolutionKernel encodeToCommandBuffer:commandBuffer sourceImage:inputImage
                               destinationImage:outputImage];
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = PNKConvolutionInputSize(outputSize, self.kernelWidth, self.kernelHeight, self.dilationX,
                                    self.dilationY, self.strideX, self.strideY, self.padding,
                                    self.inputFeatureChannels)
  };
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

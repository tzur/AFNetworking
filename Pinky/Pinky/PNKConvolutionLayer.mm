// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKConvolutionLayer.h"

#import "PNKConvolutionInternalLayer.h"
#import "PNKDilatedConvolutionInternalLayer.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKConvolutionLayer ()

/// Underlying internal convolution layer.
@property (readonly, nonatomic) id<PNKUnaryKernel> internalConvolutionLayer;

@end

@implementation PNKConvolutionLayer

@synthesize inputFeatureChannels = _inputFeatureChannels;

- (instancetype)initWithDevice:(id<MTLDevice>)device
              convolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel
               activationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (self = [super init]) {
    if (@available(iOS 11.0, *)) {
      _internalConvolutionLayer = [[PNKConvolutionInternalLayer alloc]
                                   initWithDevice:device
                                   convolutionModel:convolutionModel
                                   activationModel:activationModel];
    } else if (convolutionModel.dilationX == 1 && convolutionModel.dilationY == 1) {
      _internalConvolutionLayer = [[PNKConvolutionInternalLayer alloc]
                                   initWithDevice:device
                                   convolutionModel:convolutionModel
                                   activationModel:activationModel];
    } else {
      _internalConvolutionLayer = [[PNKDilatedConvolutionInternalLayer alloc]
                                   initWithDevice:device
                                   convolutionModel:convolutionModel
                                   activationModel:activationModel];
    }
  }
  return self;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
              convolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel {
  return [self initWithDevice:device convolutionModel:convolutionModel
              activationModel:{.activationType = pnk::ActivationTypeIdentity}];
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
    [self.internalConvolutionLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                             outputImage:outputImage];
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return [self.internalConvolutionLayer inputRegionForOutputSize:outputSize];
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return [self.internalConvolutionLayer outputSizeForInputSize:inputSize];
}

@end

NS_ASSUME_NONNULL_END

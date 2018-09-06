// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKActivationLayer.h"

#import "PNKActivationCustomInternalLayer.h"
#import "PNKActivationStandardInternalLayer.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKActivationLayer ()

/// Underlying internal activation layer.
@property (readonly, nonatomic) id<PNKUnaryKernel> internalNeuronLayer;

@end

@implementation PNKActivationLayer

@synthesize inputFeatureChannels = _inputFeatureChannels;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device
               activationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (self = [super init]) {
    pnk::ActivationType activationType = activationModel.activationType;
    if ([PNKActivationStandardInternalLayer doesSupportActivationType:activationType]) {
      _internalNeuronLayer = [[PNKActivationStandardInternalLayer alloc] initWithDevice:device
                              activationModel:activationModel];
    } else if ([PNKActivationCustomInternalLayer doesSupportActivationType:activationType]) {
      _internalNeuronLayer = [[PNKActivationCustomInternalLayer alloc] initWithDevice:device
                              activationModel:activationModel];
    } else {
      LTParameterAssert(NO, @"Activation type %lu is not supported", (unsigned long)activationType);
    }
  }
  return self;
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self.internalNeuronLayer encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                      outputImage:outputImage];
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return [self.internalNeuronLayer inputRegionForOutputSize:outputSize];
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return [self.internalNeuronLayer outputSizeForInputSize:inputSize];
}

@end

NS_ASSUME_NONNULL_END

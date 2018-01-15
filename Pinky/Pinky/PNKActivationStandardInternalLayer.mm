// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKActivationStandardInternalLayer.h"

#import "MPSCNNNeuron+Factory.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKActivationStandardInternalLayer ()

/// Underlying activation kernel used for performing the operation.
@property (readonly, nonatomic) MPSCNNNeuron *neuron;

@end

@implementation PNKActivationStandardInternalLayer

@synthesize inputFeatureChannels = _inputFeatureChannels;

- (instancetype)initWithDevice:(id<MTLDevice>)device
               activationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (self = [super init]) {
    _neuron = [MPSCNNNeuron pnk_cnnNeuronWithDevice:device activationModel:activationModel];
  }
  return self;
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self.neuron encodeToCommandBuffer:commandBuffer sourceImage:inputImage
                    destinationImage:outputImage];
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = outputSize
  };
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return inputSize;
}

#pragma mark -
#pragma mark PNKActivationKernel
#pragma mark -

+ (BOOL)doesSupportActivationType:(pnk::ActivationType)activationType {
  if (@available(iOS 11.0, *)) {
    static const std::set<pnk::ActivationType> kSupportedTypes = {
      pnk::ActivationTypeAbsolute,
      pnk::ActivationTypeReLU,
      pnk::ActivationTypeLeakyReLU,
      pnk::ActivationTypeTanh,
      pnk::ActivationTypeScaledTanh,
      pnk::ActivationTypeSigmoid,
      pnk::ActivationTypeSigmoidHard,
      pnk::ActivationTypeLinear,
      pnk::ActivationTypePReLU,
      pnk::ActivationTypeELU,
      pnk::ActivationTypeSoftsign,
      pnk::ActivationTypeSoftplus,
      pnk::ActivationTypeParametricSoftplus
    };
    return kSupportedTypes.count(activationType);
  } else {
    static const std::set<pnk::ActivationType> kSupportedTypes = {
      pnk::ActivationTypeAbsolute,
      pnk::ActivationTypeReLU,
      pnk::ActivationTypeLeakyReLU,
      pnk::ActivationTypeTanh,
      pnk::ActivationTypeScaledTanh,
      pnk::ActivationTypeSigmoid,
      pnk::ActivationTypeLinear,
    };
    return kSupportedTypes.count(activationType);
  }
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END


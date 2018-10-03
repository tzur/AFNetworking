// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKInstanceNormLayer.h"

#import "PNKBufferExtensions.h"
#import "PNKInstanceNormInternalKernel.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKInstanceNormLayer ()

/// Instance normalization kernel performing the operation underlying this layer.
@property (readonly, nonatomic) PNKInstanceNormInternalKernel *instanceNormKernel;

@end

@implementation PNKInstanceNormLayer

@synthesize inputFeatureChannels = _inputFeatureChannels;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device
            normalizationModel:(const pnk::NormalizationKernelModel &)normalizationModel
               activationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (self = [super init]) {
    [self updatePropertiesWithNormalizationModel:normalizationModel];
    _instanceNormKernel = [[PNKInstanceNormInternalKernel alloc]
                           initWithDevice:device
                           featureChannels:normalizationModel.inputFeatureChannels
                           activationModel:activationModel
                           reuseParameterBuffers:YES];

    [self.instanceNormKernel setScaleParameters:normalizationModel.scale];
    [self.instanceNormKernel setShiftParameters:normalizationModel.shift];
  }
  return self;
}

- (void)updatePropertiesWithNormalizationModel:(const pnk::NormalizationKernelModel &)model {
  LTParameterAssert(model.instanceNormalization,
                    @"Normalization model must be instance normalization");
  LTParameterAssert(model.scale.cols == (int)model.inputFeatureChannels,
                    @"Normalization model scale parameters must be equal to the number of input "
                    "features (%lu), got %lu", (unsigned long)model.inputFeatureChannels,
                    (unsigned long)model.scale.cols);
  LTParameterAssert(model.shift.cols == (int)model.inputFeatureChannels,
                    @"Normalization model shift parameters must be equal to the number of input "
                    "features (%lu), got %lu", (unsigned long)model.inputFeatureChannels,
                    (unsigned long)model.shift.cols);
  _inputFeatureChannels = model.inputFeatureChannels;
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self.instanceNormKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                     outputImage:outputImage];
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return [self.instanceNormKernel inputRegionForOutputSize:outputSize];
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return [self.instanceNormKernel outputSizeForInputSize:inputSize];
}

@end

NS_ASSUME_NONNULL_END

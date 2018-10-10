// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKSoftMaxLayer.h"

#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKSoftMaxLayer ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Underlying SoftMax kernel.
@property (readonly, nonatomic) MPSCNNSoftMax *softMaxKernel;

@end

@implementation PNKSoftMaxLayer

@synthesize inputFeatureChannels = _inputFeatureChannels;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  if (self = [super init]) {
    _device = device;
    _softMaxKernel = [[MPSCNNSoftMax alloc] initWithDevice:device];
  }
  return self;
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.width == outputImage.width &&
                    inputImage.height == outputImage.height &&
                    inputImage.featureChannels == outputImage.featureChannels,
                    @"Input image and output image must be of the same size, got input image size "
                    "(%lu, %lu, %lu) and output image size (%lu, %lu, %lu)",
                    (unsigned long)inputImage.width, (unsigned long)inputImage.height,
                    (unsigned long)inputImage.featureChannels, (unsigned long)outputImage.width,
                    (unsigned long)outputImage.height, (unsigned long)outputImage.featureChannels);

  [self.softMaxKernel encodeToCommandBuffer:commandBuffer sourceImage:inputImage
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

@end

NS_ASSUME_NONNULL_END

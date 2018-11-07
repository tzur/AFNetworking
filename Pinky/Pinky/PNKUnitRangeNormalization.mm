// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKUnitRangeNormalization.h"

#import <MetalToolbox/MPSTemporaryImage+Factory.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNKUnitRangeNormalization ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode full rescale operation.
@property (readonly, nonatomic, nullable) id<MTLComputePipelineState> stateFullRescale;

/// Kernel state to encode rescale operation when minimal and maximal values are pre-computed by
/// an \c MPSImageStatisticsMinAndMax kernel.
@property (readonly, nonatomic, nullable) id<MTLComputePipelineState> stateRescaleWithMinAndMax;

/// Finds the minimum and maximum pixel values in a given image. Faster than our metal
/// implementation but available only on iOS 11.
@property (readonly, nonatomic, nullable) MPSImageStatisticsMinAndMax *mpsMinMax
    NS_AVAILABLE_IOS(11);

@end

@implementation PNKUnitRangeNormalization

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  if (self = [super init]) {
    _device = device;
    [self createComputeStates];
  }
  return self;
}

- (void)createComputeStates {
  if (@available(iOS 11.0, *)) {
    if ([self.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily3_v3]) {
      [self createFastComputeStates];
      return;
    }
  }

  [self createSlowComputeStates];
}

- (void)createFastComputeStates NS_AVAILABLE_IOS(11) {
  _mpsMinMax = [[MPSImageStatisticsMinAndMax alloc] initWithDevice:self.device];
  _stateRescaleWithMinAndMax = PNKCreateComputeState(self.device, @"rescaleWithMinAndMax");
}

- (void)createSlowComputeStates {
  _stateFullRescale = PNKCreateComputeState(self.device, @"fullRescale");
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  if (@available(iOS 11.0, *)) {
    if (self.mpsMinMax) {
      [self encodeFastToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
      return;
    }
  }

  [self encodeSlowToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
}

- (void)encodeFastToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                       inputImage:(MPSImage *)inputImage
                      outputImage:(MPSImage *)outputImage NS_AVAILABLE_IOS(11) {
  auto minMaxSize = MTLSizeMake(2, 1, inputImage.featureChannels);
  auto minMaxImage = [MPSTemporaryImage mtb_float16TemporaryImageWithCommandBuffer:commandBuffer
                                                                              size:minMaxSize];
  [self.mpsMinMax encodeToCommandBuffer:commandBuffer sourceImage:inputImage
                       destinationImage:minMaxImage];
  MTBComputeDispatchWithDefaultThreads(self.stateRescaleWithMinAndMax, commandBuffer,
                                       @[inputImage, minMaxImage], @[outputImage],
                                       @"rescaleWithMinAndMax", inputImage.pnk_size);
}

- (void)encodeSlowToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                       inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  static const NSUInteger kMaxThreadsInGroup = 512;
  auto threadWidth = std::min(kMaxThreadsInGroup, outputImage.width);
  auto threadHeight = std::min(kMaxThreadsInGroup / threadWidth, outputImage.height);
  MTLSize threadsInGroup = MTLSizeMake(threadWidth, threadHeight, 1);
  MTLSize threadgroupsPerGrid = {1, 1, 1};

  MTBComputeDispatch(self.stateFullRescale, commandBuffer, @[inputImage], @[outputImage],
                     @"fullRescale", threadsInGroup, threadgroupsPerGrid);
}

- (void)verifyParametersWithInputImage:(MPSImage *)inputImage
                           outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.textureType == MTLTextureType2D, @"Input image texture type must "
                    "equal MTLTextureType2D(%lu), got %lu", (unsigned long)MTLTextureType2D,
                    (unsigned long)inputImage.textureType);
  LTParameterAssert(outputImage.textureType == MTLTextureType2D, @"Output image texture type must "
                    "equal MTLTextureType2D(%lu), got %lu", (unsigned long)MTLTextureType2D,
                    (unsigned long)outputImage.textureType);
  LTParameterAssert(inputImage.featureChannels == outputImage.featureChannels, @"Input image "
                    "featureChannels must match output image featureChannels. got: (%lu, %lu)",
                    (unsigned long)inputImage.featureChannels,
                    (unsigned long)outputImage.featureChannels);
  LTParameterAssert(inputImage.width == outputImage.width,
                    @"Input image width must match output image width. got: (%lu, %lu)",
                    (unsigned long)inputImage.width, (unsigned long)outputImage.width);
  LTParameterAssert(inputImage.height == outputImage.height,
                    @"Input image height must match output image height. got: (%lu, %lu)",
                    (unsigned long)inputImage.height, (unsigned long)outputImage.height);
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

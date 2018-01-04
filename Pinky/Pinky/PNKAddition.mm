// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKAddition.h"

#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKAddition ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode single texture addition.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingle;

/// Kernel state to encode texture array addition.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArray;

@end

@implementation PNKAddition

@synthesize primaryInputFeatureChannels = _primaryInputFeatureChannels;
@synthesize secondaryInputFeatureChannels = _secondaryInputFeatureChannels;

/// Kernel function name for a single texture.
static NSString * const kKernelSingleFunctionName = @"additionSingle";

/// Kernel function name for texture array.
static NSString * const kKernelArrayFunctionName = @"additionArray";

/// Family name of the kernel functions for debug purposes.
static NSString * const kDebugGroupName = @"addition";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  if (self = [super init]) {
    _device = device;
    [self createStates];
  }
  return self;
}

- (void)createStates {
  _stateSingle = PNKCreateComputeState(self.device, kKernelSingleFunctionName);
  _stateArray = PNKCreateComputeState(self.device, kKernelArrayFunctionName);
}

#pragma mark -
#pragma mark PNKBinaryImageKernel
#pragma mark -

- (void)verifyParametersWithPrimaryInputImage:(MPSImage *)primaryInputImage
                          secondaryInputImage:(MPSImage *)secondaryInputImage
                                  outputImage:(MPSImage *)outputImage {
  LTParameterAssert(primaryInputImage.width == secondaryInputImage.width, @"Primary input "
                    "image width must match secondary input image width. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.width,
                    (unsigned long)secondaryInputImage.width);
  LTParameterAssert(primaryInputImage.height == secondaryInputImage.height, @"Primary input "
                    "image height must match secondary input image height. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.height,
                    (unsigned long)secondaryInputImage.height);
  LTParameterAssert(primaryInputImage.featureChannels == secondaryInputImage.featureChannels,
                    @"Primary input image featureChannels must match secondary input image "
                    "featureChannels. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.featureChannels,
                    (unsigned long)secondaryInputImage.featureChannels);
  LTParameterAssert(primaryInputImage.width == outputImage.width,
                    @"Primary input image width must match output image width. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.width, (unsigned long)outputImage.width);
  LTParameterAssert(primaryInputImage.height == outputImage.height, @"Primary input image "
                    "height must match output image height. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.height, (unsigned long)outputImage.height);
  LTParameterAssert(primaryInputImage.featureChannels == outputImage.featureChannels, @"Primary "
                    "input image featureChannels must match output image featureChannels. got: "
                    "(%lu, %lu)", (unsigned long)primaryInputImage.featureChannels,
                    (unsigned long)outputImage.featureChannels);
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(MPSImage *)secondaryInputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithPrimaryInputImage:primaryInputImage
                          secondaryInputImage:secondaryInputImage outputImage:outputImage];

  NSArray<id<MTLTexture>> *textures = @[
    primaryInputImage.texture,
    secondaryInputImage.texture,
    outputImage.texture
  ];

  MTLSize workingSpaceSize = {
    outputImage.width,
    outputImage.height,
    outputImage.texture.arrayLength};

  auto state = outputImage.featureChannels <= 4 ? self.stateSingle : self.stateArray;

  PNKComputeDispatchWithDefaultThreads(state, commandBuffer, @[], textures, kDebugGroupName,
                                       workingSpaceSize);

  if ([primaryInputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *)primaryInputImage).readCount -= 1;
  }
  if ([secondaryInputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *)secondaryInputImage).readCount -= 1;
  }
}

- (MTLRegion)primaryInputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = outputSize
  };
}

- (MTLRegion)secondaryInputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = outputSize
  };
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

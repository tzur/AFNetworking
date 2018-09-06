// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKArithmetic.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKArithmetic ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Operation to be executed by the kernel.
@property (readonly, nonatomic) pnk::ArithmeticOperation operation;

/// Kernel state to encode single texture arithmetic operation.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingle;

/// Kernel state to encode single texture arithmetic operation with broadcasting the primary input.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingleBroadcastPrimary;

/// Kernel state to encode single texture arithmetic operation with broadcasting the secondary
/// input.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingleBroadcastSecondary;

/// Kernel state to encode texture array arithmetic operation.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArray;

/// Kernel state to encode arithmetic operation such that the primary input is a single-channel
/// texture broadcasted onto a texture array secondary input.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArrayBroadcastPrimary;

/// Kernel state to encode arithmetic operation such that the secondary input is a single-channel
/// texture broadcasted onto a texture array primary input.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArrayBroadcastSecondary;

@end

@implementation PNKArithmetic

@synthesize primaryInputFeatureChannels = _primaryInputFeatureChannels;
@synthesize secondaryInputFeatureChannels = _secondaryInputFeatureChannels;

/// Kernel function name for a single texture. Does not use broadcasting.
static NSString * const kKernelSingle = @"arithmeticSingle";

/// Kernel function name for a single texture. Broadcasts the primary input.
static NSString * const kKernelSingleBroadcastPrimary = @"arithmeticSingleBroadcastPrimary";

/// Kernel function name for a single texture. Broadcasts the secondary input.
static NSString * const kKernelSingleBroadcastSecondary = @"arithmeticSingleBroadcastSecondary";

/// Kernel function name for texture array. Does not use broadcasting.
static NSString * const kKernelArray = @"arithmeticArray";

/// Kernel function name for texture array. Broadcasts the single-channel primary input texture
/// onto a texture array secondary input.
static NSString * const kKernelArrayBroadcastPrimary = @"arithmeticArrayBroadcastPrimary";

/// Kernel function name for texture array. Broadcasts the single-channel secondary input texture
/// onto a texture array primary input.
static NSString * const kKernelArrayBroadcastSecondary = @"arithmeticArrayBroadcastSecondary";

/// Family name of the kernel functions for debug purposes.
static NSString * const kDebugGroupName = @"arithmetic";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device operation:(pnk::ArithmeticOperation)operation {
  if (self = [super init]) {
    _device = device;
    _operation = operation;
    [self createStates];
  }
  return self;
}

- (void)createStates {
  auto functionConstants = @[
    [MTBFunctionConstant ushortConstantWithValue:self.operation name:@"operation"]
  ];

  _stateSingle = PNKCreateComputeState(self.device, kKernelSingle, functionConstants);
  _stateSingleBroadcastPrimary = PNKCreateComputeState(self.device, kKernelSingleBroadcastPrimary,
                                                       functionConstants);
  _stateSingleBroadcastSecondary =
      PNKCreateComputeState(self.device, kKernelSingleBroadcastSecondary, functionConstants);
  _stateArray = PNKCreateComputeState(self.device, kKernelArray, functionConstants);
  _stateArrayBroadcastPrimary = PNKCreateComputeState(self.device, kKernelArrayBroadcastPrimary,
                                                      functionConstants);
  _stateArrayBroadcastSecondary = PNKCreateComputeState(self.device, kKernelArrayBroadcastSecondary,
                                                        functionConstants);
}

#pragma mark -
#pragma mark PNKBinaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(MPSImage *)secondaryInputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithPrimaryInputImage:primaryInputImage
                          secondaryInputImage:secondaryInputImage outputImage:outputImage];

  NSArray<MPSImage *> *inputImages = @[primaryInputImage, secondaryInputImage];
  NSArray<MPSImage *> *outputImages = @[outputImage];

  MTLSize workingSpaceSize = outputImage.pnk_textureArraySize;

  id<MTLComputePipelineState> state;
  if (primaryInputImage.featureChannels == secondaryInputImage.featureChannels) {
    state = outputImage.pnk_isSingleTexture ? self.stateSingle : self.stateArray;
  } else if (primaryInputImage.featureChannels == 1) {
    state = outputImage.pnk_isSingleTexture ?
        self.stateSingleBroadcastPrimary : self.stateArrayBroadcastPrimary;
  } else {
    state = outputImage.pnk_isSingleTexture ?
        self.stateSingleBroadcastSecondary : self.stateArrayBroadcastSecondary;
  }

  MTBComputeDispatchWithDefaultThreads(state, commandBuffer, inputImages, outputImages,
                                       kDebugGroupName, workingSpaceSize);
}

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
  LTParameterAssert(primaryInputImage.featureChannels == secondaryInputImage.featureChannels ||
                    primaryInputImage.featureChannels == 1 ||
                    secondaryInputImage.featureChannels == 1,
                    @"Either primary input image featureChannels must match secondary input image "
                    "featureChannels or one of them must have a single channel. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.featureChannels,
                    (unsigned long)secondaryInputImage.featureChannels);
  LTParameterAssert(primaryInputImage.width == outputImage.width,
                    @"Primary input image width must match output image width. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.width, (unsigned long)outputImage.width);
  LTParameterAssert(primaryInputImage.height == outputImage.height, @"Primary input image "
                    "height must match output image height. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.height, (unsigned long)outputImage.height);
  LTParameterAssert(outputImage.featureChannels == std::max(primaryInputImage.featureChannels,
                                                            secondaryInputImage.featureChannels),
                    @"Output image featureChannels must match the maximal featureChannels of the "
                    "two input images. got: (%lu, %lu)", (unsigned long)outputImage.featureChannels,
                    (unsigned long)std::max(primaryInputImage.featureChannels,
                                            secondaryInputImage.featureChannels));
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

- (MTLSize)outputSizeForPrimaryInputSize:(MTLSize)primaryInputSize
                      secondaryInputSize:(MTLSize)secondaryInputSize {
  LTParameterAssert(primaryInputSize.width == secondaryInputSize.width &&
                    primaryInputSize.height == secondaryInputSize.height, @"Primary and secondary "
                    "input width and height must be equal, got (%lu, %lu) and (%lu, %lu)",
                    (unsigned long)primaryInputSize.width, (unsigned long)primaryInputSize.height,
                    (unsigned long)secondaryInputSize.width,
                    (unsigned long)secondaryInputSize.height);
  LTParameterAssert(primaryInputSize.depth == secondaryInputSize.depth ||
                    primaryInputSize.depth == 1 || secondaryInputSize.depth == 1, @"Either primary "
                    "input depth must match secondary input depth or one of them must equal 1. "
                    "got: (%lu, %lu)", (unsigned long)primaryInputSize.depth,
                    (unsigned long)secondaryInputSize.depth);

  return {
    .width = primaryInputSize.width,
    .height = primaryInputSize.height,
    .depth = std::max(primaryInputSize.depth, secondaryInputSize.depth)
  };
}

@end

NS_ASSUME_NONNULL_END

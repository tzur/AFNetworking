// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKArithmetic.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKArithmetic ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Operation to be executed by the kernel.
@property (readonly, nonatomic) pnk::ArithmeticOperation operation;

/// Kernel state to encode single texture addition.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingle;

/// Kernel state to encode texture array addition.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArray;

@end

@implementation PNKArithmetic

@synthesize primaryInputFeatureChannels = _primaryInputFeatureChannels;
@synthesize secondaryInputFeatureChannels = _secondaryInputFeatureChannels;

/// Kernel function name for a single texture.
static NSString * const kKernelSingleFunctionName = @"arithmeticSingle";

/// Kernel function name for texture array.
static NSString * const kKernelArrayFunctionName = @"arithmeticArray";

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
  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  [functionConstants setConstantValue:&_operation type:MTLDataTypeUShort withName:@"operation"];

  _stateSingle = PNKCreateComputeStateWithConstants(self.device, kKernelSingleFunctionName,
                                                    functionConstants);
  _stateArray = PNKCreateComputeStateWithConstants(self.device, kKernelArrayFunctionName,
                                                   functionConstants);
}

#pragma mark -
#pragma mark PNKBinaryKernel
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

  NSArray<MPSImage *> *inputImages = @[primaryInputImage, secondaryInputImage];
  NSArray<MPSImage *> *outputImages = @[outputImage];

  MTLSize workingSpaceSize = outputImage.pnk_textureArraySize;

  auto state = outputImage.pnk_isSingleTexture ? self.stateSingle : self.stateArray;

  PNKComputeDispatchWithDefaultThreads(state, commandBuffer, inputImages, outputImages,
                                       kDebugGroupName, workingSpaceSize);
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
                    primaryInputSize.height == secondaryInputSize.height &&
                    primaryInputSize.depth == secondaryInputSize.depth, @"Primary and secondary "
                    "input sizes must be equal, got (%lu, %lu, %lu) and (%lu, %lu, %lu)",
                    (unsigned long)primaryInputSize.width, (unsigned long)primaryInputSize.height,
                    (unsigned long)primaryInputSize.depth, (unsigned long)secondaryInputSize.width,
                    (unsigned long)secondaryInputSize.height,
                    (unsigned long)secondaryInputSize.depth);
  return primaryInputSize;
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

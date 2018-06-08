// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKReflectionPadding.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKReflectionPadding ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode padding of a single texture.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingle;

/// Kernel state to encode padding of texture array.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArray;

/// Kernel function name.
@property (readonly, nonatomic) NSString *functionName;

/// Padding to apply.
@property (readonly, nonatomic) pnk::PaddingSize paddingSize;

@end

@implementation PNKReflectionPadding

@synthesize inputFeatureChannels = _inputFeatureChannels;

/// Kernel function name for texture.
static NSString * const kKernelSingleFunctionName = @"reflectionPaddingSingle";

/// Kernel function name for texture array.
static NSString * const kKernelArrayFunctionName = @"reflectionPaddingArray";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device
                   paddingSize:(pnk::PaddingSize)paddingSize {
  if (self = [super init]) {
    _device = device;
    _paddingSize = paddingSize;

    [self createStates];
  }
  return self;
}

- (void)createStates {
  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  short paddingLeftTop[] = {(short)self.paddingSize.left, (short)self.paddingSize.top};
  short paddingRightBottom[] = {(short)self.paddingSize.right, (short)self.paddingSize.bottom};

  [functionConstants setConstantValue:paddingLeftTop type:MTLDataTypeShort2
                             withName:@"paddingLeftTop"];
  [functionConstants setConstantValue:paddingRightBottom type:MTLDataTypeShort2
                             withName:@"paddingRightBottom"];

  _stateSingle = PNKCreateComputeStateWithConstants(self.device, kKernelSingleFunctionName,
                                                    functionConstants);
  _stateArray = PNKCreateComputeStateWithConstants(self.device, kKernelArrayFunctionName,
                                                   functionConstants);
}

#pragma mark -
#pragma mark PNKUnaryImageKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  MTLSize workingSpaceSize = outputImage.pnk_textureArraySize;

  auto state = inputImage.pnk_isSingleTexture ? self.stateSingle : self.stateArray;
  PNKComputeDispatchWithDefaultThreads(state, commandBuffer, @[inputImage], @[outputImage],
                                       self.functionName, workingSpaceSize);
}

- (void)verifyParametersWithInputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.featureChannels == outputImage.featureChannels, @"Input image "
                    "featureChannels must match output image featureChannels, got: (%lu, %lu)",
                    (unsigned long)inputImage.featureChannels,
                    (unsigned long)outputImage.featureChannels);
  LTParameterAssert(inputImage.width > self.paddingSize.left,
                    @"Input image width must be larger than left padding, got: (%lu, %lu)",
                    (unsigned long)inputImage.width, (unsigned long)self.paddingSize.left);
  LTParameterAssert(inputImage.width > self.paddingSize.right,
                    @"Input image width must be larger than right padding, got: (%lu, %lu)",
                    (unsigned long)inputImage.width, (unsigned long)self.paddingSize.right);
  LTParameterAssert(inputImage.height > self.paddingSize.top,
                    @"Input image height must be larger than top padding, got: (%lu, %lu)",
                    (unsigned long)inputImage.height, (unsigned long)self.paddingSize.top);
  LTParameterAssert(inputImage.height > self.paddingSize.bottom,
                    @"Input image height must be larger than bottom padding, got: (%lu, %lu)",
                    (unsigned long)inputImage.height, (unsigned long)self.paddingSize.bottom);
  LTParameterAssert(outputImage.width == inputImage.width + self.paddingSize.left +
                    self.paddingSize.right, @"Output image width must equal the sum of input "
                    "image width with left and right padding, got: (%lu, %lu)",
                    (unsigned long)outputImage.width,
                    (unsigned long)(inputImage.width + self.paddingSize.left +
                                    self.paddingSize.right));
  LTParameterAssert(outputImage.height == inputImage.height + self.paddingSize.top +
                    self.paddingSize.bottom, @"Output image height must equal the sum of input "
                    "image height with top and right padding, got: (%lu, %lu)",
                    (unsigned long)outputImage.height,
                    (unsigned long)(inputImage.height + self.paddingSize.bottom +
                                    self.paddingSize.bottom));
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = {
      outputSize.width - self.paddingSize.left - self.paddingSize.right,
      outputSize.height - self.paddingSize.top - self.paddingSize.bottom,
      outputSize.depth
    }
  };
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return {
    inputSize.width + self.paddingSize.left + self.paddingSize.right,
    inputSize.height + self.paddingSize.top + self.paddingSize.bottom,
    inputSize.depth
  };
}

@end

#endif

NS_ASSUME_NONNULL_END

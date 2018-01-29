// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKReflectionPadding.h"

#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"
#import "PNKPaddingSize.h"

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
                 inputTexture:(id<MTLTexture>)inputTexture
                outputTexture:(id<MTLTexture>)outputTexture {
  [self verifyParametersWithInputTexture:inputTexture outputTexture:outputTexture];

  NSArray<id<MTLTexture>> *textures = @[
    inputTexture,
    outputTexture
  ];

  MTLSize workingSpaceSize = {outputTexture.width, outputTexture.height, outputTexture.arrayLength};

  auto state = (inputTexture.arrayLength <= 1) ? self.stateSingle : self.stateArray;
  PNKComputeDispatchWithDefaultThreads(state, commandBuffer, @[], textures, self.functionName,
                                       workingSpaceSize);
}

- (void)verifyParametersWithInputTexture:(id<MTLTexture>)inputTexture
                           outputTexture:(id<MTLTexture>)outputTexture {
  LTParameterAssert(inputTexture.arrayLength == outputTexture.arrayLength, @"Input texture "
                    "arrayLength must match output texture arrayLength, got: (%lu, %lu)",
                    (unsigned long)inputTexture.arrayLength,
                    (unsigned long)outputTexture.arrayLength);
  LTParameterAssert(inputTexture.width > self.paddingSize.left,
                    @"Input texture width must be larger than left padding, got: (%lu, %lu)",
                    (unsigned long)inputTexture.width, (unsigned long)self.paddingSize.left);
  LTParameterAssert(inputTexture.width > self.paddingSize.right,
                    @"Input texture width must be larger than right padding, got: (%lu, %lu)",
                    (unsigned long)inputTexture.width, (unsigned long)self.paddingSize.right);
  LTParameterAssert(inputTexture.height > self.paddingSize.top,
                    @"Input texture height must be larger than top padding, got: (%lu, %lu)",
                    (unsigned long)inputTexture.height, (unsigned long)self.paddingSize.top);
  LTParameterAssert(inputTexture.height > self.paddingSize.bottom,
                    @"Input texture height must be larger than bottom padding, got: (%lu, %lu)",
                    (unsigned long)inputTexture.height, (unsigned long)self.paddingSize.bottom);
  LTParameterAssert(outputTexture.width == inputTexture.width + self.paddingSize.left +
                    self.paddingSize.right, @"Output texture width must equal the sum of input "
                    "texture width with left and right padding, got: (%lu, %lu)",
                    (unsigned long)outputTexture.width,
                    (unsigned long)(inputTexture.width + self.paddingSize.left +
                                    self.paddingSize.right));
  LTParameterAssert(outputTexture.height == inputTexture.height + self.paddingSize.top +
                    self.paddingSize.bottom, @"Output texture height must equal the sum of input "
                    "texture height with top and right padding, got: (%lu, %lu)",
                    (unsigned long)outputTexture.height,
                    (unsigned long)(inputTexture.height + self.paddingSize.bottom +
                                    self.paddingSize.bottom));
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.featureChannels == outputImage.featureChannels, @"Input image "
                    "featureChannels must match output image featureChannels, got: (%lu, %lu)",
                    (unsigned long)inputImage.featureChannels,
                    (unsigned long)outputImage.featureChannels);
  [self encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                outputTexture:outputImage.texture];

  if ([inputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *)inputImage).readCount -= 1;
  }
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

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

/// Kernel compiled states to encode.
@property (readonly, nonatomic) NSDictionary<NSString *, id<MTLComputePipelineState>> *states;

@end

@implementation PNKAddition

/// Single input function key.
static NSString * const kFunctionKey = @"FunctionKey";

/// Multiple input function key.
static NSString * const kArrayFunctionKey = @"ArrayFunctionKey";

/// Kernel function name for texture.
static NSString * const kKernelFunctionName = @"addition";

/// Kernel function name for texture array.
static NSString * const kKernelArrayFunctionName = @"additionArray";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  if (self = [super init]) {
    _device = device;

    [self compileStates];
  }
  return self;
}

- (void)compileStates {
  auto state = PNKCreateComputeState(self.device, kKernelFunctionName);
  auto stateArray = PNKCreateComputeState(self.device, kKernelArrayFunctionName);

  _states = @{
    kFunctionKey: state,
    kArrayFunctionKey: stateArray
  };
}

#pragma mark -
#pragma mark PNKBinaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
          primaryInputTexture:(id<MTLTexture>)primaryInputTexture
        secondaryInputTexture:(id<MTLTexture>)secondaryInputTexture
                outputTexture:(id<MTLTexture>)outputTexture {
  [self verifyParametersWithPrimaryInputTexture:primaryInputTexture
                          secondaryInputTexture:secondaryInputTexture outputTexture:outputTexture];

  NSArray<id<MTLTexture>> *textures = @[
    primaryInputTexture,
    secondaryInputTexture,
    outputTexture
  ];
  auto state = (primaryInputTexture.arrayLength > 1) ? self.states[kArrayFunctionKey] :
      self.states[kFunctionKey];
  auto functionName = (primaryInputTexture.arrayLength > 1) ? kKernelArrayFunctionName :
      kKernelFunctionName;
  MTLSize workingSpaceSize = {outputTexture.width, outputTexture.height, outputTexture.arrayLength};

  PNKComputeDispatchWithDefaultThreads(state, commandBuffer, @[], textures, functionName,
                                       workingSpaceSize);
}

- (void)verifyParametersWithPrimaryInputTexture:(id<MTLTexture>)primaryInputTexture
                          secondaryInputTexture:(id<MTLTexture>)secondaryInputTexture
                                  outputTexture:(id<MTLTexture>)outputTexture {
  LTParameterAssert(primaryInputTexture.width == secondaryInputTexture.width, @"Primary input "
                    "texture width must match secondary input texture width. got: (%lu, %lu)",
                    (unsigned long)primaryInputTexture.width,
                    (unsigned long)secondaryInputTexture.width);
  LTParameterAssert(primaryInputTexture.height == secondaryInputTexture.height, @"Primary input "
                    "texture height must match secondary input texture height. got: (%lu, %lu)",
                    (unsigned long)primaryInputTexture.height,
                    (unsigned long)secondaryInputTexture.height);
  LTParameterAssert(primaryInputTexture.width == outputTexture.width,
                    @"Primary input texture width must match output texture width. got: (%lu, %lu)",
                    (unsigned long)primaryInputTexture.width, (unsigned long)outputTexture.width);
  LTParameterAssert(primaryInputTexture.height == outputTexture.height, @"Primary input texture "
                    "height must match output texture height. got: (%lu, %lu)",
                    (unsigned long)primaryInputTexture.height, (unsigned long)outputTexture.height);
  LTParameterAssert(primaryInputTexture.arrayLength == secondaryInputTexture.arrayLength,
                    @"Primary input texture arrayLength must match secondary input texture "
                    "arrayLength. got: (%lu, %lu)", (unsigned long)primaryInputTexture.arrayLength,
                    (unsigned long)secondaryInputTexture.arrayLength);
  LTParameterAssert(primaryInputTexture.arrayLength == outputTexture.arrayLength, @"Primary input "
                    "texture arrayLength must match output texture arrayLength. got: (%lu, %lu)",
                    (unsigned long)primaryInputTexture.arrayLength,
                    (unsigned long)outputTexture.arrayLength);
}

- (MTLSize)outputSizeForPrimaryInputSize:(MTLSize)primaryInputSize
                   forSecondaryInputSize:(MTLSize __unused)secondaryInputSize {
  return primaryInputSize;
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

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

/// Kernel state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

/// Kernel function name.
@property (readonly, nonatomic) NSString *functionName;

@end

@implementation PNKAddition

@synthesize isInputTextureArray = _isInputTextureArray;

/// Kernel function name for texture.
static NSString * const kKernelFunctionName = @"addition";

/// Kernel function name for texture array.
static NSString * const kKernelArrayFunctionName = @"additionArray";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device withInputIsArray:(BOOL)inputIsArray {
  if (self = [super init]) {
    _device = device;
    _isInputTextureArray = inputIsArray;

    [self createState];
  }
  return self;
}

- (void)createState {
  _state = self.isInputTextureArray ?
      PNKCreateComputeState(self.device, kKernelArrayFunctionName) :
      PNKCreateComputeState(self.device, kKernelFunctionName);
  _functionName = self.isInputTextureArray ? kKernelArrayFunctionName : kKernelFunctionName;
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
  MTLSize workingSpaceSize = {outputTexture.width, outputTexture.height, outputTexture.arrayLength};

  PNKComputeDispatchWithDefaultThreads(self.state, commandBuffer, @[], textures, self.functionName,
                                       workingSpaceSize);
}

- (void)verifyParametersWithPrimaryInputTexture:(id<MTLTexture>)primaryInputTexture
                          secondaryInputTexture:(id<MTLTexture>)secondaryInputTexture
                                  outputTexture:(id<MTLTexture>)outputTexture {
  LTParameterAssert(primaryInputTexture.arrayLength == secondaryInputTexture.arrayLength,
                    @"Primary input texture arrayLength must match secondary input texture "
                    "arrayLength. got: (%lu, %lu)", (unsigned long)primaryInputTexture.arrayLength,
                    (unsigned long)secondaryInputTexture.arrayLength);
  LTParameterAssert(primaryInputTexture.arrayLength == outputTexture.arrayLength, @"Primary input "
                    "texture arrayLength must match output texture arrayLength. got: (%lu, %lu)",
                    (unsigned long)primaryInputTexture.arrayLength,
                    (unsigned long)outputTexture.arrayLength);
  LTParameterAssert((self.isInputTextureArray && primaryInputTexture.arrayLength > 1) ||
                    (!self.isInputTextureArray && primaryInputTexture.arrayLength == 1), @"Input "
                    "textures array type must be %@, got: %@)", @(self.isInputTextureArray),
                    @(primaryInputTexture.arrayLength > 1));
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

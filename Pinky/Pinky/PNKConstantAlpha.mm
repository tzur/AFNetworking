// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKConstantAlpha.h"

#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"

NS_ASSUME_NONNULL_BEGIN

/// MTLFunctionConstantValues is not supported in simulator for Xcode 8. Solved in Xcode 9.
#if PNK_USE_MPS

@interface PNKConstantAlpha ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel compiled state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

@end

@implementation PNKConstantAlpha

@synthesize isInputArray = _isInputArray;

/// Kernel function name.
static NSString * const kKernelFunctionName = @"setConstantAlpha";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device alpha:(float)alpha {
  if (self = [super init]) {
    _device = device;
    _isInputArray = NO;

    [self createStateWithAlpha:alpha];
  }
  return self;
}

- (void)createStateWithAlpha:(float)alpha {
  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  [functionConstants setConstantValue:&alpha type:MTLDataTypeFloat withName:@"alpha"];
  _state = PNKCreateComputeStateWithConstants(self.device, kKernelFunctionName, functionConstants);
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 inputTexture:(id<MTLTexture>)inputTexture
                outputTexture:(id<MTLTexture>)outputTexture {
  [self verifyParametersWithInputTexture:inputTexture outputTexture:outputTexture];

  MTLSize workingSpaceSize = {inputTexture.width, inputTexture.height, inputTexture.arrayLength};
  PNKComputeDispatchWithDefaultThreads(self.state, commandBuffer, @[],
                                       @[inputTexture, outputTexture], kKernelFunctionName,
                                       workingSpaceSize);
}

- (void)verifyParametersWithInputTexture:(id<MTLTexture>)inputTexture
                           outputTexture:(id<MTLTexture>)outputTexture {
  LTParameterAssert(inputTexture.textureType == MTLTextureType2D,
                    @"Input texture type must be 2D, got: %lu",
                    (unsigned long)inputTexture.textureType);
  LTParameterAssert(outputTexture.textureType == MTLTextureType2D,
                    @"Output texture type must be 2D, got: %lu",
                    (unsigned long)outputTexture.textureType);

  LTParameterAssert(inputTexture.width == outputTexture.width,
                    @"Input texture width must match output texture width. got: (%lu, %lu)",
                    (unsigned long)inputTexture.width, (unsigned long)outputTexture.width);
  LTParameterAssert(inputTexture.height == outputTexture.height,
                    @"Input texture height must match output texture height. got: (%lu, %lu)",
                    (unsigned long)inputTexture.height, (unsigned long)outputTexture.height);
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self encodeToCommandBuffer:commandBuffer inputTexture:inputImage.texture
                outputTexture:outputImage.texture];
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = outputSize
  };
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

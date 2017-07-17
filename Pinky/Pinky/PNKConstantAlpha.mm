// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKConstantAlpha.h"

#import "PNKComputeDispatch.h"
#import "PNKLibraryLoader.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKConstantAlpha ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel compiled state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

/// Alpha value to set in the Alpha channel.
@property (readonly, nonatomic) float alpha;

@end

@implementation PNKConstantAlpha

/// Kernel function name.
static NSString * const kKernelFunctionName = @"setConstantAlpha";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device alpha:(float)alpha {
  if (self = [super init]) {
    _device = device;
    _alpha = alpha;

    [self compileStateWithAlpha:alpha];
  }
  return self;
}

- (void)compileStateWithAlpha:(float)alpha {
  auto library = PNKLoadLibrary(self.device);
  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  [functionConstants setConstantValue:&alpha type:MTLDataTypeFloat withName:@"alpha"];
  NSError *error;
  auto function = [library newFunctionWithName:kKernelFunctionName constantValues:functionConstants
                                         error:&error];
  LTAssert(function, @"Can't create function with name %@. Got error %@", kKernelFunctionName,
           error);
  auto state = [self.device newComputePipelineStateWithFunction:function error:&error];
  LTAssert(state, @"Can't create compute pipeline state for function %@. Got error %@",
           function.name, error);
  _state = state;
}

#pragma mark -
#pragma mark PNKUnaryEncodableKernel
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
                    @"inputTexture type must be 2D, got: %lu",
                    (unsigned long)inputTexture.textureType);
  LTParameterAssert(outputTexture.textureType == MTLTextureType2D,
                    @"outputTexture type must be 2D, got: %lu",
                    (unsigned long)outputTexture.textureType);

  LTParameterAssert(inputTexture.width == outputTexture.width,
                    @"Input texture width must match output texture width. got: (%lu, %lu)",
                    (unsigned long)inputTexture.width, (unsigned long)outputTexture.width);
  LTParameterAssert(inputTexture.height == outputTexture.height,
                    @"Input texture height must match output texture height. got: (%lu, %lu)",
                    (unsigned long)inputTexture.height, (unsigned long)outputTexture.height);
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return inputSize;
}

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKNearestNeighborUpsampling.h"

#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"

NS_ASSUME_NONNULL_BEGIN

/// MTLFunctionConstantValues is not supported in simulator for Xcode 8. Solved in Xcode 9.
#if PNK_USE_MPS

@interface PNKNearestNeighborUpsampling ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

/// Kernel function name.
@property (readonly, nonatomic) NSString *functionName;

@end

@implementation PNKNearestNeighborUpsampling

@synthesize isInputTextureArray = _isInputTextureArray;

/// Texture input kernel function name.
static NSString * const kKernelFunctionName = @"nearestNeighbor";

/// Texture array input function kernel function name.
static NSString * const kKernelArrayFunctionName = @"nearestNeighborArray";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device inputIsArray:(BOOL)inputIsArray
           magnificationFactor:(NSUInteger)magnificationFactor {
  LTParameterAssert(magnificationFactor > 1, @"Magnification factor should be larger than 1, got: "
                    "%lu", (unsigned long)magnificationFactor);
  if (self = [super init]) {
    _device = device;
    _isInputTextureArray = inputIsArray;
    _magnificationFactor = magnificationFactor;

    [self createState];
  }
  return self;
}

- (void)createState {
  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  unsigned short factor = (unsigned short)self.magnificationFactor;
  [functionConstants setConstantValue:&factor type:MTLDataTypeUShort
                             withName:@"magnificationFactor"];

  _state = self.isInputTextureArray ?
      PNKCreateComputeStateWithConstants(self.device, kKernelArrayFunctionName, functionConstants) :
      PNKCreateComputeStateWithConstants(self.device, kKernelFunctionName, functionConstants);
  _functionName = self.isInputTextureArray ? kKernelArrayFunctionName : kKernelFunctionName;
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 inputTexture:(id<MTLTexture>)inputTexture
                outputTexture:(id<MTLTexture>)outputTexture {
  [self verifyParametersWithInputTexture:inputTexture outputTexture:outputTexture];

  MTLSize workingSpaceSize = {outputTexture.width, outputTexture.height, outputTexture.arrayLength};

  PNKComputeDispatchWithDefaultThreads(self.state, commandBuffer, @[],
                                       @[inputTexture, outputTexture], self.functionName,
                                       workingSpaceSize);
}

- (void)verifyParametersWithInputTexture:(id<MTLTexture>)inputTexture
                           outputTexture:(id<MTLTexture>)outputTexture {
  LTParameterAssert(inputTexture.arrayLength == outputTexture.arrayLength,
                    @"Input texture arrayLength must match output texture arrayLength, got: "
                    "(%lu, %lu)", (unsigned long)inputTexture.arrayLength,
                    (unsigned long)outputTexture.arrayLength);
  LTParameterAssert((self.isInputTextureArray && inputTexture.arrayLength > 1) ||
                    (!self.isInputTextureArray && inputTexture.arrayLength == 1), @"Input textures "
                    "array type must be %@, got: %@", @(self.isInputTextureArray),
                    @(inputTexture.arrayLength > 1));
  LTParameterAssert(inputTexture.width * self.magnificationFactor == outputTexture.width,
                    @"Input texture width after upsampling must match output texture width, "
                    "got: (%lu, %lu)", (unsigned long)inputTexture.width * self.magnificationFactor,
                    (unsigned long)outputTexture.width);
  LTParameterAssert(inputTexture.height * self.magnificationFactor == outputTexture.height,
                    @"Input texture height after upsampling must match output texture height, "
                    "got: (%lu, %lu)", (unsigned long)inputTexture.height *
                    self.magnificationFactor, (unsigned long)outputTexture.height);
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = {
      outputSize.width / self.magnificationFactor,
      outputSize.height / self.magnificationFactor,
      outputSize.depth
    }
  };
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

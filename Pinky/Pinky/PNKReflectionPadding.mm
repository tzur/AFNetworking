// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKReflectionPadding.h"

#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKReflectionPadding ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

/// Kernel function name.
@property (readonly, nonatomic) NSString *functionName;

@end

@implementation PNKReflectionPadding

@synthesize isInputArray = _isInputArray;

/// Kernel function name for texture.
static NSString * const kKernelFunctionName = @"reflectionPadding";

/// Kernel function name for texture array.
static NSString * const kKernelArrayFunctionName = @"reflectionPaddingArray";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device inputIsArray:(BOOL)inputIsArray
                   paddingSize:(pnk::SymmetricPadding)padding {
  if (self = [super init]) {
    _device = device;
    _isInputArray = inputIsArray;
    _padding = padding;

    [self createState];
  }
  return self;
}

- (void)createState {
  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  unsigned short paddingSize[2] = {
    (unsigned short)self.padding.width,
    (unsigned short)self.padding.height
  };
  [functionConstants setConstantValue:&paddingSize type:MTLDataTypeUShort2 withName:@"paddingSize"];

  _state = self.isInputArray ?
      PNKCreateComputeStateWithConstants(self.device, kKernelArrayFunctionName, functionConstants) :
      PNKCreateComputeStateWithConstants(self.device, kKernelFunctionName, functionConstants);
  _functionName = self.isInputArray ? kKernelArrayFunctionName : kKernelFunctionName;
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

  PNKComputeDispatchWithDefaultThreads(self.state, commandBuffer, @[], textures, self.functionName,
                                       workingSpaceSize);
}

- (void)verifyParametersWithInputTexture:(id<MTLTexture>)inputTexture
                           outputTexture:(id<MTLTexture>)outputTexture {
  LTParameterAssert(inputTexture.arrayLength == outputTexture.arrayLength, @"Input texture "
                    "arrayLength must match output texture arrayLength, got: (%lu, %lu)",
                    (unsigned long)inputTexture.arrayLength,
                    (unsigned long)outputTexture.arrayLength);
  LTParameterAssert((self.isInputArray && inputTexture.arrayLength > 1) ||
                    (!self.isInputArray && inputTexture.arrayLength == 1), @"Input textures "
                    "array type must be %@, got: %@)", @(self.isInputArray),
                    @(inputTexture.arrayLength > 1));
  LTParameterAssert(inputTexture.width > self.padding.width,
                    @"Input texture width must be larger than padding width, got: (%lu, %lu)",
                    (unsigned long)inputTexture.width, (unsigned long)self.padding.width);
  LTParameterAssert(inputTexture.height > self.padding.height,
                    @"Input texture height must be larger than padding height, got: (%lu, %lu)",
                    (unsigned long)inputTexture.height, (unsigned long)self.padding.height);
  LTParameterAssert(outputTexture.width == inputTexture.width + self.padding.width * 2,
                    @"Output texture width must be that of twice the width padding added to the "
                    "input texture width, got: (%lu, %lu)", (unsigned long)outputTexture.width,
                    (unsigned long)(inputTexture.width + self.padding.width * 2));
  LTParameterAssert(outputTexture.height == inputTexture.height + self.padding.height * 2,
                    @"Output texture height must be that of twice the height padding added to the "
                    "input texture height, got: (%lu, %lu)", (unsigned long)outputTexture.height,
                    (unsigned long)(inputTexture.height + self.padding.height * 2));
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
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
      outputSize.width - self.padding.width * 2,
      outputSize.height - self.padding.height * 2,
      outputSize.depth
    }
  };
}

@end

#endif

NS_ASSUME_NONNULL_END

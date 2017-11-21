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

@synthesize primaryInputFeatureChannels = _primaryInputFeatureChannels;
@synthesize secondaryInputFeatureChannels = _secondaryInputFeatureChannels;

/// Kernel function name for texture.
static NSString * const kKernelFunctionName = @"addition";

/// Kernel function name for texture array.
static NSString * const kKernelArrayFunctionName = @"additionArray";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device
          inputFeatureChannels:(NSUInteger)inputFeatureChannels {
  if (self = [super init]) {
    _device = device;
    _primaryInputFeatureChannels = inputFeatureChannels;
    _secondaryInputFeatureChannels = inputFeatureChannels;

    [self createState];
  }
  return self;
}

- (void)createState {
  _functionName = self.primaryInputFeatureChannels > 4 ?
      kKernelArrayFunctionName : kKernelFunctionName;
  _state = PNKCreateComputeState(self.device, self.functionName);
}

#pragma mark -
#pragma mark PNKBinaryImageKernel
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
  LTParameterAssert(primaryInputTexture.arrayLength ==
                    (self.primaryInputFeatureChannels - 1) / 4 + 1,
                    @"Input textures arrayLength must be %lu, got: %lu)",
                    (unsigned long)((self.primaryInputFeatureChannels - 1) / 4 + 1),
                    (unsigned long)primaryInputTexture.arrayLength);
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

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(MPSImage *)secondaryInputImage outputImage:(MPSImage *)outputImage {
  [self encodeToCommandBuffer:commandBuffer primaryInputTexture:primaryInputImage.texture
        secondaryInputTexture:secondaryInputImage.texture outputTexture:outputImage.texture];

  if ([primaryInputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *)primaryInputImage).readCount -= 1;
  }
  if ([secondaryInputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *)secondaryInputImage).readCount -= 1;
  }
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

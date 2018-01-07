// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKConcatenation.h"

#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"
#import "PNKOpenCVExtensions.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKConcatenation ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode concatenating 2 single textures into a single texture.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingleAndSingleToSingle;

/// Kernel state to encode concatenating 2 single textures into an array of textures.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingleAndSingleToArray;

/// Kernel state to encode concatenating a single texture and an array of textures into an array of
/// textures.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingleAndArrayToArray;

/// Kernel state to encode concatenating an array of textures and a single texture into an array of
/// textures.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArrayAndSingleToArray;

/// Kernel state to encode concatenating 2 arrays of textures into an array of textures.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArrayAndArrayToArray;

/// Buffer for passing the input feature channel counts to the kernel.
@property (readonly, nonatomic) id<MTLBuffer> bufferForFeatureChannelCounts;

@end

@implementation PNKConcatenation

/// Name of kernel function for concatenating 2 single textures into a single texture.
static NSString * const kKernelFunctionSingleAndSingleToSingle = @"concatSingleAndSingleToSingle";

/// Name of kernel function for concatenating 2 single textures into an array of textures.
static NSString * const kKernelFunctionSingleAndSingleToArray = @"concatSingleAndSingleToArray";

/// Name of kernel function for concatenating a single texture and an array of textures into an
/// array of textures.
static NSString * const kKernelFunctionSingleAndArrayToArray = @"concatSingleAndArrayToArray";

/// Name of kernel function for concatenating an array of textures and a single texture into an
/// array of textures.
static NSString * const kKernelFunctionArrayAndSingleToArray = @"concatArrayAndSingleToArray";

/// Name of kernel function for concatenating 2 arrays of textures into an array of textures.
static NSString * const kKernelFunctionArrayAndArrayToArray = @"concatArrayAndArrayToArray";

/// Family name of the kernel functions for debug purposes.
static NSString * const kDebugGroupName = @"concat";

/// Number of channels in each texture in array.
static NSUInteger kChannelsPerTexture = 4;

@synthesize primaryInputFeatureChannels = _primaryInputFeatureChannels;
@synthesize secondaryInputFeatureChannels = _secondaryInputFeatureChannels;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  if (self = [super init]) {
    _device = device;
    [self createStates];
    [self createBuffers];
  }
  return self;
}

- (void)createStates {
  _stateSingleAndSingleToSingle = PNKCreateComputeState(self.device,
                                                        kKernelFunctionSingleAndSingleToSingle);
  _stateSingleAndSingleToArray = PNKCreateComputeState(self.device,
                                                        kKernelFunctionSingleAndSingleToArray);
  _stateSingleAndArrayToArray = PNKCreateComputeState(self.device,
                                                      kKernelFunctionSingleAndArrayToArray);
  _stateArrayAndSingleToArray = PNKCreateComputeState(self.device,
                                                      kKernelFunctionArrayAndSingleToArray);
  _stateArrayAndArrayToArray = PNKCreateComputeState(self.device,
                                                     kKernelFunctionArrayAndArrayToArray);
}

- (void)createBuffers {
  NSUInteger length = 2 * sizeof(ushort);
  _bufferForFeatureChannelCounts =
      [self.device newBufferWithLength:length options:MTLResourceCPUCacheModeWriteCombined];
}

#pragma mark -
#pragma mark PNKBinaryImageKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
          primaryInputTexture:(id<MTLTexture>)primaryInputTexture
        secondaryInputTexture:(id<MTLTexture>)secondaryInputTexture
                outputTexture:(id<MTLTexture>)outputTexture {
  [self encodeToCommandBuffer:commandBuffer primaryInputTexture:primaryInputTexture
  primaryInputFeatureChannels:PNKChannelCountForTexture(primaryInputTexture)
        secondaryInputTexture:secondaryInputTexture
secondaryInputFeatureChannels:PNKChannelCountForTexture(secondaryInputTexture)
                outputTexture:outputTexture];
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(MPSImage *)secondaryInputImage outputImage:(MPSImage *)outputImage {
  [self encodeToCommandBuffer:commandBuffer primaryInputTexture:primaryInputImage.texture
  primaryInputFeatureChannels:primaryInputImage.featureChannels
        secondaryInputTexture:secondaryInputImage.texture
secondaryInputFeatureChannels:secondaryInputImage.featureChannels
                outputTexture:outputImage.texture];

  if ([primaryInputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *)primaryInputImage).readCount -= 1;
  }
  if ([secondaryInputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *)secondaryInputImage).readCount -= 1;
  }
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
          primaryInputTexture:(id<MTLTexture>)primaryInputTexture
  primaryInputFeatureChannels:(NSUInteger)primaryInputFeatureChannels
        secondaryInputTexture:(id<MTLTexture>)secondaryInputTexture
secondaryInputFeatureChannels:(NSUInteger)secondaryInputFeatureChannels
                outputTexture:(id<MTLTexture>)outputTexture {
  [self verifyParametersWithPrimaryInputTexture:primaryInputTexture
                          secondaryInputTexture:secondaryInputTexture outputTexture:outputTexture];

  [self fillBuffer:self.bufferForFeatureChannelCounts withFirst:primaryInputFeatureChannels
            second:secondaryInputFeatureChannels];
  NSArray<id<MTLBuffer>> *buffers = @[self.bufferForFeatureChannelCounts];

  NSArray<id<MTLTexture>> *textures = @[
    primaryInputTexture,
    secondaryInputTexture,
    outputTexture
  ];

  id<MTLComputePipelineState> state;
  if (primaryInputFeatureChannels <= kChannelsPerTexture) {
    if (secondaryInputFeatureChannels <= kChannelsPerTexture) {
      if (primaryInputFeatureChannels + secondaryInputFeatureChannels <= kChannelsPerTexture) {
        state = self.stateSingleAndSingleToSingle;
      } else {
        state = self.stateSingleAndSingleToArray;
      }
    } else {
      state = self.stateSingleAndArrayToArray;
    }
  } else {
    if (secondaryInputFeatureChannels <= kChannelsPerTexture) {
      state = self.stateArrayAndSingleToArray;
    } else {
      state = self.stateArrayAndArrayToArray;
    }
  }

  MTLSize workingSpaceSize = {outputTexture.width, outputTexture.height, 1};

  PNKComputeDispatchWithDefaultThreads(state, commandBuffer, buffers, textures, kDebugGroupName,
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
                    (unsigned long)primaryInputTexture.width,
                    (unsigned long)outputTexture.width);
  LTParameterAssert(primaryInputTexture.height == outputTexture.height, @"Primary input texture "
                    "height must match output texture height. got: (%lu, %lu)",
                    (unsigned long)primaryInputTexture.height,
                    (unsigned long)outputTexture.height);
}

- (void)fillBuffer:(id<MTLBuffer>)buffer withFirst:(NSUInteger)first second:(NSUInteger)second {
  ushort value[] = {(ushort)first, (ushort)second};
  memcpy(buffer.contents, &value, sizeof(value));
}

- (MTLRegion)primaryInputRegionForOutputSize:(MTLSize)outputSize {
  return [self inputRegionForOutputSize:outputSize];
}

- (MTLRegion)secondaryInputRegionForOutputSize:(MTLSize)outputSize {
  return [self inputRegionForOutputSize:outputSize];
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = outputSize
  };
}

- (MTLSize)outputSizeForPrimaryInputSize:(MTLSize)primaryInputSize
                      secondaryInputSize:(MTLSize)secondaryInputSize {
  return {
    .width = primaryInputSize.width,
    .height = primaryInputSize.height,
    .depth = primaryInputSize.depth + secondaryInputSize.depth
  };
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

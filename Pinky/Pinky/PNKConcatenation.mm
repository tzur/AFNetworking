// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKConcatenation.h"

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
#pragma mark PNKBinaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(MPSImage *)secondaryInputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithPrimaryInputImage:primaryInputImage
                          secondaryInputImage:secondaryInputImage outputImage:outputImage];

  [self fillBuffer:self.bufferForFeatureChannelCounts withFirst:primaryInputImage.featureChannels
            second:secondaryInputImage.featureChannels];
  NSArray<id<MTLBuffer>> *buffers = @[self.bufferForFeatureChannelCounts];

  NSArray<MPSImage *> *inputImages = @[primaryInputImage, secondaryInputImage];
  NSArray<MPSImage *> *outputImages = @[outputImage];

  id<MTLComputePipelineState> state;
  if (primaryInputImage.pnk_isSingleTexture) {
    if (secondaryInputImage.pnk_isSingleTexture) {
      if (outputImage.pnk_isSingleTexture) {
        state = self.stateSingleAndSingleToSingle;
      } else {
        state = self.stateSingleAndSingleToArray;
      }
    } else {
      state = self.stateSingleAndArrayToArray;
    }
  } else {
    if (secondaryInputImage.pnk_isSingleTexture) {
      state = self.stateArrayAndSingleToArray;
    } else {
      state = self.stateArrayAndArrayToArray;
    }
  }

  MTLSize workingSpaceSize = {outputImage.width, outputImage.height, 1};

  MTBComputeDispatchWithDefaultThreads(state, commandBuffer, buffers, inputImages, outputImages,
                                       kDebugGroupName, workingSpaceSize);
}

- (void)verifyParametersWithPrimaryInputImage:(MPSImage *)primaryInputImage
                          secondaryInputImage:(MPSImage *)secondaryInputImage
                                  outputImage:(MPSImage *)outputImage {
  LTParameterAssert(primaryInputImage.width == secondaryInputImage.width, @"Primary input image "
                    "width must match secondary input image width. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.width,
                    (unsigned long)secondaryInputImage.width);
  LTParameterAssert(primaryInputImage.height == secondaryInputImage.height, @"Primary input image "
                    "height must match secondary input image height. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.height,
                    (unsigned long)secondaryInputImage.height);
  LTParameterAssert(primaryInputImage.width == outputImage.width,
                    @"Primary input image width must match output image width. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.width,
                    (unsigned long)outputImage.width);
  LTParameterAssert(primaryInputImage.height == outputImage.height, @"Primary input image "
                    "height must match output image height. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.height,
                    (unsigned long)outputImage.height);
  LTParameterAssert(primaryInputImage.featureChannels + secondaryInputImage.featureChannels ==
                    outputImage.featureChannels, @"The sum of feature channel counts of primary "
                    "and secondary input images should equal feature channel count of output "
                    "image. got: (%lu, %lu, %lu)",
                    (unsigned long)primaryInputImage.featureChannels,
                    (unsigned long)secondaryInputImage.featureChannels,
                    (unsigned long)outputImage.featureChannels);
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
  LTParameterAssert(primaryInputSize.width == secondaryInputSize.width &&
                    primaryInputSize.height == secondaryInputSize.height, @"Primary and secondary "
                    "inputs must have same width and height, got (%lu, %lu) and (%lu, %lu)",
                    (unsigned long)primaryInputSize.width, (unsigned long)primaryInputSize.height,
                    (unsigned long)secondaryInputSize.width,
                    (unsigned long)secondaryInputSize.height);
  return {
    .width = primaryInputSize.width,
    .height = primaryInputSize.height,
    .depth = primaryInputSize.depth + secondaryInputSize.depth
  };
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

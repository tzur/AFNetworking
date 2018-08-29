// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKArgmax.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKArgmax ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode argmax operation on a single texture when output texture has channel
/// format \c MPSImageFeatureChannelFormatUnorm8.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingleUnorm;

/// Kernel state to encode argmax operation on a single texture when output texture has channel
/// format \c MPSImageFeatureChannelFormatFloat16.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingleHalf;

/// Kernel state to encode argmax operation on a texture array when output texture has channel
/// format \c MPSImageFeatureChannelFormatUnorm8.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArrayUnorm;

/// Kernel state to encode argmax operation on a texture array when output texture has channel
/// format \c MPSImageFeatureChannelFormatFloat16.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArrayHalf;

/// Kernel function name.
@property (readonly, nonatomic) NSString *functionName;

/// Buffer for passing the input feature channel counts to the kernel.
@property (readonly, nonatomic) id<MTLBuffer> bufferForFeatureChannelCount;

@end

@implementation PNKArgmax

/// Name of kernel function for performing argmax operation on a single texture.
static NSString * const kKernelFunctionSingle = @"argmaxSingle";

/// Name of kernel function for performing argmax operation on a texture array.
static NSString * const kKernelFunctionArray = @"argmaxArray";

/// Family name of the kernel functions for debug purposes.
static NSString * const kDebugGroupName = @"argmax";

@synthesize inputFeatureChannels = _inputFeatureChannels;

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  if (self = [super init]) {
    _device = device;

    [self createStates];
    [self createBuffer];
  }
  return self;
}

- (void)createStates {
  half_float::half scaleForUnorm = (half_float::half)(1.0 / 255.0);
  auto functionConstantsForUnorm = @[[MTBFunctionConstant halfConstantWithValue:scaleForUnorm
                                                                           name:@"scale"]];

  half_float::half scaleForHalf = (half_float::half)1.0;
  auto functionConstantsForHalf = @[[MTBFunctionConstant halfConstantWithValue:scaleForHalf
                                                                          name:@"scale"]];

  _stateSingleUnorm = PNKCreateComputeState(self.device, kKernelFunctionSingle,
                                            functionConstantsForUnorm);
  _stateSingleHalf = PNKCreateComputeState(self.device, kKernelFunctionSingle,
                                           functionConstantsForHalf);
  _stateArrayUnorm = PNKCreateComputeState(self.device, kKernelFunctionArray,
                                           functionConstantsForUnorm);
  _stateArrayHalf = PNKCreateComputeState(self.device, kKernelFunctionArray,
                                          functionConstantsForHalf);
}

- (void)createBuffer {
  NSUInteger length = sizeof(ushort);
  _bufferForFeatureChannelCount =
      [self.device newBufferWithLength:length options:MTLResourceCPUCacheModeWriteCombined];
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  [self fillBufferWithFeatureChannels:inputImage.featureChannels];

  MTLSize workingSpaceSize = {outputImage.width, outputImage.height, 1};

  bool isSingle = inputImage.pnk_isSingleTexture;
  bool isUnorm = outputImage.pixelFormat == MTLPixelFormatR8Unorm;
  id<MTLComputePipelineState> state;
  if (isSingle) {
    state = isUnorm ? self.stateSingleUnorm : self.stateSingleHalf;
  } else {
    state = isUnorm ? self.stateArrayUnorm : self.stateArrayHalf;
  }

  MTBComputeDispatchWithDefaultThreads(state, commandBuffer, @[self.bufferForFeatureChannelCount],
                                       @[inputImage], @[outputImage], kDebugGroupName,
                                       workingSpaceSize);
}

- (void)verifyParametersWithInputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  LTParameterAssert(outputImage.featureChannels == 1,
                    @"Output image featureChannels must be 1, got: %lu",
                    (unsigned long)outputImage.featureChannels);
  LTParameterAssert(inputImage.featureChannels <= 256 ||
                    outputImage.pixelFormat != MTLPixelFormatR8Unorm,
                    @"Input image has more than 256 channels but output image is of Unorm8 type");
  LTParameterAssert(inputImage.width == outputImage.width,
                    @"Input image width must match output image width. got: (%lu, %lu)",
                    (unsigned long)inputImage.width, (unsigned long)outputImage.width);
  LTParameterAssert(inputImage.height == outputImage.height,
                    @"Input image height must match output image height. got: (%lu, %lu)",
                    (unsigned long)inputImage.height, (unsigned long)outputImage.height);
}

- (void)fillBufferWithFeatureChannels:(NSUInteger)featureChannels {
  *((ushort *)self.bufferForFeatureChannelCount.contents) = (ushort)featureChannels;
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = outputSize
  };
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return MTLSizeMake(inputSize.width, inputSize.height, 1);
}

@end

#endif

NS_ASSUME_NONNULL_END

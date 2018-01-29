// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKCrop.h"

#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"
#import "PNKPaddingSize.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKCrop ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode cropping a single texture.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingle;

/// Kernel state to encode cropping texture array.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArray;

/// Margins to be cropped out.
@property (readonly, nonatomic) pnk::PaddingSize margins;

@end

@implementation PNKCrop

/// Name of kernel function for cropping a single texture.
static NSString * const kKernelSingleFunctionName = @"cropSingle";

/// Name of kernel function for cropping an array of textures.
static NSString * const kKernelArrayFunctionName = @"cropArray";

/// Family name of the kernel functions for debug purposes.
static NSString * const kDebugGroupName = @"crop";

/// Number of channels in each texture in array.
static NSUInteger kChannelsPerTexture = 4;

@synthesize inputFeatureChannels = _inputFeatureChannels;

- (instancetype)initWithDevice:(id<MTLDevice>)device margins:(pnk::PaddingSize)margins {
  if (self = [super init]) {
    _device = device;
    _margins = margins;

    [self createStates];
  }
  return self;
}

- (void)createStates {
  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  ushort marginsLeftTop[] = {(ushort)self.margins.left, (ushort)self.margins.top};
  [functionConstants setConstantValue:marginsLeftTop type:MTLDataTypeUShort2
                             withName:@"marginsLeftTop"];

  _stateSingle = PNKCreateComputeStateWithConstants(self.device, kKernelSingleFunctionName,
                                                    functionConstants);
  _stateArray = PNKCreateComputeStateWithConstants(self.device, kKernelArrayFunctionName,
                                                   functionConstants);
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  NSArray<id<MTLTexture>> *textures = @[inputImage.texture, outputImage.texture];
  MTLSize workingSpaceSize = {
    outputImage.width,
    outputImage.height,
    outputImage.texture.arrayLength
  };

  auto state = (inputImage.featureChannels <= kChannelsPerTexture) ?
      self.stateSingle : self.stateArray;

  PNKComputeDispatchWithDefaultThreads(state, commandBuffer, @[], textures, kDebugGroupName,
                                       workingSpaceSize);

  if ([inputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *)inputImage).readCount -= 1;
  }
}

- (void)verifyParametersWithInputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  MTLSize inputSize = {inputImage.width, inputImage.height, inputImage.featureChannels};
  MTLSize expectedOutputSize = [self outputSizeForInputSize:inputSize];

  LTParameterAssert(expectedOutputSize.depth == outputImage.featureChannels,
                    @"Output image featureChannels must equal %lu, got: %lu",
                    (unsigned long)expectedOutputSize.depth,
                    (unsigned long)outputImage.featureChannels);
  LTParameterAssert(expectedOutputSize.width == outputImage.width,
                    @"Output image width must equal %lu, got: %lu",
                    (unsigned long)expectedOutputSize.width,
                    (unsigned long)outputImage.width);
  LTParameterAssert(expectedOutputSize.height == outputImage.height,
                    @"Output image width must equal %lu, got: %lu",
                    (unsigned long)expectedOutputSize.height,
                    (unsigned long)outputImage.height);
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {{self.margins.left, self.margins.top, 0}, outputSize};
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return {
    inputSize.width - self.margins.left - self.margins.right,
    inputSize.height - self.margins.top - self.margins.bottom,
    inputSize.depth
  };
}

@end

#endif

NS_ASSUME_NONNULL_END

// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKBinaryGather.h"

#import "PNKBufferExtensions.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKBinaryGather ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

/// Kernel function name.
@property (readonly, nonatomic) NSString *functionName;

/// Buffer for passing \c primaryFeatureChannelIndices to the kernel as an array of unsigned shorts.
@property (readonly, nonatomic) id<MTLBuffer> bufferForPrimaryFeatureChannelIndices;

/// Buffer for passing \c secondaryFeatureChannelIndices to the kernel as an array of unsigned
/// shorts.
@property (readonly, nonatomic) id<MTLBuffer> bufferForSecondaryFeatureChannelIndices;

@end

@implementation PNKBinaryGather {
  /// Array of primary channel indices.
  std::vector<ushort> _primaryFeatureChannelIndices;
  /// Array of secondary channel indices.
  std::vector<ushort> _secondaryFeatureChannelIndices;
}

/// Name of kernel function for gathering channels from two single textures into a single texture.
static NSString * const kKernelSingleAndSingleToSingle = @"gatherSingleAndSingleToSingle";

/// Name of kernel function for gathering channels from two single textures into a texture array.
static NSString * const kKernelSingleAndSingleToArray = @"gatherSingleAndSingleToArray";

/// Name of kernel function for gathering channels from a single tecxture and a texture array into a
/// single texture.
static NSString * const kKernelSingleAndArrayToSingle = @"gatherSingleAndArrayToSingle";

/// Name of kernel function for gathering channels from a single tecxture and a texture array into a
/// a texture array.
static NSString * const kKernelSingleAndArrayToArray = @"gatherSingleAndArrayToArray";

/// Name of kernel function for gathering channels from a texture array and a single texture into a
/// single texture.
static NSString * const kKernelArrayAndSingleToSingle = @"gatherArrayAndSingleToSingle";

/// Name of kernel function for gathering channels from a texture array and a single texture into a
/// texture array.
static NSString * const kKernelArrayAndSingleToArray = @"gatherArrayAndSingleToArray";

/// Name of kernel function for gathering channels from two texture arrays into a single texture.
static NSString * const kKernelArrayAndArrayToSingle = @"gatherArrayAndArrayToSingle";

/// Name of kernel function for gathering channels from two texture arrays into a texture array.
static NSString * const kKernelArrayAndArrayToArray = @"gatherArrayAndArrayToArray";

/// Number of channels in each texture in array.
static NSUInteger kChannelsPerTexture = 4;

@synthesize primaryInputFeatureChannels = _primaryInputFeatureChannels;
@synthesize secondaryInputFeatureChannels = _secondaryInputFeatureChannels;

- (instancetype)initWithDevice:(id<MTLDevice>)device
   primaryInputFeatureChannels:(NSUInteger)primaryInputFeatureChannels
  primaryFeatureChannelIndices:(const std::vector<ushort> &)primaryFeatureChannelIndices
 secondaryInputFeatureChannels:(NSUInteger)secondaryInputFeatureChannels
secondaryFeatureChannelIndices:(const std::vector<ushort> &)secondaryFeatureChannelIndices {
  if (self = [super init]) {
    _device = device;
    _primaryInputFeatureChannels = primaryInputFeatureChannels;
    _primaryFeatureChannelIndices = primaryFeatureChannelIndices;
    _secondaryInputFeatureChannels = secondaryInputFeatureChannels;
    _secondaryFeatureChannelIndices = secondaryFeatureChannelIndices;

    [self validateFeatureChannelIndices];
    [self createState];
    [self createBuffers];
  }
  return self;
}

- (void)validateFeatureChannelIndices {
  for (auto channelIndex: _primaryFeatureChannelIndices) {
    LTParameterAssert(channelIndex < self.primaryInputFeatureChannels, @"Primary feature channel "
                      "index must be less than %hu - got %hu",
                      (unsigned short)self.primaryInputFeatureChannels, channelIndex);
  }
  for (auto channelIndex: _secondaryFeatureChannelIndices) {
    LTParameterAssert(channelIndex < self.secondaryInputFeatureChannels, @"Secondary feature "
                      "channel index must be less than %hu - got %hu",
                      (unsigned short)self.secondaryInputFeatureChannels, channelIndex);
  }
}

- (void)createState {
  ushort primaryFeatureChannelIndicesSize = (ushort)_primaryFeatureChannelIndices.size();
  ushort secondaryFeatureChannelIndicesSize = (ushort)_secondaryFeatureChannelIndices.size();
  ushort outputFeatureChannels = primaryFeatureChannelIndicesSize +
      secondaryFeatureChannelIndicesSize;

  if (self.primaryInputFeatureChannels <= kChannelsPerTexture) {
    if (self.secondaryInputFeatureChannels <= kChannelsPerTexture) {
      if (outputFeatureChannels <= kChannelsPerTexture) {
        _functionName = kKernelSingleAndSingleToSingle;
      } else {
        _functionName = kKernelSingleAndSingleToArray;
      }
     } else {
       if (outputFeatureChannels <= kChannelsPerTexture) {
         _functionName = kKernelSingleAndArrayToSingle;
       } else {
         _functionName = kKernelSingleAndArrayToArray;
       }
     }
  } else {
    if (self.secondaryInputFeatureChannels <= kChannelsPerTexture) {
      if (outputFeatureChannels <= kChannelsPerTexture) {
        _functionName = kKernelArrayAndSingleToSingle;
      } else {
        _functionName = kKernelArrayAndSingleToArray;
      }
    } else {
      if (outputFeatureChannels <= kChannelsPerTexture) {
        _functionName = kKernelArrayAndArrayToSingle;
      } else {
        _functionName = kKernelArrayAndArrayToArray;
      }
    }
  }

  auto functionConstants = @[
    [MTBFunctionConstant ushortConstantWithValue:primaryFeatureChannelIndicesSize
                                            name:@"primaryFeatureChannelIndicesSize"],
    [MTBFunctionConstant ushortConstantWithValue:secondaryFeatureChannelIndicesSize
                                            name:@"secondaryFeatureChannelIndicesSize"]
  ];
  _state = PNKCreateComputeState(self.device, self.functionName, functionConstants);
}

- (void)createBuffers {
  _bufferForPrimaryFeatureChannelIndices = PNKUshortBufferFromVector(self.device,
                                                                     _primaryFeatureChannelIndices);
  _bufferForSecondaryFeatureChannelIndices =
      PNKUshortBufferFromVector(self.device, _secondaryFeatureChannelIndices);
}

#pragma mark -
#pragma mark PNKBinaryKernel
#pragma mark -

- (void)verifyParametersWithPrimaryInputImage:(MPSImage *)primaryInputImage
                          secondaryInputImage:(MPSImage *)secondaryInputImage
                                  outputImage:(MPSImage *)outputImage {
  LTParameterAssert(primaryInputImage.featureChannels == self.primaryInputFeatureChannels,
                    @"Primary input image featureChannels must be %lu, got: %lu",
                    (unsigned long)self.primaryInputFeatureChannels,
                    (unsigned long)primaryInputImage.featureChannels);
  LTParameterAssert(secondaryInputImage.featureChannels == self.secondaryInputFeatureChannels,
                    @"Secondary input image featureChannels must be %lu, got: %lu",
                    (unsigned long)self.secondaryInputFeatureChannels,
                    (unsigned long)secondaryInputImage.featureChannels);
  LTParameterAssert(outputImage.featureChannels ==
                    _primaryFeatureChannelIndices.size() + _secondaryFeatureChannelIndices.size(),
                    @"Output image featureChannels must be %lu, got: %lu",
                    _primaryFeatureChannelIndices.size() + _secondaryFeatureChannelIndices.size(),
                    (unsigned long)outputImage.featureChannels);
  LTParameterAssert(primaryInputImage.width == outputImage.width,
                    @"Primary input image width must match output image width. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.width, (unsigned long)outputImage.width);
  LTParameterAssert(primaryInputImage.height == outputImage.height,
                    @"Primary input image height must match output image height. got: (%lu, %lu)",
                    (unsigned long)primaryInputImage.height, (unsigned long)outputImage.height);
  LTParameterAssert(secondaryInputImage.width == outputImage.width,
                    @"Secondary input image width must match output image width. got: (%lu, %lu)",
                    (unsigned long)secondaryInputImage.width, (unsigned long)outputImage.width);
  LTParameterAssert(secondaryInputImage.height == outputImage.height,
                    @"Secondary input image height must match output image height. got: (%lu, %lu)",
                    (unsigned long)secondaryInputImage.height, (unsigned long)outputImage.height);
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(MPSImage *)secondaryInputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithPrimaryInputImage:primaryInputImage
                          secondaryInputImage:secondaryInputImage outputImage:outputImage];

  NSArray<id<MTLBuffer>> *buffers = @[
    self.bufferForPrimaryFeatureChannelIndices,
    self.bufferForSecondaryFeatureChannelIndices
  ];

  MTLSize workingSpaceSize = {outputImage.width, outputImage.height, 1};

  MTBComputeDispatchWithDefaultThreads(self.state, commandBuffer, buffers,
                                       @[primaryInputImage, secondaryInputImage], @[outputImage],
                                       self.functionName, workingSpaceSize);
}

- (MTLRegion)primaryInputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = {outputSize.width, outputSize.height, self.primaryInputFeatureChannels}
  };
}

- (MTLRegion)secondaryInputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = {outputSize.width, outputSize.height, self.secondaryInputFeatureChannels}
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
    primaryInputSize.width,
    primaryInputSize.height,
    (NSUInteger)(_primaryFeatureChannelIndices.size() + _secondaryFeatureChannelIndices.size())
  };
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

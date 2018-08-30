// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKGather.h"

#import "PNKBufferExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKGather ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

/// Kernel function name.
@property (readonly, nonatomic) NSString *functionName;

/// Buffer for passing \c outputFeatureChannelIndices to the kernel as an array of unsigned shorts.
@property (readonly, nonatomic) id<MTLBuffer> bufferForOutputFeatureChannelIndices;

@end

@implementation PNKGather {
  /// Array of output channel indices.
  std::vector<ushort> _outputFeatureChannelIndices;
}

/// Name of kernel function for gathering channels from a single texture into a single texture.
static NSString * const kKernelFunctionSingleToSingle = @"gatherSingleToSingle";

/// Name of kernel function gathering channels from an array of textures into a single texture.
static NSString * const kKernelFunctionArrayToSingle = @"gatherArrayToSingle";

/// Name of kernel function for gathering channels from a single texture into a single texture.
static NSString * const kKernelFunctionSingleToArray = @"gatherSingleToArray";

/// Name of kernel function gathering channels from an array of textures into a single texture.
static NSString * const kKernelFunctionArrayToArray = @"gatherArrayToArray";

/// Number of channels in each texture in array.
static NSUInteger kChannelsPerTexture = 4;

@synthesize inputFeatureChannels = _inputFeatureChannels;

- (instancetype)initWithDevice:(id<MTLDevice>)device
          inputFeatureChannels:(NSUInteger)inputFeatureChannels
   outputFeatureChannelIndices:(const std::vector<ushort> &)outputFeatureChannelIndices {
  if (self = [super init]) {
    _device = device;
    _inputFeatureChannels = inputFeatureChannels;
    _outputFeatureChannelIndices = outputFeatureChannelIndices;

    [self validateFeatureChannelIndices];
    [self createState];
    [self createBuffers];
  }
  return self;
}

- (void)validateFeatureChannelIndices {
  for (auto channelIndex: _outputFeatureChannelIndices) {
    LTParameterAssert(channelIndex < self.inputFeatureChannels, @"Output feature channel index "
                      "must be less than %hu - got %hu", (unsigned short)self.inputFeatureChannels,
                      channelIndex);
  }
}

- (void)createState {
  ushort outputFeatureChannels = (ushort)_outputFeatureChannelIndices.size();

  if (outputFeatureChannels <= kChannelsPerTexture) {
    if (self.inputFeatureChannels <= kChannelsPerTexture) {
      _functionName = kKernelFunctionSingleToSingle;
    } else {
      _functionName = kKernelFunctionArrayToSingle;
    }
  } else {
    if (self.inputFeatureChannels <= kChannelsPerTexture) {
      _functionName = kKernelFunctionSingleToArray;
    } else {
      _functionName = kKernelFunctionArrayToArray;
    }
  }

  simd_ushort4 shortVectorOfIndices;
  for (ushort i = 0; i < std::min((ushort)kChannelsPerTexture, outputFeatureChannels); ++i) {
    shortVectorOfIndices[i] = _outputFeatureChannelIndices[i];
  }

  auto functionConstants = @[
    [MTBFunctionConstant ushortConstantWithValue:outputFeatureChannels
                                            name:@"outputFeatureChannels"],
    [MTBFunctionConstant ushort4ConstantWithValue:shortVectorOfIndices
                                             name:@"outputFeatureChannelsShortList"]
  ];

  _state = PNKCreateComputeState(self.device, self.functionName, functionConstants);
}

- (void)createBuffers {
  _bufferForOutputFeatureChannelIndices = PNKUshortBufferFromVector(self.device,
                                                                    _outputFeatureChannelIndices);
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  NSArray<id<MTLBuffer>> *buffers = _outputFeatureChannelIndices.size() <= kChannelsPerTexture ?
      @[] : @[self.bufferForOutputFeatureChannelIndices];

  MTLSize workingSpaceSize = {outputImage.width, outputImage.height, 1};

  MTBComputeDispatchWithDefaultThreads(self.state, commandBuffer, buffers, @[inputImage],
                                       @[outputImage], self.functionName, workingSpaceSize);
}

- (void)verifyParametersWithInputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.featureChannels == self.inputFeatureChannels,
                    @"Input image featureChannels must be %lu, got: %lu",
                    (unsigned long)self.inputFeatureChannels,
                    (unsigned long)inputImage.featureChannels);
  LTParameterAssert(outputImage.featureChannels == _outputFeatureChannelIndices.size(),
                    @"Output image featureChannels must be %lu, got: %lu",
                    _outputFeatureChannelIndices.size(),
                    (unsigned long)outputImage.featureChannels);
  LTParameterAssert(inputImage.width == outputImage.width,
                    @"Input image width must match output image width. got: (%lu, %lu)",
                    (unsigned long)inputImage.width, (unsigned long)outputImage.width);
  LTParameterAssert(inputImage.height == outputImage.height,
                    @"Input image height must match output image height. got: (%lu, %lu)",
                    (unsigned long)inputImage.height, (unsigned long)outputImage.height);
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = {
      outputSize.width,
      outputSize.height,
      self.inputFeatureChannels
    }
  };
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return {
    inputSize.width,
    inputSize.height,
    _outputFeatureChannelIndices.size()
  };
}

@end

NS_ASSUME_NONNULL_END

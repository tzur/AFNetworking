// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKGather.h"

#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

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

  vector_ushort4 shortVectorOfIndices;
  for (ushort i = 0; i < std::min((ushort)kChannelsPerTexture, outputFeatureChannels); ++i) {
    shortVectorOfIndices[i] = _outputFeatureChannelIndices[i];
  }

  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  [functionConstants setConstantValue:&outputFeatureChannels type:MTLDataTypeUShort
                             withName:@"outputFeatureChannels"];
  [functionConstants setConstantValue:&shortVectorOfIndices type:MTLDataTypeUShort4
                             withName:@"outputFeatureChannelsShortList"];
  _state = PNKCreateComputeStateWithConstants(self.device, self.functionName, functionConstants);
}

- (void)createBuffers {
  _bufferForOutputFeatureChannelIndices =
      [self.device newBufferWithLength:sizeof(ushort) * _outputFeatureChannelIndices.size()
                               options:MTLResourceCPUCacheModeWriteCombined];

  void *bufferContents = (ushort *)self.bufferForOutputFeatureChannelIndices.contents;
  memcpy(bufferContents, _outputFeatureChannelIndices.data(),
         _outputFeatureChannelIndices.size() * sizeof(ushort));
}

#pragma mark -
#pragma mark PNKBinaryImageKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 inputTexture:(id<MTLTexture>)inputTexture
                outputTexture:(id<MTLTexture>)outputTexture {
  [self verifyParametersWithInputTexture:inputTexture outputTexture:outputTexture];

  NSArray<id<MTLBuffer>> *buffers = _outputFeatureChannelIndices.size() <= kChannelsPerTexture ?
      @[] : @[self.bufferForOutputFeatureChannelIndices];

  NSArray<id<MTLTexture>> *textures = @[inputTexture, outputTexture];

  MTLSize workingSpaceSize = {outputTexture.width, outputTexture.height, 1};

  PNKComputeDispatchWithDefaultThreads(self.state, commandBuffer, buffers, textures,
                                       self.functionName, workingSpaceSize);
}

- (void)verifyParametersWithInputTexture:(id<MTLTexture>)inputTexture
                           outputTexture:(id<MTLTexture>)outputTexture {
  LTParameterAssert(inputTexture.arrayLength ==
                    (self.inputFeatureChannels - 1) / kChannelsPerTexture + 1,
                    @"Input texture arrayLength must be %lu, got: %lu",
                    (unsigned long)((self.inputFeatureChannels - 1) / kChannelsPerTexture + 1),
                    (unsigned long)inputTexture.arrayLength);
  LTParameterAssert(outputTexture.arrayLength ==
                    (_outputFeatureChannelIndices.size() - 1) / kChannelsPerTexture + 1,
                    @"Output texture arrayLength must be %lu, got: %lu",
                    (_outputFeatureChannelIndices.size() - 1) / kChannelsPerTexture + 1,
                    (unsigned long)outputTexture.arrayLength);
  LTParameterAssert(inputTexture.width == outputTexture.width,
                    @"Input texture width must match output texture width. got: (%lu, %lu)",
                    (unsigned long)inputTexture.width, (unsigned long)outputTexture.width);
  LTParameterAssert(inputTexture.height == outputTexture.height,
                    @"Input texture  height must match output texture height. got: (%lu, %lu)",
                    (unsigned long)inputTexture.height, (unsigned long)outputTexture.height);
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.featureChannels == self.inputFeatureChannels,
                    @"Input image featureChannels must be %lu, got: %lu",
                    (unsigned long)self.inputFeatureChannels,
                    (unsigned long)inputImage.featureChannels);
  LTParameterAssert(outputImage.featureChannels == _outputFeatureChannelIndices.size(),
                    @"Output image featureChannels must be %lu, got: %lu",
                    _outputFeatureChannelIndices.size(),
                    (unsigned long)outputImage.featureChannels);

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

#endif

NS_ASSUME_NONNULL_END

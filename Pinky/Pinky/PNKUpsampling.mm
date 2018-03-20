// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKUpsampling.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKUpsampling ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode single texture upsampling.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingle;

/// Kernel state to encode texture array upsampling.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArray;

/// Buffer for passing the coefficients used by Metal to calculate sampling coordinates.
@property (readonly, nonatomic) id<MTLBuffer> bufferForSamplingCoefficients;

@end

@implementation PNKUpsampling

@synthesize inputFeatureChannels = _inputFeatureChannels;

/// Kernel function name for nearest neighbor upsampling on a single texture.
static NSString * const kKernelFunctionNearestNeighborSingle = @"nearestNeighborSingle";

/// Kernel function name for nearest neighbor upsampling on texture array.
static NSString * const kKernelFunctionNearestNeighborArray = @"nearestNeighborArray";

/// Kernel function name for bilinear upsampling with non-aligned corners on a single texture.
static NSString * const kKernelFunctionBilinearSingle = @"bilinearSingle";

/// Kernel function name for bilinear upsampling with non-aligned corners on texture array.
static NSString * const kKernelFunctionBilinearArray = @"bilinearArray";

/// Kernel function name for bilinear upsampling with aligned corners on a single texture.
static NSString * const kKernelFunctionBilinearAlignedSingle = @"bilinearAlignedSingle";

/// Kernel function name for bilinear upsampling with aligned corners on texture array.
static NSString * const kKernelFunctionBilinearAlignedArray = @"bilinearAlignedArray";

/// Family name of the kernel functions for debug purposes.
static NSString * const kDebugGroupName = @"upsample";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device
                upsamplingType:(PNKUpsamplingType)upsamplingType {
  if (self = [super init]) {
    _device = device;

    [self createStatesWithUpsamplingType:upsamplingType];
    [self createBufferWithUpsamplingType:upsamplingType];
  }
  return self;
}

- (void)createStatesWithUpsamplingType:(PNKUpsamplingType)upsamplingType {
  switch (upsamplingType) {
    case PNKUpsamplingTypeNearestNeighbor:
      _stateSingle = PNKCreateComputeState(self.device, kKernelFunctionNearestNeighborSingle);
      _stateArray = PNKCreateComputeState(self.device, kKernelFunctionNearestNeighborArray);
      break;
    case PNKUpsamplingTypeBilinear:
      _stateSingle = PNKCreateComputeState(self.device, kKernelFunctionBilinearSingle);
      _stateArray = PNKCreateComputeState(self.device, kKernelFunctionBilinearArray);
      break;
    case PNKUpsamplingTypeBilinearAligned:
      _stateSingle = PNKCreateComputeState(self.device, kKernelFunctionBilinearAlignedSingle);
      _stateArray = PNKCreateComputeState(self.device, kKernelFunctionBilinearAlignedArray);
  }
}

- (void)createBufferWithUpsamplingType:(PNKUpsamplingType)upsamplingType {
  if (upsamplingType == PNKUpsamplingTypeBilinearAligned) {
    _bufferForSamplingCoefficients =
        [self.device newBufferWithLength:sizeof(pnk::SamplingCoefficients)
                                 options:MTLResourceCPUCacheModeWriteCombined];
  }
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  auto state = inputImage.pnk_isSingleTexture ? self.stateSingle : self.stateArray;

  MTLSize workingSpaceSize;
  if (self.bufferForSamplingCoefficients) {
    MTLSize outputTextureSize = outputImage.pnk_textureArraySize;
    [self fillBufferWithSamplingCoefficients:outputTextureSize];
    workingSpaceSize = outputTextureSize;
    PNKComputeDispatchWithDefaultThreads(state, commandBuffer,
                                         @[self.bufferForSamplingCoefficients], @[inputImage],
                                         @[outputImage], kDebugGroupName, workingSpaceSize);
 } else {
    workingSpaceSize = inputImage.pnk_textureArraySize;
   PNKComputeDispatchWithDefaultThreads(state, commandBuffer, @[inputImage], @[outputImage],
                                        kDebugGroupName, workingSpaceSize);
  }
}

- (void)verifyParametersWithInputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  MTLSize inputSize = {inputImage.width, inputImage.height, inputImage.featureChannels};
  MTLSize expectedOutputSize = [self outputSizeForInputSize:inputSize];

  LTParameterAssert(expectedOutputSize.depth == outputImage.featureChannels,
                    @"Input image featureChannels must match output image featureChannels, got: "
                    "(%lu, %lu)", (unsigned long)inputImage.featureChannels,
                    (unsigned long)outputImage.featureChannels);
  LTParameterAssert(expectedOutputSize.width == outputImage.width,
                    @"Input image width after upsampling must match output image width, "
                    "got: (%lu, %lu)", (unsigned long)expectedOutputSize.width,
                    (unsigned long)outputImage.width);
  LTParameterAssert(expectedOutputSize.height == outputImage.height,
                    @"Input image height after upsampling must match output image height, "
                    "got: (%lu, %lu)", (unsigned long)expectedOutputSize.height,
                    (unsigned long)outputImage.height);
}

- (void)fillBufferWithSamplingCoefficients:(MTLSize)outputTextureSize {
  float outputWidth = (float)outputTextureSize.width;
  float outputHeight = (float)outputTextureSize.height;
  float inputWidth = outputWidth / 2;
  float inputHeight = outputHeight / 2;

  auto samplingCoefficients =
      (pnk::SamplingCoefficients *)self.bufferForSamplingCoefficients.contents;
  samplingCoefficients->scaleX = (inputWidth - 1) / (inputWidth * (outputWidth - 1));
  samplingCoefficients->scaleY = (inputHeight - 1) / (inputHeight * (outputHeight - 1));
  samplingCoefficients->biasX = 1 / outputWidth;
  samplingCoefficients->biasY = 1 / outputHeight;
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  LTAssert(outputSize.width % 2 == 0, "Odd output width %lu is not supported",
           (unsigned long)outputSize.width);
  LTAssert(outputSize.height % 2 == 0, "Odd output height %lu is not supported",
           (unsigned long)outputSize.height);
  return {
    .origin = {0, 0, 0},
    .size = {
      outputSize.width / 2,
      outputSize.height / 2,
      outputSize.depth
    }
  };
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return {
    inputSize.width * 2,
    inputSize.height * 2,
    inputSize.depth
  };
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

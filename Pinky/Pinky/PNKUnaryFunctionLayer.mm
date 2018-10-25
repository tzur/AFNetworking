// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "PNKUnaryFunctionLayer.h"

#import "PNKBufferExtensions.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKUnaryFunctionLayer ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode operation on single texture.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingle;

/// Kernel state to encode operation on texture array.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArray;

/// Unary function alpha parameter buffer.
@property (readonly, nonatomic, nullable) id<MTLBuffer> alphaBuffer;

/// Bias value that is added to tensor elements before applying unary function.
@property (readonly, nonatomic, nullable) id<MTLBuffer> shiftBuffer;

/// Scale factor that is applied on tensor elements before applying unary function.
@property (readonly, nonatomic, nullable) id<MTLBuffer> scaleBuffer;

@end

@implementation PNKUnaryFunctionLayer

@synthesize inputFeatureChannels = _inputFeatureChannels;

/// Kernel function name for a single texture.
static NSString * const kKernelSingleFunctionName = @"unarySingle";

/// Kernel function name for texture array.
static NSString * const kKernelArrayFunctionName = @"unaryArray";

/// Family name of the kernel functions for debug purposes.
static NSString * const kDebugGroupName = @"unary";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device
                    unaryModel:(const pnk::UnaryFunctionKernelModel &)unaryModel {
  if (self = [super init]) {
    _device = device;
    [self createStatesWithUnaryType:unaryModel.type];
    [self setupBuffersWithUnaryModel:unaryModel];
  }
  return self;
}

- (void)createStatesWithUnaryType:(pnk::UnaryType)unaryType {
  ushort unaryTypeAsUshort = (ushort)unaryType;
  auto functionConstants = @[
    [MTBFunctionConstant ushortConstantWithValue:unaryTypeAsUshort name:@"unaryType"],
  ];

  _stateSingle = PNKCreateComputeState(self.device, kKernelSingleFunctionName, functionConstants);
  _stateArray = PNKCreateComputeState(self.device, kKernelArrayFunctionName, functionConstants);
}

- (void)setupBuffersWithUnaryModel:(const pnk::UnaryFunctionKernelModel &)model {
  cv::Mat1f alpha(1, 1, model.alpha);
  _alphaBuffer = PNKHalfBufferFromFloatVector(self.device, alpha, YES);

  cv::Mat1f shift(1, 1, model.shift);
  _shiftBuffer = PNKHalfBufferFromFloatVector(self.device, shift, YES);

  cv::Mat1f scale(1, 1, model.scale);
  _scaleBuffer = PNKHalfBufferFromFloatVector(self.device, scale, YES);
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  auto state = outputImage.pnk_isSingleTexture ? self.stateSingle : self.stateArray;

  NSArray<id<MTLBuffer>> *kernelBuffers = @[
    self.alphaBuffer,
    self.shiftBuffer,
    self.scaleBuffer
  ];

  MTLSize workingSpaceSize = inputImage.pnk_textureArraySize;
  MTBComputeDispatchWithDefaultThreads(state, commandBuffer, kernelBuffers, @[inputImage],
                                       @[outputImage], kDebugGroupName, workingSpaceSize);
}

- (void)verifyParametersWithInputImage:(MPSImage *)inputImage
                           outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.featureChannels == outputImage.featureChannels, @"Input image "
                    "featureChannels must match output image featureChannels. got: (%lu, %lu)",
                    (unsigned long)inputImage.featureChannels,
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
    .size = outputSize
  };
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return inputSize;
}

@end

NS_ASSUME_NONNULL_END

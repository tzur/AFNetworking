// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKActivationCustomInternalLayer.h"

#import "PNKActivationUtils.h"
#import "PNKBufferExtensions.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKActivationCustomInternalLayer ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode single texture activation.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingle;

/// Kernel state to encode texture array activation.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArray;

/// Kernel activation alpha parameters buffer.
@property (readonly, nonatomic, nullable) id<MTLBuffer> alphaBuffer;

/// Kernel activation beta parameters buffer.
@property (readonly, nonatomic, nullable) id<MTLBuffer> betaBuffer;

/// Indicator if the layer's ActivationType is using the Alpha parameter buffer.
@property (readonly, nonatomic) bool hasAlphaBuffer;

/// Indicator if the layer's ActivationType is using the Beta parameter buffer.
@property (readonly, nonatomic) bool hasBetaBuffer;

@end

@implementation PNKActivationCustomInternalLayer

@synthesize inputFeatureChannels = _inputFeatureChannels;

/// Kernel function name for a single texture.
static NSString * const kKernelSingleFunctionName = @"activationSingle";

/// Kernel function name for texture array.
static NSString * const kKernelArrayFunctionName = @"activationArray";

/// Family name of the kernel functions for debug purposes.
static NSString * const kDebugGroupName = @"activation";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device
               activationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (self = [super init]) {
    _device = device;
    [self createStatesWithActivationType:activationModel.activationType];
    [self setupBuffersWithActivationModel:activationModel];
  }
  return self;
}

- (void)createStatesWithActivationType:(pnk::ActivationType)activationType {
  auto needsAlphaBeta = PNKActivationNeedsAlphaBetaParameters(activationType);
  _hasAlphaBuffer = needsAlphaBeta.first;
  _hasBetaBuffer = needsAlphaBeta.second;

  ushort activationTypeAsUshort = (ushort)activationType;
  auto functionConstants = @[
    [MTBFunctionConstant ushortConstantWithValue:activationTypeAsUshort name:@"activationType"],
    [MTBFunctionConstant boolConstantWithValue:self.hasAlphaBuffer name:@"hasAlphaBuffer"],
    [MTBFunctionConstant boolConstantWithValue:self.hasBetaBuffer name:@"hasBetaBuffer"]
  ];

  _stateSingle = PNKCreateComputeState(self.device, kKernelSingleFunctionName, functionConstants);
  _stateArray = PNKCreateComputeState(self.device, kKernelArrayFunctionName, functionConstants);
}

- (void)setupBuffersWithActivationModel:(const pnk::ActivationKernelModel &)model {
  _alphaBuffer = self.hasAlphaBuffer ?
      PNKHalfBufferFromFloatVector(self.device, model.alpha, YES) : nil;
  _betaBuffer = self.hasBetaBuffer ?
      PNKHalfBufferFromFloatVector(self.device, model.beta, YES) : nil;
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  auto state = outputImage.pnk_isSingleTexture ? self.stateSingle : self.stateArray;

  NSArray<id<MTLBuffer>> *kernelBuffers;
  if (self.hasBetaBuffer) {
    kernelBuffers = @[self.alphaBuffer, self.betaBuffer];
  } else if (self.hasAlphaBuffer) {
    kernelBuffers = @[self.alphaBuffer];
  } else {
    kernelBuffers = @[];
  }

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

+ (BOOL)doesSupportActivationType:(__unused pnk::ActivationType)activationType {
  return YES;
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKActivationCustomInternalLayer.h"

#import "PNKBufferExtensions.h"
#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"
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
  switch (activationType) {
    case pnk::ActivationTypeIdentity:
    case pnk::ActivationTypeAbsolute:
    case pnk::ActivationTypeReLU:
    case pnk::ActivationTypeTanh:
    case pnk::ActivationTypeSigmoid:
    case pnk::ActivationTypeSoftsign:
    case pnk::ActivationTypeSoftplus:
      _hasAlphaBuffer = false;
      _hasBetaBuffer = false;
      break;
    case pnk::ActivationTypeLeakyReLU:
    case pnk::ActivationTypePReLU:
    case pnk::ActivationTypeELU:
      _hasAlphaBuffer = true;
      _hasBetaBuffer = false;
      break;
    case pnk::ActivationTypeScaledTanh:
    case pnk::ActivationTypeSigmoidHard:
    case pnk::ActivationTypeLinear:
    case pnk::ActivationTypeParametricSoftplus:
      _hasAlphaBuffer = true;
      _hasBetaBuffer = true;
      break;
  }

  ushort activationTypeAsUshort = (ushort)activationType;
  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  [functionConstants setConstantValue:&activationTypeAsUshort type:MTLDataTypeUShort
                             withName:@"activationType"];
  [functionConstants setConstantValue:&_hasAlphaBuffer type:MTLDataTypeBool
                             withName:@"hasAlphaBuffer"];
  [functionConstants setConstantValue:&_hasBetaBuffer type:MTLDataTypeBool
                             withName:@"hasBetaBuffer"];

  _stateSingle = PNKCreateComputeStateWithConstants(self.device, kKernelSingleFunctionName,
                                                    functionConstants);
  _stateArray = PNKCreateComputeStateWithConstants(self.device, kKernelArrayFunctionName,
                                                   functionConstants);
}

- (void)setupBuffersWithActivationModel:(const pnk::ActivationKernelModel &)model {
  _alphaBuffer = self.hasAlphaBuffer ? PNKHalfBufferFromFloatVector(self.device, model.alpha) : nil;
  _betaBuffer = self.hasBetaBuffer ? PNKHalfBufferFromFloatVector(self.device, model.beta) : nil;
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  id<MTLComputePipelineState> state = outputImage.featureChannels <= 4 ?
      self.stateSingle : self.stateArray;

  NSArray<id<MTLBuffer>> *kernelBuffers;
  if (self.hasBetaBuffer) {
    kernelBuffers = @[self.alphaBuffer, self.betaBuffer];
  } else if (self.hasAlphaBuffer) {
    kernelBuffers = @[self.alphaBuffer];
  } else {
    kernelBuffers = @[];
  }

  MTLSize workingSpaceSize = {inputImage.width, inputImage.height, inputImage.texture.arrayLength};
  PNKComputeDispatchWithDefaultThreads(state, commandBuffer, kernelBuffers,
                                       @[inputImage.texture, outputImage.texture],
                                       kDebugGroupName, workingSpaceSize);

  if ([inputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *)inputImage).readCount -= 1;
  }
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


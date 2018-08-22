// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKBatchNormalizationLayer.h"

#import "PNKActivationUtils.h"
#import "PNKBufferExtensions.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKBatchNormalizationLayer ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

/// Kernel function name.
@property (readonly, nonatomic) NSString *functionName;

/// Kernel scale buffer.
@property (readonly, nonatomic) id<MTLBuffer> scaleBuffer;

/// Kernel shift buffer.
@property (readonly, nonatomic) id<MTLBuffer> shiftBuffer;

/// Kernel activation alpha parameters buffer.
@property (readonly, nonatomic, nullable) id<MTLBuffer> alphaBuffer;

/// Kernel activation beta parameters buffer.
@property (readonly, nonatomic, nullable) id<MTLBuffer> betaBuffer;

/// Indicator if the layer's ActivationType is using the Alpha parameter buffer.
@property (readonly, nonatomic) bool hasAlphaBuffer;

/// Indicator if the layer's ActivationType is using the Beta parameter buffer.
@property (readonly, nonatomic) bool hasBetaBuffer;

@end

@implementation PNKBatchNormalizationLayer

@synthesize kernelWidth = _kernelWidth;
@synthesize kernelHeight = _kernelHeight;
@synthesize inputFeatureChannels = _inputFeatureChannels;
@synthesize outputFeatureChannels = _outputFeatureChannels;
@synthesize strideX = _strideX;
@synthesize strideY = _strideY;
@synthesize groups = _groups;

/// Texture input kernel function name.
static NSString * const kKernelSingleFunctionName = @"batchNormSingle";

/// Texture array input kernel function name.
static NSString * const kKernelArrayFunctionName = @"batchNormArray";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device
            normalizationModel:(const pnk::NormalizationKernelModel &)normalizationModel
               activationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (self = [super init]) {
    _device = device;
    [self updatePropertiesWithNormalizationModel:normalizationModel];
    [self setupBuffersAndStateWithActivationModel:activationModel];
    [self setupBuffersWithNormalizationModel:normalizationModel];
  }
  return self;
}

- (void)updatePropertiesWithNormalizationModel:(const pnk::NormalizationKernelModel &)model {
  LTParameterAssert(!model.instanceNormalization,
                    @"Normalization model must not be instance normalization");
  LTParameterAssert(model.scale.total() == (size_t)model.inputFeatureChannels,
                    @"Normalization model scale parameters must be equal to the number of input "
                    "features (%lu), got %lu", (unsigned long)model.inputFeatureChannels,
                    (unsigned long)model.scale.total());
  LTParameterAssert(model.shift.total() == (size_t)model.inputFeatureChannels,
                    @"Normalization model shift parameters must be equal to the number of input "
                    "features (%lu), got %lu", (unsigned long)model.inputFeatureChannels,
                    (unsigned long)model.shift.total());
  LTParameterAssert(model.mean.total() == (size_t)model.inputFeatureChannels,
                    @"Normalization model mean parameters must be equal to the number of input "
                    "features (%lu), got %lu", (unsigned long)model.inputFeatureChannels,
                    (unsigned long)model.mean.total());
  LTParameterAssert(model.variance.total() == (size_t)model.inputFeatureChannels,
                    @"Normalization model variance parameters must be equal to the number of input "
                    "features (%lu), got %lu", (unsigned long)model.inputFeatureChannels,
                    (unsigned long)model.variance.total());

  _kernelWidth = 1;
  _kernelHeight = 1;
  _inputFeatureChannels = model.inputFeatureChannels;
  _outputFeatureChannels = model.inputFeatureChannels;
  _strideX = 1;
  _strideY = 1;
  _groups = 1;
}

- (void)setupBuffersAndStateWithActivationModel:(const pnk::ActivationKernelModel &)model {
  [self createStateWithActivationType:model.activationType];

  _alphaBuffer = self.hasAlphaBuffer ?
      PNKHalfBufferFromFloatVector(self.device, model.alpha, YES) : nil;
  _betaBuffer = self.hasBetaBuffer ?
      PNKHalfBufferFromFloatVector(self.device, model.beta, YES) : nil;
}

- (void)createStateWithActivationType:(pnk::ActivationType)activationType {
  _functionName = self.inputFeatureChannels > 4 ?
      kKernelArrayFunctionName : kKernelSingleFunctionName;

  auto needsAlphaBeta = PNKActivationNeedsAlphaBetaParameters(activationType);
  _hasAlphaBuffer = needsAlphaBeta.first;
  _hasBetaBuffer = needsAlphaBeta.second;

  ushort activationTypeAsUshort = (ushort)activationType;
  auto functionConstants = @[
    [MTBFunctionConstant ushortConstantWithValue:activationTypeAsUshort name:@"activationType"],
    [MTBFunctionConstant boolConstantWithValue:_hasAlphaBuffer name:@"hasAlphaBuffer"],
    [MTBFunctionConstant boolConstantWithValue:_hasBetaBuffer name:@"hasBetaBuffer"]
  ];

  _state = PNKCreateComputeState(self.device, self.functionName, functionConstants);
}

- (void)setupBuffersWithNormalizationModel:(const pnk::NormalizationKernelModel &)model {
  cv::Mat correctedScale = model.scale / (model.variance + model.epsilon);
  cv::Mat correctedShift = model.shift - model.mean.mul(correctedScale);

  _scaleBuffer = PNKHalfBufferFromFloatVector(self.device, correctedScale, YES);
  _shiftBuffer = PNKHalfBufferFromFloatVector(self.device, correctedShift, YES);
}

#pragma mark -
#pragma mark PNKUnaryNeuralKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  NSArray<id<MTLBuffer>> *kernelBuffers;
  if (self.hasBetaBuffer) {
    kernelBuffers = @[self.scaleBuffer, self.shiftBuffer, self.alphaBuffer, self.betaBuffer];
  } else if (self.hasAlphaBuffer) {
    kernelBuffers = @[self.scaleBuffer, self.shiftBuffer, self.alphaBuffer];
  } else {
    kernelBuffers = @[self.scaleBuffer, self.shiftBuffer];
  }

  MTLSize workingSpaceSize = inputImage.pnk_textureArraySize;
  MTBComputeDispatchWithDefaultThreads(self.state, commandBuffer, kernelBuffers, @[inputImage],
                                       @[outputImage], self.functionName, workingSpaceSize);
}

- (void)verifyParametersWithInputImage:(MPSImage *)inputImage
                           outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.featureChannels == outputImage.featureChannels, @"Input image "
                    "featureChannels must match output image featureChannels. got: (%lu, %lu)",
                    (unsigned long)inputImage.featureChannels,
                    (unsigned long)outputImage.featureChannels);
  LTParameterAssert(self.inputFeatureChannels == inputImage.featureChannels, @"Input image must "
                    "have %lu feature channels, got: %lu",
                    (unsigned long)self.inputFeatureChannels,
                    (unsigned long)inputImage.featureChannels);
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

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

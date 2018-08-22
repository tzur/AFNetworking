// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKInstanceNormInternalKernel.h"

#import "PNKActivationUtils.h"
#import "PNKBufferExtensions.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKInstanceNormInternalKernel ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

/// Kernel function name.
@property (readonly, nonatomic) NSString *functionName;

/// Kernel scale buffer.
@property (nonatomic) id<MTLBuffer> scaleBuffer;

/// Kernel shift buffer.
@property (nonatomic) id<MTLBuffer> shiftBuffer;

/// Kernel activation alpha parameters buffer.
@property (readonly, nonatomic, nullable) id<MTLBuffer> alphaBuffer;

/// Kernel activation beta parameters buffer.
@property (readonly, nonatomic, nullable) id<MTLBuffer> betaBuffer;

/// Indicator if the layer's ActivationType is using the Alpha parameter buffer.
@property (readonly, nonatomic) bool hasAlphaBuffer;

/// Indicator if the layer's ActivationType is using the Beta parameter buffer.
@property (readonly, nonatomic) bool hasBetaBuffer;

/// Indicator if the parameter buffers (scale and shift) should be reused.
@property (readonly, nonatomic) BOOL reuseParameterBuffers;

@end

@implementation PNKInstanceNormInternalKernel

@synthesize inputFeatureChannels = _inputFeatureChannels;

/// Texture input kernel function name.
static NSString * const kKernelFunctionName = @"instanceNorm";

/// Texture array input function kernel function name.
static NSString * const kKernelArrayFunctionName = @"instanceNormArray";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device
               featureChannels:(NSUInteger)featureChannels
               activationModel:(const pnk::ActivationKernelModel &)activationModel
         reuseParameterBuffers:(BOOL)reuseParameterBuffers {
  if (self = [super init]) {
    _device = device;
    _featureChannels = featureChannels;
    _inputFeatureChannels = featureChannels;
    _reuseParameterBuffers = reuseParameterBuffers;
    [self setupBuffersAndStateWithActivationModel:activationModel];
  }
  return self;
}

- (void)setupBuffersAndStateWithActivationModel:(const pnk::ActivationKernelModel &)model {
  [self createStateWithActivationType:model.activationType];

  _alphaBuffer = self.hasAlphaBuffer ?
      PNKHalfBufferFromFloatVector(self.device, model.alpha, YES) : nil;
  _betaBuffer = self.hasBetaBuffer ?
      PNKHalfBufferFromFloatVector(self.device, model.beta, YES) : nil;
  _scaleBuffer = PNKHalfBufferFromFloatVector(self.device,
                                              cv::Mat1f(1, (int)self.featureChannels, 1.), YES);
  _shiftBuffer = PNKHalfBufferFromFloatVector(self.device,
                                              cv::Mat1f(1, (int)self.featureChannels, 0.), YES);
}

- (void)createStateWithActivationType:(pnk::ActivationType)activationType {
  _functionName = self.inputFeatureChannels > 4 ?
      kKernelArrayFunctionName : kKernelFunctionName;

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

- (void)setScaleParameters:(const cv::Mat &)parameters {
  int elementsCount = parameters.cols * parameters.rows;
  LTParameterAssert(elementsCount == (int)self.featureChannels, @"Number of scale parameters must "
                    "be the same as number of input features (%lu), got %d",
                    (unsigned long)self.featureChannels, elementsCount);
  if (self.reuseParameterBuffers) {
    PNKFillHalfFloatBuffer(self.scaleBuffer, parameters);
  } else {
    self.scaleBuffer = PNKHalfBufferFromFloatVector(self.device, parameters, YES);
  }
}

- (void)setShiftParameters:(const cv::Mat &)parameters {
  int elementsCount = parameters.cols * parameters.rows;
  LTParameterAssert(elementsCount == (int)self.featureChannels, @"Number of shift parameters must "
                    "be the same as number of input features (%lu), got %d",
                    (unsigned long)self.featureChannels, elementsCount);
  if (self.reuseParameterBuffers) {
    PNKFillHalfFloatBuffer(self.shiftBuffer, parameters);
  } else {
    self.shiftBuffer = PNKHalfBufferFromFloatVector(self.device, parameters, YES);
  }
}

#pragma mark -
#pragma mark PNKUnaryNeuralKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  static const NSUInteger kMaxThreadsInGroup = 256;
  auto threadWidth = std::min(kMaxThreadsInGroup, outputImage.width);
  auto threadHeight = std::min(kMaxThreadsInGroup / threadWidth, outputImage.height);
  MTLSize threadsInGroup = MTLSizeMake(threadWidth, threadHeight, 1);
  MTLSize threadgroupsPerGrid = {1, 1, outputImage.pnk_textureArrayDepth};

  NSArray<id<MTLBuffer>> *kernelBuffers;
  if (self.hasBetaBuffer) {
    kernelBuffers = @[self.scaleBuffer, self.shiftBuffer, self.alphaBuffer, self.betaBuffer];
  } else if (self.hasAlphaBuffer) {
    kernelBuffers = @[self.scaleBuffer, self.shiftBuffer, self.alphaBuffer];
  } else {
    kernelBuffers = @[self.scaleBuffer, self.shiftBuffer];
  }

  MTBComputeDispatch(self.state, commandBuffer, kernelBuffers, @[inputImage], @[outputImage],
                     self.functionName, threadsInGroup, threadgroupsPerGrid);
}

- (void)verifyParametersWithInputImage:(MPSImage *)inputImage
                           outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.featureChannels == outputImage.featureChannels, @"Input image "
                    "featureChannels must match output image featureChannels. got: (%lu, %lu)",
                    (unsigned long)inputImage.featureChannels,
                    (unsigned long)outputImage.featureChannels);
  LTParameterAssert(self.featureChannels == inputImage.featureChannels, @"Input image must "
                    "have %lu feature channels, got: %lu",
                    (unsigned long)self.featureChannels,
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

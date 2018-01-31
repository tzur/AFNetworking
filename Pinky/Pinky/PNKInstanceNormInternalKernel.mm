// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKInstanceNormInternalKernel.h"

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
@property (readonly, nonatomic) id<MTLBuffer> scaleBuffer;

/// Kernel shift buffer.
@property (readonly, nonatomic) id<MTLBuffer> shiftBuffer;

/// Kernel activation type performed after normalization.
@property (readonly, nonatomic) pnk::ActivationType activationType;

/// Kernel pReLU parameters buffer.
@property (readonly, nonatomic, nullable) id<MTLBuffer> preluBuffer;

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
                activationType:(pnk::ActivationType)activationType {
  if (self = [super init]) {
    _device = device;
    _featureChannels = featureChannels;
    _inputFeatureChannels = featureChannels;
    _activationType = activationType;
    [self setupBuffersAndStateWithActivationModel:activationType];
  }
  return self;
}

- (void)setupBuffersAndStateWithActivationModel:(pnk::ActivationType)activationType {
  switch (activationType) {
    case pnk::ActivationTypeIdentity:
      [self createStateWithHasPrelu:NO sharedPrelu:NO];
      break;
    case pnk::ActivationTypeAbsolute:
      [self createStateWithHasPrelu:YES sharedPrelu:YES];
      _preluBuffer = PNKHalfBufferFromFloatVector(self.device, cv::Mat1f(1, 1, -1.), YES);
      break;
    case pnk::ActivationTypeReLU:
      [self createStateWithHasPrelu:YES sharedPrelu:YES];
      _preluBuffer = PNKHalfBufferFromFloatVector(self.device, cv::Mat1f(1, 1, 0.), YES);
      break;
    case pnk::ActivationTypeLeakyReLU:
      [self createStateWithHasPrelu:YES sharedPrelu:YES];
      _preluBuffer = PNKHalfBufferFromFloatVector(self.device, cv::Mat1f(1, 1, 0.), YES);
      break;
    case pnk::ActivationTypePReLU:
      [self createStateWithHasPrelu:YES sharedPrelu:NO];
      _preluBuffer = PNKHalfBufferFromFloatVector(self.device,
                                                  cv::Mat1f::zeros(1, (int)self.featureChannels),
                                                  YES);
      break;
    default:
      LTParameterAssert(NO, @"Activation type %lu is not supported",
                        (unsigned long)activationType);
  }

  _scaleBuffer = PNKHalfBufferFromFloatVector(self.device,
                                              cv::Mat1f(1, (int)self.featureChannels, 1.), YES);
  _shiftBuffer = PNKHalfBufferFromFloatVector(self.device,
                                              cv::Mat1f(1, (int)self.featureChannels, 0.), YES);
}

- (void)createStateWithHasPrelu:(const BOOL)hasPrelu sharedPrelu:(const BOOL)sharedPrelu {
  _functionName = self.inputFeatureChannels > 4 ? kKernelArrayFunctionName : kKernelFunctionName;
  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  [functionConstants setConstantValue:&hasPrelu type:MTLDataTypeBool withName:@"hasPrelu"];
  [functionConstants setConstantValue:&sharedPrelu type:MTLDataTypeBool withName:@"sharedPrelu"];
  _state = PNKCreateComputeStateWithConstants(self.device, self.functionName, functionConstants);
}

- (void)setScaleParameters:(const cv::Mat &)parameters {
  int elementsCount = parameters.cols * parameters.rows;
  LTParameterAssert(elementsCount == (int)self.featureChannels, @"Number of scale parameters must "
                    "be the same as number of input features (%lu), got %d",
                    (unsigned long)self.featureChannels, elementsCount);
  PNKFillHalfFloatBuffer(self.scaleBuffer, parameters);
}

- (void)setShiftParameters:(const cv::Mat &)parameters {
  int elementsCount = parameters.cols * parameters.rows;
  LTParameterAssert(elementsCount == (int)self.featureChannels, @"Number of shift parameters must "
                    "be the same as number of input features (%lu), got %d",
                    (unsigned long)self.featureChannels, elementsCount);
  PNKFillHalfFloatBuffer(self.shiftBuffer, parameters);
}

- (void)setPReluParameters:(const cv::Mat &)parameters {
  int elementsCount = parameters.cols * parameters.rows;
  switch (self.activationType) {
    case pnk::ActivationTypeLeakyReLU:
      LTParameterAssert(elementsCount == 1, @"Leaky Relu Activation model must "
                        "have exactly one parameter, got %d", elementsCount);
      PNKFillHalfFloatBuffer(self.preluBuffer, parameters);
      break;
    case pnk::ActivationTypePReLU:
      LTParameterAssert(elementsCount == (int)self.featureChannels, @"PRelu Activation model must "
                        "have the same number of parameters as number of input features (%lu), "
                        "got %d", (unsigned long)self.featureChannels, elementsCount);
      PNKFillHalfFloatBuffer(self.preluBuffer, parameters);
      break;
    default:
      LTParameterAssert(NO, @"Setting parameters for activation type %lu is not supported",
                        (unsigned long)self.activationType);
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

  auto kernelBuffers = self.preluBuffer ?
      @[self.scaleBuffer, self.shiftBuffer, self.preluBuffer] :
      @[self.scaleBuffer, self.shiftBuffer];

  PNKComputeDispatch(self.state, commandBuffer, kernelBuffers, @[inputImage], @[outputImage],
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

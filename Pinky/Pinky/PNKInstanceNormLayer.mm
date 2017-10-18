// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKInstanceNormLayer.h"

#import "PNKBufferExtensions.h"
#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKInstanceNormLayer ()

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

/// Kernel pReLU parameters buffer.
@property (readonly, nonatomic, nullable) id<MTLBuffer> preluBuffer;

@end

@implementation PNKInstanceNormLayer

@synthesize kernelWidth = _kernelWidth;
@synthesize kernelHeight = _kernelHeight;
@synthesize inputFeatureChannels = _inputFeatureChannels;
@synthesize outputFeatureChannels = _outputFeatureChannels;
@synthesize strideX = _strideX;
@synthesize strideY = _strideY;
@synthesize groups = _groups;
@synthesize isInputArray = _isInputArray;

/// Texture input kernel function name.
static NSString * const kKernelFunctionName = @"instanceNorm";

/// Texture array input function kernel function name.
static NSString * const kKernelArrayFunctionName = @"instanceNormArray";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device
            normalizationModel:(const pnk::NormalizationKernelModel &)normalizationModel
               activationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (self = [super init]) {
    _device = device;
    [self updatePropertiesWithNormalizationModel:normalizationModel];
    [self setupWithActivationModel:activationModel];
    [self createBuffersWithNormalizationModel:normalizationModel];
  }
  return self;
}

- (void)updatePropertiesWithNormalizationModel:(const pnk::NormalizationKernelModel &)model {
  _kernelWidth = 1;
  _kernelHeight = 1;
  _inputFeatureChannels = model.inputFeatureChannels;
  _outputFeatureChannels = model.inputFeatureChannels;
  _strideX = 1;
  _strideY = 1;
  _groups = 1;
  _isInputArray = model.inputFeatureChannels > 4;
}

- (void)setupWithActivationModel:(const pnk::ActivationKernelModel &)model {
  switch (model.activationType) {
    case pnk::ActivationTypeIdentity:
      [self createStateWithHasPrelu:NO sharedPrelu:NO];
      break;
    case pnk::ActivationTypeAbsolute:
      [self createStateWithHasPrelu:YES sharedPrelu:YES];
      _preluBuffer = [self halfBufferFromFloatVector:cv::Mat1f(1, 1, -1.)];
      break;
    case pnk::ActivationTypeReLU:
      [self createStateWithHasPrelu:YES sharedPrelu:YES];
      _preluBuffer = [self halfBufferFromFloatVector:cv::Mat1f(1, 1, 0.)];
      break;
    case pnk::ActivationTypeLeakyReLU:
      [self createStateWithHasPrelu:YES sharedPrelu:YES];
      LTParameterAssert(model.alpha.cols == 1, @"Leaky Relu Activation model must have exactly one "
                        "parameter, got %d", model.alpha.cols);
      _preluBuffer = [self halfBufferFromFloatVector:model.alpha];
      break;
    case pnk::ActivationTypePReLU:
      [self createStateWithHasPrelu:YES sharedPrelu:NO];
      LTParameterAssert(model.alpha.cols == (int)self.inputFeatureChannels, @"PRelu Activation "
                        "model must have the same number of parameters as number of input features "
                        "(%lu), got %d", (unsigned long)self.inputFeatureChannels,
                        model.alpha.cols);
      _preluBuffer = [self halfBufferFromFloatVector:model.alpha];
      break;
    default:
      LTParameterAssert(NO, @"Activation type %lu is not supported",
                        (unsigned long)model.activationType);
  }
}

- (void)createStateWithHasPrelu:(const BOOL)hasPrelu sharedPrelu:(const BOOL)sharedPrelu {
  _functionName = self.isInputArray ? kKernelArrayFunctionName : kKernelFunctionName;
  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  [functionConstants setConstantValue:&hasPrelu type:MTLDataTypeBool withName:@"hasPrelu"];
  [functionConstants setConstantValue:&sharedPrelu type:MTLDataTypeBool withName:@"sharedPrelu"];
  _state = PNKCreateComputeStateWithConstants(self.device, self.functionName, functionConstants);
}

- (void)createBuffersWithNormalizationModel:(const pnk::NormalizationKernelModel &)model {
  LTParameterAssert(model.scale.cols == (int)model.inputFeatureChannels, @"Normalization model "
                    "must have the same number of scale parameters as number of input features "
                    "(%lu), got %d", (unsigned long)self.inputFeatureChannels, model.scale.cols);
  LTParameterAssert(model.shift.cols == (int)model.inputFeatureChannels, @"Normalization model "
                    "must have the same number of shift parameters as number of input features "
                    "(%lu), got %d", (unsigned long)self.inputFeatureChannels, model.shift.cols);

  _scaleBuffer = [self halfBufferFromFloatVector:model.scale];
  _shiftBuffer = [self halfBufferFromFloatVector:model.shift];
}

- (id<MTLBuffer>)halfBufferFromFloatVector:(const cv::Mat1f &)parameters {
  NSUInteger bufferElements = PNKImageAlignedBufferElementsFromMatrix(parameters);
  id<MTLBuffer> buffer = [self.device newBufferWithLength:bufferElements * sizeof(half_float::half)
                                                  options:MTLResourceCPUCacheModeWriteCombined];
  PNKFillHalfFloatBuffer(buffer, parameters);
  return buffer;
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
  MTLSize threadgroupsPerGrid = {1, 1, outputImage.texture.arrayLength};

  auto kernelBuffers = self.preluBuffer ?
      @[self.scaleBuffer, self.shiftBuffer, self.preluBuffer] :
      @[self.scaleBuffer, self.shiftBuffer];

  PNKComputeDispatch(self.state, commandBuffer, kernelBuffers,
                     @[inputImage.texture, outputImage.texture], self.functionName, threadsInGroup,
                     threadgroupsPerGrid);

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

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

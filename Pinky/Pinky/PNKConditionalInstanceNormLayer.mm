// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKConditionalInstanceNormLayer.h"

#import "PNKBufferExtensions.h"
#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"
#import "PNKInstanceNormInternalKernel.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKConditionalInstanceNormLayer ()

/// Instance normalization kernel performing the operation underlying this layer.
@property (readonly, nonatomic) PNKInstanceNormInternalKernel *instanceNormKernel;

/// Matrix of scale parameters for the instance normalization operation. Each row of the matrix
/// represents the scale of the corresponding condition.
@property (readonly, nonatomic) cv::Mat1f scaleMatrix;

/// Matrix of shift parameters for the instance normalization operation. Each row of the matrix
/// represents the shift of the corresponding condition.
@property (readonly, nonatomic) cv::Mat1f shiftMatrix;

@end

@implementation PNKConditionalInstanceNormLayer

@synthesize kernelWidth = _kernelWidth;
@synthesize kernelHeight = _kernelHeight;
@synthesize inputFeatureChannels = _inputFeatureChannels;
@synthesize outputFeatureChannels = _outputFeatureChannels;
@synthesize strideX = _strideX;
@synthesize strideY = _strideY;
@synthesize groups = _groups;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device
            normalizationModel:(const pnk::NormalizationKernelModel &)normalizationModel
               activationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (self = [super init]) {
    [self updatePropertiesWithNormalizationModel:normalizationModel];
    _instanceNormKernel = [[PNKInstanceNormInternalKernel alloc]
                           initWithDevice:device
                           featureChannels:normalizationModel.inputFeatureChannels
                           activationType:activationModel.activationType];

    if (activationModel.activationType == pnk::ActivationTypeLeakyReLU ||
        activationModel.activationType == pnk::ActivationTypePReLU) {
      [self.instanceNormKernel setPReluParameters:activationModel.alpha];
    }
    [self setSingleCondition:0];
  }
  return self;
}

- (void)updatePropertiesWithNormalizationModel:(const pnk::NormalizationKernelModel &)model {
  LTParameterAssert(model.instanceNormalization,
                    @"Normalization model must be instance normalization");
  LTParameterAssert(model.scale.cols % model.inputFeatureChannels == 0,
                    @"Normalization model scale parameters must be a multiply of the number of "
                    "input features (%lu), got %lu", (unsigned long)model.inputFeatureChannels,
                    (unsigned long)model.scale.cols);
  LTParameterAssert(model.shift.cols % model.inputFeatureChannels == 0,
                    @"Normalization model shift parameters must be a multiply of the number of "
                    "input features (%lu), got %lu", (unsigned long)model.inputFeatureChannels,
                    (unsigned long)model.shift.cols);
  _kernelWidth = 1;
  _kernelHeight = 1;
  _inputFeatureChannels = model.inputFeatureChannels;
  _outputFeatureChannels = model.inputFeatureChannels;
  _strideX = 1;
  _strideY = 1;
  _groups = 1;

  _conditionsCount = model.scale.cols / model.inputFeatureChannels;
  _scaleMatrix = model.scale.reshape(0, (int)self.conditionsCount).clone();
  _shiftMatrix = model.shift.reshape(0, (int)self.conditionsCount).clone();
}

- (void)setSingleCondition:(NSUInteger)condition {
  LTParameterAssert(condition < self.conditionsCount,
                    @"Condition number must be in [0, %lu), got %lu",
                    (unsigned long)self.conditionsCount, (unsigned long)condition);
  [self.instanceNormKernel setScaleParameters:self.scaleMatrix.row((int)condition)];
  [self.instanceNormKernel setShiftParameters:self.shiftMatrix.row((int)condition)];
}

#pragma mark -
#pragma mark PNKUnaryNeuralKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self.instanceNormKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                    outputImage:outputImage];
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return [self.instanceNormKernel inputRegionForOutputSize:outputSize];
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return [self.instanceNormKernel outputSizeForInputSize:inputSize];
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

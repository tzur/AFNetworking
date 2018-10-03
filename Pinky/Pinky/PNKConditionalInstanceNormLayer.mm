// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKConditionalInstanceNormLayer.h"

#import "PNKBufferExtensions.h"
#import "PNKCollectionUtils.h"
#import "PNKInstanceNormInternalKernel.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

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

@synthesize inputFeatureChannels = _inputFeatureChannels;

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
                           activationModel:activationModel
                           reuseParameterBuffers:NO];

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
  _inputFeatureChannels = model.inputFeatureChannels;

  _conditionsCount = model.scale.cols / model.inputFeatureChannels;
  _scaleMatrix = model.scale.reshape(0, (int)self.conditionsCount).clone();
  _shiftMatrix = model.shift.reshape(0, (int)self.conditionsCount).clone();
}

#pragma mark -
#pragma mark PNKParametricUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage
              inputParameters:(NSDictionary<NSString *, NSObject *> *)inputParameters
                  outputImage:(MPSImage *)outputImage {
  [self validateInputParameters:inputParameters];
  NSUInteger condition = ((NSNumber *)inputParameters[@"condition"]).unsignedIntegerValue;
  [self setSingleCondition:condition];
  [self.instanceNormKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                    outputImage:outputImage];
}

- (void)validateInputParameters:(NSDictionary<NSString *, NSObject *> *)inputParameters {
  PNKValidateCollection(inputParameters, [self inputParameterKernelNames], @"input parameters");
  LTAssert([inputParameters[@"condition"] isKindOfClass:[NSNumber class]], @"Input parameter %@ is "
           "not an NSNumber", inputParameters[@"condition"]);
}

- (NSArray<NSString *> *)inputParameterKernelNames {
  return @[@"condition"];
}

- (void)setSingleCondition:(NSUInteger)condition {
  LTParameterAssert(condition < self.conditionsCount,
                    @"Condition number must be in [0, %lu), got %lu",
                    (unsigned long)self.conditionsCount, (unsigned long)condition);
  [self.instanceNormKernel setScaleParameters:self.scaleMatrix.row((int)condition)];
  [self.instanceNormKernel setShiftParameters:self.shiftMatrix.row((int)condition)];
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return [self.instanceNormKernel inputRegionForOutputSize:outputSize];
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return [self.instanceNormKernel outputSizeForInputSize:inputSize];
}

@end

NS_ASSUME_NONNULL_END

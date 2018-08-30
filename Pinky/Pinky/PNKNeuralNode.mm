// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKNeuralNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKNeuralNode ()

/// Unary kernel as set by initializer. Exactly one of \c unaryKernel, \c parametricUnaryKernel and
/// \c binaryKernel properties is non-nil.
@property (readonly, nonatomic, nullable) id<PNKUnaryKernel> unaryKernel;

/// Parametric unary kernel as set by initializer. Exactly one of \c unaryKernel,
/// \c parametricUnaryKernel and \c binaryKernel properties is non-nil.
@property (readonly, nonatomic, nullable) id<PNKParametricUnaryKernel> parametricUnaryKernel;

/// Binary kernel as set by initializer. Exactly one of \c unaryKernel, \c parametricUnaryKernel
/// and \c binaryKernel properties is non-nil.
@property (readonly, nonatomic, nullable) id<PNKBinaryKernel> binaryKernel;

/// \c readCount  property value to be set on \c outputImage in case it is of \c MPSTempoarayImage
/// type.
@property (readonly, nonatomic) NSUInteger outputImageReadCount;

@end

@implementation PNKNeuralNode

- (instancetype)initWithUnaryKernel:(id<PNKUnaryKernel>)unaryKernel
              primaryInputImageName:(NSString *)primaryInputImageName
                    outputImageName:(NSString *)outputImageName
               outputImageReadCount:(NSUInteger)outputImageReadCount {
  if (self = [super init]) {
    _unaryKernel = unaryKernel;
    _primaryInputImageName = primaryInputImageName;
    _outputImageName = outputImageName;
    _outputImageReadCount = outputImageReadCount;
  }
  return self;
}

- (instancetype)initWithParametricUnaryKernel:(id<PNKParametricUnaryKernel>)parametricUnaryKernel
                        primaryInputImageName:(NSString *)primaryInputImageName
                    inputParameterGlobalNames:(NSArray<NSString *> *)inputParameterGlobalNames
                              outputImageName:(NSString *)outputImageName
                         outputImageReadCount:(NSUInteger)outputImageReadCount {
  LTParameterAssert(inputParameterGlobalNames.count ==
                    parametricUnaryKernel.inputParameterKernelNames.count,
                    @"Input parameter kernel names array should contain %lu entries, got: %lu",
                    (unsigned long)parametricUnaryKernel.inputParameterKernelNames.count,
                    (unsigned long)inputParameterGlobalNames.count);
  if (self = [super init]) {
    _parametricUnaryKernel = parametricUnaryKernel;
    _primaryInputImageName = primaryInputImageName;
    _inputParameterGlobalNames = inputParameterGlobalNames;
    _outputImageName = outputImageName;
    _outputImageReadCount = outputImageReadCount;
  }
  return self;
}

- (instancetype)initWithBinaryKernel:(id<PNKBinaryKernel>)binaryKernel
               primaryInputImageName:(NSString *)primaryInputImageName
             secondaryInputImageName:(NSString *)secondaryInputImageName
                     outputImageName:(NSString *)outputImageName
                outputImageReadCount:(NSUInteger)outputImageReadCount {
  if (self = [super init]) {
    _binaryKernel = binaryKernel;
    _primaryInputImageName = primaryInputImageName;
    _secondaryInputImageName = secondaryInputImageName;
    _outputImageName = outputImageName;
    _outputImageReadCount = outputImageReadCount;
  }
  return self;
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(nullable MPSImage *)secondaryInputImage
              inputParameters:(nullable NSArray *)inputParameters
                  outputImage:(MPSImage *)outputImage {
  if (self.outputImageReadCount > 0 && [outputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *) outputImage).readCount = self.outputImageReadCount;
  }

  if (self.unaryKernel) {
    LTParameterAssert(secondaryInputImage == nil, @"Valid secondaryInputImage is provided for a "
                      "unary kernel");
    LTParameterAssert(inputParameters == nil, @"Valid inputParameters are provided for a "
                      "non-parametric unary kernel");
    [self.unaryKernel encodeToCommandBuffer:commandBuffer inputImage:primaryInputImage
                                outputImage:outputImage];
  } else if (self.parametricUnaryKernel) {
    LTParameterAssert(secondaryInputImage == nil, @"Valid secondaryInputImage is provided for a "
                      "unary kernel");
    LTParameterAssert(inputParameters.count == self.inputParameterGlobalNames.count, @"Expected "
                      "inputParameters array with %lu members, got %lu",
                      (unsigned long)self.inputParameterGlobalNames.count,
                      (unsigned long)inputParameters.count);

    auto inputParameterKernelNames = self.parametricUnaryKernel.inputParameterKernelNames;
    auto namedParameters = [NSDictionary dictionaryWithObjects:inputParameters
                                                       forKeys:inputParameterKernelNames];
    [self.parametricUnaryKernel encodeToCommandBuffer:commandBuffer inputImage:primaryInputImage
                                      inputParameters:namedParameters outputImage:outputImage];
  } else {
    LTParameterAssert(secondaryInputImage, @"Must provide non-null secondaryInputImage for a "
                      "binary kernel");
    LTParameterAssert(inputParameters == nil, @"Valid inputParameters are provided for a "
                      "non-parametric binary kernel");
    [self.binaryKernel encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
                         secondaryInputImage:secondaryInputImage outputImage:outputImage];
  }
}

- (MTLSize)outputSizeForPrimaryInputSize:(MTLSize)primaryInputSize
                      secondaryInputSize:(MTLSize)secondaryInputSize {
  MTLSize size;
  if (self.unaryKernel) {
    size = [self.unaryKernel outputSizeForInputSize:primaryInputSize];
  } else if (self.parametricUnaryKernel) {
    size = [self.parametricUnaryKernel outputSizeForInputSize:primaryInputSize];
  } else {
    size = [self.binaryKernel outputSizeForPrimaryInputSize:primaryInputSize
                                         secondaryInputSize:secondaryInputSize];
  }
  return size;
}

@end

NS_ASSUME_NONNULL_END

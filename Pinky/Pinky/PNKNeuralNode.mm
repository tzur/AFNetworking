// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKNeuralNode.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKNeuralNode ()

/// Unary kernel as set by initializer. Exaxctly one of \c unaryKernel and \c binaryKernel
/// properties is non-nil.
@property (readonly, nonatomic, nullable) id<PNKUnaryKernel> unaryKernel;

/// Binary kernel as set by initializer. Exaxctly one of \c unaryKernel and \c binaryKernel
/// properties is non-nil.
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
                  outputImage:(MPSImage *)outputImage {
  if (self.outputImageReadCount > 0 && [outputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *) outputImage).readCount = self.outputImageReadCount;
  }

  if (self.unaryKernel) {
    LTParameterAssert(secondaryInputImage == nil, @"Valid secondaryInputImage is provided for a "
                      "unary kernel");
    [self.unaryKernel encodeToCommandBuffer:commandBuffer inputImage:primaryInputImage
                                outputImage:outputImage];
  } else {
    LTParameterAssert(secondaryInputImage, @"Must provide non-null secondaryInputImage for a "
                      "binary kernel");
    [self.binaryKernel encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
                         secondaryInputImage:secondaryInputImage outputImage:outputImage];
  }
}

- (MTLSize)outputSizeForPrimaryInputSize:(MTLSize)primaryInputSize
                      secondaryInputSize:(MTLSize)secondaryInputSize {
  if (self.unaryKernel) {
    return [self.unaryKernel outputSizeForInputSize:primaryInputSize];
  } else {
    return [self.binaryKernel outputSizeForPrimaryInputSize:primaryInputSize
                                         secondaryInputSize:secondaryInputSize];
  }
}

@end

#endif

NS_ASSUME_NONNULL_END

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKConstantAlpha.h"

NS_ASSUME_NONNULL_BEGIN

/// MTLFunctionConstantValues is not supported in simulator for Xcode 8. Solved in Xcode 9.
#if PNK_USE_MPS

@interface PNKConstantAlpha ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel compiled state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

@end

@implementation PNKConstantAlpha

@synthesize inputFeatureChannels = _inputFeatureChannels;

/// Kernel function name.
static NSString * const kKernelFunctionName = @"setConstantAlpha";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device alpha:(float)alpha {
  if (self = [super init]) {
    _device = device;
    _inputFeatureChannels = 4;

    [self createStateWithAlpha:alpha];
  }
  return self;
}

- (void)createStateWithAlpha:(float)alpha {
  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  [functionConstants setConstantValue:&alpha type:MTLDataTypeFloat withName:@"alpha"];
  _state = PNKCreateComputeStateWithConstants(self.device, kKernelFunctionName, functionConstants);
}

#pragma mark -
#pragma mark PNKUnaryKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  MTLSize workingSpaceSize = {inputImage.width, inputImage.height, 1};
  PNKComputeDispatchWithDefaultThreads(self.state, commandBuffer, @[inputImage], @[outputImage],
                                       kKernelFunctionName, workingSpaceSize);
}

- (void)verifyParametersWithInputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.width == outputImage.width,
                    @"Input image width must match output image width. got: (%lu, %lu)",
                    (unsigned long)inputImage.width, (unsigned long)outputImage.width);
  LTParameterAssert(inputImage.height == outputImage.height,
                    @"Input image height must match output image height. got: (%lu, %lu)",
                    (unsigned long)inputImage.height, (unsigned long)outputImage.height);
  LTParameterAssert(inputImage.featureChannels == 4, @"Input image feature channels count must be "
                    "4. got: %lu", (unsigned long)inputImage.featureChannels);
  LTParameterAssert(outputImage.featureChannels == 4, @"Output image feature channels count must "
                    "be 4. got: %lu", (unsigned long)outputImage.featureChannels);
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

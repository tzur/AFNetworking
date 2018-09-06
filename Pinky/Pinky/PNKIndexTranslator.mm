// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKIndexTranslator.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKIndexTranslator ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

/// Buffer for passing the translation table to Metal.
@property (readonly, nonatomic) id<MTLBuffer> bufferForTranslationTable;

@end

@implementation PNKIndexTranslator

/// Kernel function name.
static NSString * const kKernelFunctionName = @"translatePixelValue";

@synthesize inputFeatureChannels = _inputFeatureChannels;

- (instancetype)initWithDevice:(id<MTLDevice>)device
              translationTable:(const std::array<uchar, 256> &)translationTable {
  if (self = [super init]) {
    _device = device;
    _inputFeatureChannels = 1;
    [self createState];
    [self createBufferFromTranslationTable:translationTable];
  }
  return self;
}

- (void)createState {
  _state = PNKCreateComputeState(self.device, kKernelFunctionName);
}

- (void)createBufferFromTranslationTable:(const std::array<uchar, 256> &)translationTable {
  NSUInteger bufferLength = (NSUInteger)translationTable.size() * sizeof(half_float::half);
  _bufferForTranslationTable =
      [self.device newBufferWithLength:bufferLength options:MTLResourceCPUCacheModeWriteCombined];
  auto bufferData = (half_float::half *)self.bufferForTranslationTable.contents;
  for (int i = 0; i < (int)translationTable.size(); ++i) {
    bufferData[i] = (half_float::half)(translationTable[i]) / (half_float::half)255.0;
  }
}

#pragma mark -
#pragma mark PNKUnaryImageKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  MTLSize workingSpaceSize = outputImage.pnk_textureArraySize;

  MTBComputeDispatchWithDefaultThreads(self.state, commandBuffer, @[self.bufferForTranslationTable],
                                       @[inputImage], @[outputImage], kKernelFunctionName,
                                       workingSpaceSize);
}

- (void)verifyParametersWithInputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.featureChannels == 1, @"Input image must have 1 feature channel, "
                    "got: %lu", (unsigned long)inputImage.featureChannels);
  LTParameterAssert(outputImage.featureChannels == 1, @"Output image must have 1 feature channel, "
                    "got: %lu", (unsigned long)outputImage.featureChannels);
  LTParameterAssert(outputImage.width == inputImage.width, @"Output image width must equal input "
                    "image width, got: (%lu, %lu)", (unsigned long)outputImage.width,
                    (unsigned long)inputImage.width);
  LTParameterAssert(outputImage.height == inputImage.height, @"Output image height must equal "
                    "input image height, got: (%lu, %lu)", (unsigned long)outputImage.height,
                    (unsigned long)inputImage.height);
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

NS_ASSUME_NONNULL_END

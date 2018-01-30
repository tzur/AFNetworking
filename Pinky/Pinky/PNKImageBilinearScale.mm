// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageBilinearScale.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKImageBilinearScale ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

/// Number of feature channels per pixel in the input image.
@property (readonly, nonatomic) NSUInteger inputFeatureChannels;

/// Number of feature channels per pixel in the output image.
@property (readonly, nonatomic) NSUInteger outputFeatureChannels;

/// Buffer for passing inverse output texture size.
@property (readonly, nonatomic) id<MTLBuffer> bufferForInverseOutputTextureSize;

@end

@implementation PNKImageBilinearScale

/// Name of kernel function for scaling a texture.
static NSString * const kKernelFunctionBilinearScale = @"bilinearScale";

- (instancetype)initWithDevice:(id<MTLDevice>)device
          inputFeatureChannels:(NSUInteger)inputFeatureChannels
         outputFeatureChannels:(NSUInteger)outputFeatureChannels {
  if (self = [super init]) {
    _device = device;
    _inputFeatureChannels = inputFeatureChannels;
    _outputFeatureChannels = outputFeatureChannels;

    [self createState];
    [self createBuffers];
  }
  return self;
}

- (void)createState {
  bool yToRGBA;

  if ((self.inputFeatureChannels == 1 && self.outputFeatureChannels == 1) ||
      (self.inputFeatureChannels == 3 && self.outputFeatureChannels == 3) ||
      (self.inputFeatureChannels == 3 && self.outputFeatureChannels == 4) ||
      (self.inputFeatureChannels == 4 && self.outputFeatureChannels == 3) ||
      (self.inputFeatureChannels == 4 && self.outputFeatureChannels == 4)) {
    yToRGBA = false;
  } else if ((self.inputFeatureChannels == 1 && self.outputFeatureChannels == 3) ||
             (self.inputFeatureChannels == 1 && self.outputFeatureChannels == 4)){
    yToRGBA = true;
  } else {
    LTParameterAssert(NO, @"Invalid input/output feature channels combination - (%lu, %lu)",
                      (unsigned long)self.inputFeatureChannels,
                      (unsigned long)self.outputFeatureChannels);
  }

  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  [functionConstants setConstantValue:&yToRGBA type:MTLDataTypeBool
                             withName:@"yToRGBA"];
  _state = PNKCreateComputeStateWithConstants(self.device, kKernelFunctionBilinearScale,
                                              functionConstants);
}

- (void)createBuffers {
  _bufferForInverseOutputTextureSize =
      [self.device newBufferWithLength:sizeof(float) * 2
                               options:MTLResourceCPUCacheModeWriteCombined];
}

#pragma mark -
#pragma mark Encode
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  MTLSize outputTextureSize = {outputImage.width, outputImage.height, 1};
  [self fillBufferWithInverseOutputTextureSize:outputTextureSize];

  NSArray<id<MTLBuffer>> *buffers = @[self.bufferForInverseOutputTextureSize];

  MTLSize workingSpaceSize = {outputImage.width, outputImage.height, 1};

  PNKComputeDispatchWithDefaultThreads(self.state, commandBuffer, buffers, @[inputImage],
                                       @[outputImage], kKernelFunctionBilinearScale,
                                       workingSpaceSize);
}

- (void)verifyParametersWithInputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.featureChannels == self.inputFeatureChannels,
                    @"Input image featureChannels must be %lu, got: %lu",
                    (unsigned long)self.inputFeatureChannels,
                    (unsigned long)inputImage.featureChannels);
  LTParameterAssert(outputImage.featureChannels == self.outputFeatureChannels,
                    @"Output image featureChannels must be %lu, got: %lu",
                    (unsigned long)self.outputFeatureChannels,
                    (unsigned long)outputImage.featureChannels);
}

- (void)fillBufferWithInverseOutputTextureSize:(MTLSize)outputTextureSize {
  float *bufferContents = (float *)self.bufferForInverseOutputTextureSize.contents;
  bufferContents[0] = 1.0 / (float)outputTextureSize.width;
  bufferContents[1] = 1.0 / (float)outputTextureSize.height;
}

@end

#endif

NS_ASSUME_NONNULL_END

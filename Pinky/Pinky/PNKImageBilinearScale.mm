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

/// Buffer for passing inverse output texture size.
@property (readonly, nonatomic) id<MTLBuffer> bufferForInverseOutputTextureSize;

/// Buffer for passing the indication for wether Y->RGBA transformation is needed.
@property (readonly, nonatomic) id<MTLBuffer> bufferForColorTransformType;

@end

@implementation PNKImageBilinearScale

/// Name of kernel function for scaling a texture.
static NSString * const kKernelFunctionBilinearScale = @"bilinearScale";

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  if (self = [super init]) {
    _device = device;

    [self createState];
    [self createBuffers];
  }
  return self;
}

- (void)createState {
  _state = PNKCreateComputeState(self.device, kKernelFunctionBilinearScale);
}

- (void)createBuffers {
  _bufferForInverseOutputTextureSize =
      [self.device newBufferWithLength:sizeof(float) * 2
                               options:MTLResourceCPUCacheModeWriteCombined];
  _bufferForColorTransformType =
      [self.device newBufferWithLength:sizeof(pnk::ColorTransformType)
                               options:MTLResourceCPUCacheModeWriteCombined];
}

#pragma mark -
#pragma mark Encode
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self fillBuffersWithInputImage:inputImage outputImage:outputImage];

  NSArray<id<MTLBuffer>> *buffers = @[
    self.bufferForInverseOutputTextureSize,
    self.bufferForColorTransformType
  ];

  MTLSize workingSpaceSize = {outputImage.width, outputImage.height, 1};

  MTBComputeDispatchWithDefaultThreads(self.state, commandBuffer, buffers, @[inputImage],
                                       @[outputImage], kKernelFunctionBilinearScale,
                                       workingSpaceSize);
}

- (void)fillBuffersWithInputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  float *inverseOutputTextureSize = (float *)self.bufferForInverseOutputTextureSize.contents;
  inverseOutputTextureSize[0] = 1.0 / (float)outputImage.width;
  inverseOutputTextureSize[1] = 1.0 / (float)outputImage.height;

  pnk::ColorTransformType *colorTransformType =
      (pnk::ColorTransformType *)self.bufferForColorTransformType.contents;

  if ((inputImage.featureChannels == 1 && outputImage.featureChannels == 1) ||
      (inputImage.featureChannels == 3 && outputImage.featureChannels == 3) ||
      (inputImage.featureChannels == 3 && outputImage.featureChannels == 4) ||
      (inputImage.featureChannels == 4 && outputImage.featureChannels == 3) ||
      (inputImage.featureChannels == 4 && outputImage.featureChannels == 4)) {
    colorTransformType[0] = pnk::ColorTransformTypeNone;
  } else if ((inputImage.featureChannels == 1 && outputImage.featureChannels == 3) ||
             (inputImage.featureChannels == 1 && outputImage.featureChannels == 4)){
    colorTransformType[0] = pnk::ColorTransformTypeYToRGBA;
  } else if ((inputImage.featureChannels == 3 && outputImage.featureChannels == 1) ||
             (inputImage.featureChannels == 4 && outputImage.featureChannels == 1)) {
    colorTransformType[0] = pnk::ColorTransformTypeRGBAToY;
  } else {
    LTParameterAssert(NO, @"Invalid input/output feature channels combination - (%lu, %lu)",
                      (unsigned long)inputImage.featureChannels,
                      (unsigned long)outputImage.featureChannels);
  }
}

@end

#endif

NS_ASSUME_NONNULL_END

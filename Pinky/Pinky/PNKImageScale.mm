// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageScale.h"

NS_ASSUME_NONNULL_BEGIN

using namespace pnk_simd;

@interface PNKImageScale ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

/// Buffer for passing input rectangle.
@property (readonly, nonatomic) id<MTLBuffer> bufferForInputRectangle;

/// Buffer for passing output rectangle.
@property (readonly, nonatomic) id<MTLBuffer> bufferForOutputRectangle;

/// Buffer for passing the inverse of output rectangle size.
@property (readonly, nonatomic) id<MTLBuffer> bufferForOutputRectangleInverseSize;

/// Buffer for passing the indication for wether Y->RGBA transformation is needed.
@property (readonly, nonatomic) id<MTLBuffer> bufferForColorTransformType;

@end

@implementation PNKImageScale

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
  // Buffer resource options.
  static MTLResourceOptions kResourceOptions = MTLResourceCPUCacheModeWriteCombined;

  _bufferForInputRectangle = [self.device newBufferWithLength:sizeof(pnk::Rect2f)
                                                      options:kResourceOptions];
  _bufferForOutputRectangle = [self.device newBufferWithLength:sizeof(pnk::Rect2ui)
                                                       options:kResourceOptions];
  _bufferForOutputRectangleInverseSize = [self.device newBufferWithLength:sizeof(float2)
                                                                  options:kResourceOptions];
  _bufferForColorTransformType = [self.device newBufferWithLength:sizeof(pnk::ColorTransformType)
                                                          options:kResourceOptions];
}

#pragma mark -
#pragma mark Encode
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self encodeToCommandBuffer:commandBuffer
                   inputImage:inputImage inputRegion:{{0, 0, 0}, inputImage.pnk_size}
                  outputImage:outputImage outputRegion:{{0, 0, 0}, outputImage.pnk_size}];
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage inputRegion:(MTLRegion)inputRegion
                  outputImage:(MPSImage *)outputImage outputRegion:(MTLRegion)outputRegion {
  [self validateInputImage:inputImage inputRegion:inputRegion outputImage:outputImage
              outputRegion:outputRegion];
  [self fillBuffersWithInputImage:inputImage inputRegion:inputRegion outputImage:outputImage
                     outputRegion:outputRegion];

  NSArray<id<MTLBuffer>> *buffers = @[
    self.bufferForInputRectangle,
    self.bufferForOutputRectangle,
    self.bufferForOutputRectangleInverseSize,
    self.bufferForColorTransformType
  ];

  MTLSize workingSpaceSize = {outputRegion.size.width, outputRegion.size.height, 1};

  MTBComputeDispatchWithDefaultThreads(self.state, commandBuffer, buffers, @[inputImage],
                                       @[outputImage], kKernelFunctionBilinearScale,
                                       workingSpaceSize);
}

- (void)validateInputImage:(MPSImage *)inputImage inputRegion:(MTLRegion)inputRegion
               outputImage:(MPSImage *)outputImage outputRegion:(MTLRegion)outputRegion {
  LTParameterAssert(inputRegion.origin.x + inputRegion.size.width <= inputImage.width &&
                    inputRegion.origin.y + inputRegion.size.height <= inputImage.height,
                    @"Input region must be contained in the input image; got (%lu, %lu, %lu, %lu) "
                    "for image size  (%lu, %lu)", (unsigned long)inputRegion.origin.x,
                    (unsigned long)inputRegion.origin.y, (unsigned long)inputRegion.size.width,
                    (unsigned long)inputRegion.size.height, (unsigned long)inputImage.width,
                    (unsigned long)inputImage.height);
  LTParameterAssert(outputRegion.origin.x + outputRegion.size.width <= outputImage.width &&
                    outputRegion.origin.y + outputRegion.size.height <= outputImage.height,
                    @"Output region must be contained in the output image; got "
                    "(%lu, %lu, %lu, %lu) for image size (%lu, %lu)",
                    (unsigned long)outputRegion.origin.x, (unsigned long)outputRegion.origin.y,
                    (unsigned long)outputRegion.size.width, (unsigned long)outputRegion.size.height,
                    (unsigned long)outputImage.width, (unsigned long)outputImage.height);
}

- (void)fillBuffersWithInputImage:(MPSImage *)inputImage inputRegion:(MTLRegion)inputRegion
                      outputImage:(MPSImage *)outputImage outputRegion:(MTLRegion)outputRegion {
  auto inputRectangle = (pnk::Rect2f *)self.bufferForInputRectangle.contents;
  *inputRectangle = {
    make_float2(inputRegion.origin.x, inputRegion.origin.y),
    make_float2(inputRegion.size.width, inputRegion.size.height)
  };

  auto outputRectangle = (pnk::Rect2ui *)self.bufferForOutputRectangle.contents;
  *outputRectangle = {
    make_uint2((unsigned int)outputRegion.origin.x, (unsigned int)outputRegion.origin.y),
    make_uint2((unsigned int)outputRegion.size.width, (unsigned int)outputRegion.size.height)
  };

  auto outputRectangleInverseSize = (float2 *)self.bufferForOutputRectangleInverseSize.contents;
  *outputRectangleInverseSize = make_float2(1.0f / outputRegion.size.width,
                                            1.0f / outputRegion.size.height);

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

NS_ASSUME_NONNULL_END

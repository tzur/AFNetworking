// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionLayerFusion.h"

#import "PNKImageMotionLayerType.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKImageMotionLayerFusion ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode operation \c device.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

/// Buffer for passing the inverse of the texture size.
@property (readonly, nonatomic) id<MTLBuffer> bufferForInverseImageSize;

@end

@implementation PNKImageMotionLayerFusion

/// Name of kernel function for performing the layer fusion operation.
static NSString * const kKernelFunction = @"layerFusion";

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  if (self = [super init]) {
    _device = device;

    [self createState];
    [self createBuffers];
  }
  return self;
}

- (void)createState {
  _state = PNKCreateComputeState(self.device, kKernelFunction);
}

- (void)createBuffers {
  _bufferForInverseImageSize = [self.device newBufferWithLength:sizeof(float) * 2
                                options:MTLResourceCPUCacheModeWriteCombined];
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
       inputSegmentationImage:(MPSImage *)inputSegmentationImage
      inputDisplacementImages:(NSArray<MPSImage *> *)inputDisplacementImages
      outputSegmentationImage:(MPSImage *)outputSegmentationImage
      outputDisplacementImage:(MPSImage *)outputDisplacementImage {
  [self verifyParametersWithInputSegmentationImage:inputSegmentationImage
                           inputDisplacementImages:inputDisplacementImages
                           outputSegmentationImage:outputSegmentationImage
                           outputDisplacementImage:outputDisplacementImage];

  [self fillBufferWithInputImageSize:inputSegmentationImage.pnk_size];

  MTLSize workingSpaceSize = inputSegmentationImage.pnk_size;

  auto inputImages = [@[inputSegmentationImage]
                      arrayByAddingObjectsFromArray:inputDisplacementImages];
  auto outputImages = @[outputSegmentationImage, outputDisplacementImage];

  MTBComputeDispatchWithDefaultThreads(self.state, commandBuffer, @[self.bufferForInverseImageSize],
                                       inputImages, outputImages, kKernelFunction,
                                       workingSpaceSize);
}

- (void)verifyParametersWithInputSegmentationImage:(MPSImage *)inputSegmentationImage
                           inputDisplacementImages:(NSArray<MPSImage *> *)inputDisplacementImages
                           outputSegmentationImage:(MPSImage *)outputSegmentationImage
                           outputDisplacementImage:(MPSImage *)outputDisplacementImage {
  LTParameterAssert(inputSegmentationImage.featureChannels == 1, @"Input segmentation image must "
                    "have 1 feature channel, got %lu",
                    (unsigned long)inputSegmentationImage.featureChannels);

  LTParameterAssert(inputDisplacementImages.count == (NSUInteger)pnk::ImageMotionLayerTypeMax - 1,
                    "Input displacement images array must have %lu members, got %lu",
                    (unsigned long)pnk::ImageMotionLayerTypeMax - 1,
                    (unsigned long)inputDisplacementImages.count);
  for (NSUInteger i = 0; i < inputDisplacementImages.count; ++i) {
    LTParameterAssert(inputDisplacementImages[i].width == inputSegmentationImage.width, @"The "
                      "width of input displacement image #%lu must be equal to the width of the "
                      "input segmentation image (%lu), got %lu", (unsigned long)i,
                      (unsigned long)inputSegmentationImage.width,
                      (unsigned long)inputDisplacementImages[i].width);
    LTParameterAssert(inputDisplacementImages[i].height == inputSegmentationImage.height, @"The "
                      "height of input displacement image #%lu must be equal to the height of the "
                      "input segmentation image (%lu), got %lu", (unsigned long)i,
                      (unsigned long)inputSegmentationImage.height,
                      (unsigned long)inputDisplacementImages[i].height);
    LTParameterAssert(inputDisplacementImages[i].featureChannels == 2, @"Input displacement image "
                      "#%lu must have 2 feature channels, got %lu", (unsigned long)i,
                      (unsigned long)inputDisplacementImages[i].featureChannels);
  }

  LTParameterAssert(outputSegmentationImage.width == inputSegmentationImage.width, @"The width of "
                    "the output segmentation image must be equal to the width of the input "
                    "segmentation image (%lu), got %lu",
                    (unsigned long)inputSegmentationImage.width,
                    (unsigned long)outputSegmentationImage.width);
  LTParameterAssert(outputSegmentationImage.height == inputSegmentationImage.height, @"The height "
                    "of the output segmentation image must be equal to the width of the input "
                    "segmentation image (%lu), got %lu",
                    (unsigned long)inputSegmentationImage.height,
                    (unsigned long)outputSegmentationImage.height);
  LTParameterAssert(outputSegmentationImage.featureChannels == 1, @"Output segmentation image "
                    "must have 1 feature channel, got %lu",
                    (unsigned long)outputSegmentationImage.featureChannels);

  LTParameterAssert(outputDisplacementImage.width == inputSegmentationImage.width, @"The width of "
                    "the output displacement image must be equal to the width of the input "
                    "segmentation image (%lu), got %lu",
                    (unsigned long)inputSegmentationImage.width,
                    (unsigned long)outputDisplacementImage.width);
  LTParameterAssert(outputDisplacementImage.height == inputSegmentationImage.height, @"The height "
                    "of the output displacement image must be equal to the width of the input "
                    "segmentation image (%lu), got %lu",
                    (unsigned long)inputSegmentationImage.height,
                    (unsigned long)outputDisplacementImage.height);
  LTParameterAssert(outputDisplacementImage.featureChannels == 2, @"Output displacement image "
                    "must have 2 feature channels, got %lu",
                    (unsigned long)outputDisplacementImage.featureChannels);
}

- (void)fillBufferWithInputImageSize:(MTLSize)inputImageSize {
  float *inverseOutputTextureSize = (float *)self.bufferForInverseImageSize.contents;
  inverseOutputTextureSize[0] = 1.0 / (float)inputImageSize.width;
  inverseOutputTextureSize[1] = 1.0 / (float)inputImageSize.height;
}

@end

#endif

NS_ASSUME_NONNULL_END

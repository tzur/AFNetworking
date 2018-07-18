// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionDisplacementProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>

#import "MPSImage+Factory.h"
#import "PNKAvailability.h"
#import "PNKDeviceAndCommandQueue.h"
#import "PNKImageMotionLayer.h"
#import "PNKImageMotionLayerFactory.h"
#import "PNKImageMotionLayerFusion.h"
#import "PNKImageMotionLayerType.h"
#import "PNKOpenCVExtensions.h"
#import "PNKPixelBufferUtils.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKImageMotionDisplacementProcessor ()

/// Array of layers. Each layer is used to calculate its corresponding displacements map.
@property (nonatomic) NSArray<id<PNKImageMotionLayer>> *layers;

/// Array of layer displacement images.
@property (nonatomic) NSArray<MPSImage *> *displacementImages;

/// Device to encode the operations of this processor.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Command queue used to create command buffer objects encoding the operations of this processor.
@property (readonly, nonatomic) id<MTLCommandQueue> commandQueue;

@end

@implementation PNKImageMotionDisplacementProcessor

- (nullable instancetype)initWithSegmentation:(lt::Ref<CVPixelBufferRef>)segmentation
                                        error:(NSError * __autoreleasing *)error {
  if (self = [super init]) {
    _device = PNKDefaultDevice();
    _commandQueue = PNKDefaultCommandQueue();
    _segmentation = segmentation;
    [self createLayers];

    if (!PNKSupportsMTLDevice(self.device)) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                               description:@"MPS framework is not supported on GPU family %@",
                  self.device.name];
      }
      return nil;
    }
  } else {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Failed creating super initializer"];
    }
    return nil;
  }
  return self;
}

- (void)createLayers {
  auto imageWidth = (int)CVPixelBufferGetWidth(self.segmentation.get());
  auto imageHeight = (int)CVPixelBufferGetHeight(self.segmentation.get());
  cv::Size imageSize(imageWidth, imageHeight);

  auto layers = [NSMutableArray array];
  auto displacementImages = [NSMutableArray array];
  for (uchar layerType = (uchar)pnk::ImageMotionLayerTypeMax - 1;
       layerType > (uchar)pnk::ImageMotionLayerTypeNone; --layerType) {
    auto layer = [PNKImageMotionLayerFactory layerWithType:(pnk::ImageMotionLayerType)layerType
                                                 imageSize:imageSize];
    [layers addObject:layer];

    auto layerDisplacementImage = [MPSImage pnk_float16ImageWithDevice:self.device width:imageWidth
                                                                height:imageHeight channels:2];
    [displacementImages addObject:layerDisplacementImage];
  }

  self.layers = layers;
  [self updateLayers];

  self.displacementImages = displacementImages;
}

- (void)updateLayers {
  LTCVPixelBufferImageForReading(self.segmentation.get(), ^(const cv::Mat &segmentationMap) {
    for (id<PNKImageMotionLayer> layer in self.layers) {
      if ([layer conformsToProtocol:@protocol(PNKImageMotionSegmentationAwareLayer)]) {
        [(id<PNKImageMotionSegmentationAwareLayer>)layer updateWithSegmentationMap:segmentationMap];
      }
    }
  });
}

- (void)setSegmentation:(lt::Ref<CVPixelBufferRef>)segmentation {
  bool sizeChanged =
      CVPixelBufferGetWidth(segmentation.get()) != CVPixelBufferGetWidth(self.segmentation.get()) ||
      CVPixelBufferGetHeight(segmentation.get()) != CVPixelBufferGetHeight(self.segmentation.get());

  _segmentation = segmentation;

  if (sizeChanged) {
    [self createLayers];
  } else {
    [self updateLayers];
  }
}

- (void)displacements:(CVPixelBufferRef)displacements
   andNewSegmentation:(CVPixelBufferRef)newSegmentation
              forTime:(NSTimeInterval)time {
  [self validateDisplacements:displacements andNewSegmentation:newSegmentation];

  auto width = CVPixelBufferGetWidth(self.segmentation.get());
  auto height = CVPixelBufferGetHeight(self.segmentation.get());

  cv::Mat2hf displacementMat((int)height, (int)width);
  for (NSUInteger i = 0; i < self.layers.count; ++i) {
    [self.layers[i] displacements:&displacementMat forTime:time];
    PNKCopyMatToMTLTexture(self.displacementImages[i].texture, displacementMat);
  }

  auto inputSegmentationImage = PNKImageFromPixelBuffer(self.segmentation.get(), self.device);

  auto outputSegmentationImage = PNKImageFromPixelBuffer(newSegmentation, self.device);
  auto outputDisplacementImage = PNKImageFromPixelBuffer(displacements, self.device);

  auto commandBuffer = [self.commandQueue commandBuffer];
  auto layerFusion = [[PNKImageMotionLayerFusion alloc] initWithDevice:self.device];
  [layerFusion encodeToCommandBuffer:commandBuffer inputSegmentationImage:inputSegmentationImage
             inputDisplacementImages:self.displacementImages
             outputSegmentationImage:outputSegmentationImage
             outputDisplacementImage:outputDisplacementImage];

  [commandBuffer commit];
  [commandBuffer waitUntilCompleted];
}

- (void)validateDisplacements:(CVPixelBufferRef)displacements
           andNewSegmentation:(CVPixelBufferRef)newSegmentation {
  auto inputWidth = CVPixelBufferGetWidth(self.segmentation.get());
  auto inputHeight = CVPixelBufferGetHeight(self.segmentation.get());

  auto displacementsWidth = CVPixelBufferGetWidth(displacements);
  LTParameterAssert(displacementsWidth == inputWidth, @"Expected displacements buffer width %lu, "
                    "got %lu", (unsigned long)inputWidth, (unsigned long)displacementsWidth);
  auto displacementsHeight = CVPixelBufferGetHeight(displacements);
  LTParameterAssert(displacementsHeight == inputHeight, @"Expected displacements buffer height "
                    "%lu, got %lu", (unsigned long)inputHeight, (unsigned long)displacementsHeight);
  auto displacementsFormat = CVPixelBufferGetPixelFormatType(displacements);
  LTParameterAssert(displacementsFormat == kCVPixelFormatType_TwoComponent16Half, @"Expected "
                    "displacements buffer format kCVPixelFormatType_TwoComponent16Half, got %lu",
                    (unsigned long)displacementsFormat);

  auto segmentationWidth = CVPixelBufferGetWidth(newSegmentation);
  LTParameterAssert(segmentationWidth == inputWidth, @"Expected segmentation buffer width %lu, "
                    "got %lu", (unsigned long)inputWidth, (unsigned long)segmentationWidth);
  auto segmentationHeight = CVPixelBufferGetHeight(newSegmentation);
  LTParameterAssert(segmentationHeight == inputHeight, @"Expected segmentation buffer height "
                    "%lu, got %lu", (unsigned long)inputHeight, (unsigned long)segmentationHeight);
  auto segmentationFormat = CVPixelBufferGetPixelFormatType(newSegmentation);
  LTParameterAssert(segmentationFormat == kCVPixelFormatType_OneComponent8, @"Expected "
                    "segmentation buffer format kCVPixelFormatType_OneComponent8, got %lu",
                    (unsigned long)segmentationFormat);
}

@end

#else

@implementation PNKImageMotionDisplacementProcessor

- (nullable instancetype)initWithSegmentation:(__unused lt::Ref<CVPixelBufferRef>)segmentation
                                        error:(NSError * __autoreleasing *)error {
  if (error) {
    *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                           description:@"Supported on device only"];
  }
  return nil;
}

- (void)displacements:(__unused CVPixelBufferRef)displacements
   andNewSegmentation:(__unused CVPixelBufferRef)newSegmentation
              forTime:(__unused NSTimeInterval)time {
}

@end

#endif

NS_ASSUME_NONNULL_END

// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionSegmentationProcessor.h"

#import "PNKAvailability.h"
#import "PNKDeviceAndCommandQueue.h"
#import "PNKImageMotionSegmentationNetwork.h"
#import "PNKPixelBufferUtils.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKImageMotionSegmentationProcessor ()

/// Neural network performing the segmentation.
@property (readonly, nonatomic) PNKImageMotionSegmentationNetwork *segmentationNetwork;

/// Device to encode the operations of this processor.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Command queue used to create command buffer objects used to encode the operations of this
/// processor.
@property (readonly, nonatomic) id<MTLCommandQueue> commandQueue;

@end

@implementation PNKImageMotionSegmentationProcessor

- (nullable instancetype)initWithNetworkModel:(NSURL *)networkModelURL
                                        error:(NSError *__autoreleasing *)error {
  if (self = [super init]) {
    _device = PNKDefaultDevice();
    _commandQueue = PNKDefaultCommandQueue();

    if (!PNKSupportsMTLDevice(self.device)) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                               description:@"MPS framework is not supported on GPU family %@",
                  self.device.name];
      }
      return nil;
    }

    _segmentationNetwork = [[PNKImageMotionSegmentationNetwork alloc] initWithDevice:self.device
                                                                     networkModelURL:networkModelURL
                                                                               error:error];
    if (!self.segmentationNetwork) {
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

- (void)segmentWithInput:(CVPixelBufferRef)input output:(CVPixelBufferRef)output {
  [self verifyInputBuffer:input outputBuffer:output];

  auto inputImage = PNKImageFromPixelBuffer(input, self.device,
                                            self.segmentationNetwork.inputChannels);
  auto outputImage = PNKImageFromPixelBuffer(output, self.device);

  auto commandBuffer = [self.commandQueue commandBuffer];
  [self.segmentationNetwork encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                      outputImage:outputImage];
  [commandBuffer commit];
  [commandBuffer waitUntilCompleted];
}

- (void)verifyInputBuffer:(CVPixelBufferRef)input outputBuffer:(CVPixelBufferRef)output {
  PNKAssertPixelBufferFormatChannelCount(output, 1);
  PNKAssertPixelBufferFormatChannelCount(input, 4);

  auto inputWidth = CVPixelBufferGetWidth(input);
  auto inputHeight = CVPixelBufferGetHeight(input);
  auto outputWidth = CVPixelBufferGetWidth(output);
  auto outputHeight = CVPixelBufferGetHeight(output);
  LTParameterAssert(inputWidth == outputWidth, @"Output width must be equal to input width (%lu), "
                    "got %lu", inputWidth, outputWidth);
  LTParameterAssert(inputHeight == outputHeight, @"Output height must be equal to input height "
                    "(%lu), got %lu", inputHeight, outputHeight);
}

@end

#else

@implementation PNKImageMotionSegmentationProcessor

- (nullable instancetype)initWithNetworkModel:(__unused NSURL *)networkModelURL
                                        error:(__unused NSError *__autoreleasing *)error {
  if (error) {
    *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                           description:@"Supported on device only"];
  }
  return nil;
}

- (void)segmentWithInput:(__unused CVPixelBufferRef)input output:(__unused CVPixelBufferRef)output {
}

@end

#endif

NS_ASSUME_NONNULL_END

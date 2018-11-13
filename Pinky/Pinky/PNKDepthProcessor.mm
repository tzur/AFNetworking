// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKDepthProcessor.h"

#import <MetalToolbox/MPSTemporaryImage+Factory.h>

#import "PNKAvailability.h"
#import "PNKDeviceAndCommandQueue.h"
#import "PNKImageScale.h"
#import "PNKNetworkSchemeFactory.h"
#import "PNKPixelBufferUtils.h"
#import "PNKRunnableNeuralNetwork.h"
#import "PNKUnitRangeNormalization.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKDepthProcessor ()

/// Neural network performing the segmentation.
@property (readonly, nonatomic) PNKRunnableNeuralNetwork *network;

/// Device to encode this network operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Command queue used to create command buffer objects used to encode this network operation.
@property (readonly, nonatomic) id<MTLCommandQueue> commandQueue;

/// Pinky kernel used to resize the input image in the pre-processing stage.
@property (readonly, nonatomic) PNKImageScale *resizer;

/// Pinky kernel used to normalize the output to the unit range.
@property (readonly, nonatomic) PNKUnitRangeNormalization *normalizer;

/// Serial queue used to perform the operations when the processor's asynchronic API is called.
/// This separate queue is used because encoding the network can take non-negligible time.
@property (readonly, nonatomic) dispatch_queue_t encodingQueue;

@end

@implementation PNKDepthProcessor

- (nullable instancetype)initWithNetworkModel:(NSURL *)networkModelURL
                                        error:(NSError * __autoreleasing *)error {
  if (self = [super init]) {
    _device = PNKDefaultDevice();
    if (![self.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily3_v1]) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                               description:@"MPS framework is not supported on GPU family %@",
                  self.device.name];
      }
      return nil;
    }

    _commandQueue = PNKDefaultCommandQueue();

    auto scheme = [PNKNetworkSchemeFactory schemeWithDevice:self.device coreMLModel:networkModelURL
                                                      error:error];
    if (!scheme) {
      return nil;
    }

    _network = [[PNKRunnableNeuralNetwork alloc] initWithNetworkScheme:*scheme];

    _resizer = [[PNKImageScale alloc] initWithDevice:self.device];
    _normalizer = [[PNKUnitRangeNormalization alloc] initWithDevice:self.device];

    _encodingQueue = dispatch_queue_create("com.lightricks.Pinky.DepthProcessor",
                                           DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);
  }
  return self;
}

- (void)extractDepthWithInput:(CVPixelBufferRef)input output:(CVPixelBufferRef)output
                   completion:(LTCompletionBlock)completion {
  LTParameterAssert(completion, @"Completion block must not be nil");
  [self verifyInputBuffer:input outputBuffer:output];

  dispatch_async(self.encodingQueue, ^{
    [self encodeAndCommitWithInput:input output:output completion:completion];
  });
}

- (void)verifyInputBuffer:(CVPixelBufferRef)input outputBuffer:(CVPixelBufferRef)output {
  auto outputWidth = CVPixelBufferGetWidth(output);
  auto outputHeight = CVPixelBufferGetHeight(output);
  auto inputWidth = CVPixelBufferGetWidth(input);
  auto inputHeight = CVPixelBufferGetHeight(input);
  auto expectedOutputSize = [self outputSizeWithInputSize:CGSizeMake(inputWidth, inputHeight)];
  LTParameterAssert(expectedOutputSize == CGSizeMake(outputWidth, outputHeight), @"output size "
                    "must be (%f, %f), got (%lu, %lu)", expectedOutputSize.width,
                    expectedOutputSize.height, (unsigned long)outputWidth,
                    (unsigned long)outputHeight);
}

- (void)encodeAndCommitWithInput:(CVPixelBufferRef)input output:(CVPixelBufferRef)output
                      completion:(LTCompletionBlock)completion {
  auto inputImage = PNKImageFromPixelBuffer(input, self.device);
  auto outputImage = PNKImageFromPixelBuffer(output, self.device);

  auto commandBuffer = [self.commandQueue commandBuffer];

  auto netInputImage =
      [MPSTemporaryImage mtb_float16TemporaryImageWithCommandBuffer:commandBuffer
                                                              width:outputImage.width
                                                             height:outputImage.height
                                                           channels:3];
  [self.resizer encodeToCommandBuffer:commandBuffer inputImage:inputImage
                          outputImage:netInputImage];

  auto netOutputImage =
      [MPSTemporaryImage mtb_float16TemporaryImageWithCommandBuffer:commandBuffer
                                                             width:outputImage.width
                                                            height:outputImage.height
                                                          channels:1];

  LTParameterAssert(self.network.inputImageNames.count == 1, @"Network must have 1 input image, "
                    "got %lu", (unsigned long)self.network.inputImageNames.count);
  auto inputImageName = self.network.inputImageNames[0];
  LTParameterAssert(self.network.outputImageNames.count == 1, @"Network must have 1 output image, "
                    "got %lu", (unsigned long)self.network.outputImageNames.count);
  auto outputImageName = self.network.outputImageNames[0];

  [self.network encodeWithCommandBuffer:commandBuffer inputImages:@{inputImageName: netInputImage}
                           outputImages:@{outputImageName: netOutputImage}];

  [self.normalizer encodeToCommandBuffer:commandBuffer inputImage:netOutputImage
                             outputImage:outputImage];

  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer>) {
    completion();
  }];

  [commandBuffer commit];
}

- (CGSize)outputSizeWithInputSize:(CGSize)size {
  static const NSUInteger kInputLargeSide = 512;
  if (size.width < size.height) {
    int width = (size.width * kInputLargeSide) / size.height;
    width = ((width + 15) / 16) * 16;
    return CGSizeMake(width, kInputLargeSide);
  } else {
    int height = (size.height * kInputLargeSide) / size.width;
    height = ((height + 15) / 16) * 16;
    return CGSizeMake(kInputLargeSide, height);
  }
}

@end

NS_ASSUME_NONNULL_END

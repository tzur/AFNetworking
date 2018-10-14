// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKSuperSkySegmentationProcessor.h"

#import <MetalToolbox/MPSTemporaryImage+Factory.h>

#import "PNKAvailability.h"
#import "PNKDeviceAndCommandQueue.h"
#import "PNKGather.h"
#import "PNKImageScale.h"
#import "PNKNetworkSchemeFactory.h"
#import "PNKPixelBufferUtils.h"
#import "PNKRunnableNeuralNetwork.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKSuperSkySegmentationProcessor ()

/// Neural network performing the segmentation.
@property (readonly, nonatomic) PNKRunnableNeuralNetwork *network;

/// Device to encode this network operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Command queue used to create command buffer objects used to encode this network operation.
@property (readonly, nonatomic) id<MTLCommandQueue> commandQueue;

/// Pinky kernel used to resize the input image in the pre-processing stage.
@property (readonly, nonatomic) PNKImageScale *resizer;

/// Pinky kernel used to separate the first channel of the output image in the post-processing
/// stage.
@property (readonly, nonatomic) PNKGather *gatherer;

/// Serial queue used to perform the operations when the processor's asynchronous API is called.
/// This separate queue is used because encoding the network can take a non-negligible time.
@property (readonly, nonatomic) dispatch_queue_t dispatchQueue;

@end

@implementation PNKSuperSkySegmentationProcessor

- (nullable instancetype)initWithNetworkModel:(NSURL *)networkModelURL
                                        error:(NSError *__autoreleasing *)error {
  if (self = [super init]) {
    _device = PNKDefaultDevice();
    if (!PNKSupportsMTLDevice(self.device)) {
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
    _gatherer = [[PNKGather alloc] initWithDevice:self.device inputFeatureChannels:2
                      outputFeatureChannelIndices:{0}];
    _dispatchQueue = dispatch_queue_create("com.lightricks.Pinky.SkySegmentationProcessor",
                                           DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);
  }
  return self;
}

- (void)segmentWithInput:(CVPixelBufferRef)input output:(CVPixelBufferRef)output
              completion:(LTCompletionBlock)completion {
  LTParameterAssert(completion, @"Completion block must not be nil");
  [self verifyInputBuffer:input outputBuffer:output];

  dispatch_async(self.dispatchQueue, ^{
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
      [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                             width:outputImage.width
                                                            height:outputImage.height
                                                          channels:3];

  [self.resizer encodeToCommandBuffer:commandBuffer inputImage:inputImage
                          outputImage:netInputImage];

  auto netOutputImage =
      [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                             width:outputImage.width
                                                            height:outputImage.height
                                                          channels:2];

  LTParameterAssert(self.network.inputImageNames.count == 1, @"Network must have 1 input image, "
                    "got %lu", (unsigned long)self.network.inputImageNames.count);
  NSString *inputImageName = self.network.inputImageNames[0];
  LTParameterAssert(self.network.outputImageNames.count == 1, @"Network must have 1 output image, "
                    "got %lu", (unsigned long)self.network.outputImageNames.count);
  NSString *outputImageName = self.network.outputImageNames[0];

  [self.network encodeWithCommandBuffer:commandBuffer inputImages:@{inputImageName: netInputImage}
                           outputImages:@{outputImageName: netOutputImage}];

  [self.gatherer encodeToCommandBuffer:commandBuffer inputImage:netOutputImage
                           outputImage:outputImage];

  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer>) {
    completion();
  }];

  [commandBuffer commit];
}

- (CGSize)outputSizeWithInputSize:(CGSize)size {
  static const NSUInteger kInputSmallSide = 512;
  static const NSUInteger kInputDivisibleSize = 8;
  if (size.width > size.height) {
    int width = (size.width * kInputSmallSide) / size.height;
    width = ((width + (kInputDivisibleSize - 1)) / kInputDivisibleSize) * kInputDivisibleSize;
    return CGSizeMake(width, kInputSmallSide);
  } else {
    int height = (size.height * kInputSmallSide) / size.width;
    height = ((height + (kInputDivisibleSize - 1)) / kInputDivisibleSize) * kInputDivisibleSize;
    return CGSizeMake(kInputSmallSide, height);
  }
}

@end

NS_ASSUME_NONNULL_END

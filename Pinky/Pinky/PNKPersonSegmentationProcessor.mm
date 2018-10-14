// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKPersonSegmentationProcessor.h"

#import <MetalToolbox/MPSTemporaryImage+Factory.h>

#import "PNKAvailability.h"
#import "PNKCrop.h"
#import "PNKDeviceAndCommandQueue.h"
#import "PNKGather.h"
#import "PNKImageScale.h"
#import "PNKNetworkSchemeFactory.h"
#import "PNKPixelBufferUtils.h"
#import "PNKReflectionPadding.h"
#import "PNKRunnableNeuralNetwork.h"

NS_ASSUME_NONNULL_BEGIN

static const pnk::PaddingSize kPadding = {
  .left = 8,
  .top = 0,
  .right = 8,
  .bottom = 16
};

@interface PNKPersonSegmentationProcessor ()

/// Neural network performing the segmentation.
@property (readonly, nonatomic) PNKRunnableNeuralNetwork *network;

/// Device to encode this network operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Command queue used to create command buffer objects used to encode this network operation.
@property (readonly, nonatomic) id<MTLCommandQueue> commandQueue;

/// Pinky kernel used to resize the input image in the pre-processing stage.
@property (readonly, nonatomic) PNKImageScale *resizer;

/// Pinky kernel used to pad the resized input image.
@property (readonly, nonatomic) PNKReflectionPadding *padder;

/// Pinky kernel used to crop the output of the network.
@property (readonly, nonatomic) PNKCrop *cropper;

/// Pinky kernel used to separate the first channel of the output image in the post-processing
/// stage.
@property (readonly, nonatomic) PNKGather *gatherer;

/// Serial queue used to perform the operations when the processor's asynchronic API is called.
/// This separate queue is used because encoding the network can take non-negligible time.
@property (readonly, nonatomic) dispatch_queue_t dispatchQueue;

@end

@implementation PNKPersonSegmentationProcessor

- (nullable instancetype)initWithNetworkModel:(NSURL *)networkModelURL
                                        error:(NSError *__autoreleasing *)error {
  if (self = [super init]) {
    _device = PNKDefaultDevice();
    if (!PNKSupportsMTLDevice(self.device)) {
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
    _padder = [[PNKReflectionPadding alloc] initWithDevice:self.device paddingSize:kPadding];
    _cropper = [[PNKCrop alloc] initWithDevice:self.device margins:kPadding];
    _gatherer = [[PNKGather alloc] initWithDevice:self.device inputFeatureChannels:2
                      outputFeatureChannelIndices:{0}];
    _dispatchQueue = dispatch_queue_create("com.lightricks.Pinky.PersonSegmentationProcessor",
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

  NSUInteger paddedOutputWidth = outputImage.width + kPadding.left + kPadding.right;
  NSUInteger paddedOutputHeight = outputImage.height + kPadding.top + kPadding.bottom;

  auto resizedInputImage =
      [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                             width:outputImage.width
                                                            height:outputImage.height
                                                          channels:3];
  [self.resizer encodeToCommandBuffer:commandBuffer inputImage:inputImage
                          outputImage:resizedInputImage];

  auto netInputImage =
      [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                             width:paddedOutputWidth
                                                            height:paddedOutputHeight
                                                          channels:3];
  [self.padder encodeToCommandBuffer:commandBuffer inputImage:resizedInputImage
                         outputImage:netInputImage];

  auto netOutputImage =
      [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                             width:paddedOutputWidth
                                                            height:paddedOutputHeight
                                                          channels:2];

  LTParameterAssert(self.network.inputImageNames.count == 1, @"Network must have 1 input image, "
                    "got %lu", (unsigned long)self.network.inputImageNames.count);
  NSString *inputImageName = self.network.inputImageNames[0];
  LTParameterAssert(self.network.outputImageNames.count == 1, @"Network must have 1 output image, "
                    "got %lu", (unsigned long)self.network.outputImageNames.count);
  NSString *outputImageName = self.network.outputImageNames[0];

  [self.network encodeWithCommandBuffer:commandBuffer inputImages:@{inputImageName: netInputImage}
                           outputImages:@{outputImageName: netOutputImage}];

  auto croppedOutputImage =
      [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                             width:outputImage.width
                                                            height:outputImage.height
                                                          channels:netOutputImage.featureChannels];
  [self.cropper encodeToCommandBuffer:commandBuffer inputImage:netOutputImage
                          outputImage:croppedOutputImage];

  [self.gatherer encodeToCommandBuffer:commandBuffer inputImage:croppedOutputImage
                           outputImage:outputImage];

  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer>) {
    completion();
  }];

  [commandBuffer commit];
}

- (CGSize)outputSizeWithInputSize:(CGSize)size {
  static const NSUInteger kInputLargeSide = 800;
  if (size.width < size.height) {
    int width = (size.width * kInputLargeSide) / size.height;
    width = ((width + 7) / 8) * 8;
    return CGSizeMake(width, kInputLargeSide);
  } else {
    int height = (size.height * kInputLargeSide) / size.width;
    height = ((height + 7) / 8) * 8;
    return CGSizeMake(kInputLargeSide, height);
  }
}

@end

NS_ASSUME_NONNULL_END

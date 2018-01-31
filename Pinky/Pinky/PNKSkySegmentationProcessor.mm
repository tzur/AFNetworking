// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKSkySegmentationProcessor.h"

#import <LTEngine/CIContext+PixelFormat.h>
#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTEngine/LTGLPixelFormat.h>
#import <LTEngine/LTOpenCVExtensions.h>

#import "MPSImage+Factory.h"
#import "MPSTemporaryImage+Factory.h"
#import "PNKGather.h"
#import "PNKImageBilinearScale.h"
#import "PNKNeuralNetworkModel.h"
#import "PNKNeuralNetworkModelFactory.h"
#import "PNKOpenCVExtensions.h"
#import "PNKPixelBufferUtils.h"
#import "PNKSkySegmentationNetwork.h"
#import "PNKTensorSerializationUtilities.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKSkySegmentationProcessor ()

/// Neural network performing the ssegmentation.
@property (readonly, nonatomic) PNKSkySegmentationNetwork *network;

/// Device to encode this network operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Command queue used to create command buffer objects used to encode this network operation.
@property (readonly, nonatomic) id<MTLCommandQueue> commandQueue;

/// Pinky kernel used to resize the input image in the pre-processing stage.
@property (readonly, nonatomic) PNKImageBilinearScale *resizer;

/// Pinky kernel used to separate the first channel of the output image in the post-processing
/// stage.
@property (readonly, nonatomic) PNKGather *gatherer;

/// \c CIContext object used in the \c CIFilter - based guided upsampling.
@property (readonly, nonatomic) CIContext *ciContext;

/// Serial queue used to perform the operations when the processor's asynchronic API is called.
/// This separate queue is used because encoding the network can take a non-negligible time.
@property (readonly, nonatomic) dispatch_queue_t dispatchQueue;

@end

@implementation PNKSkySegmentationProcessor

/// The size in pixels of the tensor used as shape model input for the underlying network.
static const NSUInteger kShapeModelInputSide = 512;

- (nullable instancetype)initWithNetworkModel:(NSURL *)networkModelURL
                                   shapeModel:(NSURL *)shapeModelURL
                                        error:(NSError *__autoreleasing *)error {
  if (self = [super init]) {
    auto model = [[[PNKNeuralNetworkModelFactory alloc] init] modelWithCoreMLModel:networkModelURL
                                                                             error:error];
    if (!model) {
      return nil;
    }
    auto shapeModel = pnk::loadHalfTensor(shapeModelURL,
                                          {kShapeModelInputSide, kShapeModelInputSide, 1}, error);
    if (shapeModel.empty()) {
      return nil;
    }

    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [self.device newCommandQueue];

    _network = [[PNKSkySegmentationNetwork alloc] initWithDevice:self.device networkModel:*model
                                                      shapeModel:shapeModel];
    if (!self.network) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                               description:@"Failed to create network from the model found on URL "
                                           "%@", networkModelURL];
      }
      return nil;
    }

    _resizer = [[PNKImageBilinearScale alloc] initWithDevice:self.device];
    _gatherer = [[PNKGather alloc] initWithDevice:self.device inputFeatureChannels:2
                      outputFeatureChannelIndices:{0}];
    _ciContext = [CIContext lt_contextWithPixelFormat:$(LTGLPixelFormatRGBA8Unorm)];
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
  PNKAssertPixelBufferFormat(input);

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
  MPSImage *inputImage = PNKImageFromPixelBuffer(input, self.device);
  MPSImage *outputImage = PNKImageFromPixelBuffer(output, self.device);

  auto commandBuffer = [self.commandQueue commandBuffer];

  auto netInputImage = [MPSTemporaryImage pnk_unorm8ImageWithCommandBuffer:commandBuffer
                                                                     width:outputImage.width
                                                                    height:outputImage.height
                                                                  channels:3];

  [self encodePreProcessWithCommandBuffer:commandBuffer inputImage:inputImage
                              outputImage:netInputImage];

  auto netOutputImage = [MPSTemporaryImage pnk_unorm8ImageWithCommandBuffer:commandBuffer
                                                                      width:outputImage.width
                                                                     height:outputImage.height
                                                                   channels:2];

  [self.network encodeWithCommandBuffer:commandBuffer inputImage:netInputImage
                            outputImage:netOutputImage];

  [self encodePostProcessWithCommandBuffer:commandBuffer inputImage:netOutputImage
                               outputImage:outputImage];

  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer>) {
    completion();
  }];

  [commandBuffer commit];
}

- (void)encodePreProcessWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                               inputImage:(MPSImage *)inputImage
                              outputImage:(MPSImage *)outputImage {
  [self.resizer encodeToCommandBuffer:buffer inputImage:inputImage outputImage:outputImage];
}

- (void)encodePostProcessWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                inputImage:(MPSImage *)inputImage
                               outputImage:(MPSImage *)outputImage {
  [self.gatherer encodeToCommandBuffer:buffer inputImage:inputImage outputImage:outputImage];
}

- (void)upsampleImage:(CVPixelBufferRef)image withGuide:(CVPixelBufferRef)guide
               output:(CVPixelBufferRef)output {
  CIImage *smallImage = [[CIImage alloc] initWithCVPixelBuffer:image];
  CIImage *guideImage = [[CIImage alloc] initWithCVPixelBuffer:guide];
  CGSize outputSize = CGSizeMake(CVPixelBufferGetWidth(output), CVPixelBufferGetHeight(output));
  CIFilter *upsampler = [CIFilter filterWithName:@"CIEdgePreserveUpsampleFilter"];
  [upsampler setValue:guideImage forKey:kCIInputImageKey];
  [upsampler setValue:smallImage forKey:@"inputSmallImage"];
  [upsampler setValue:@(0.4) forKey:@"inputLumaSigma"];
  CIImage * _Nullable result = upsampler.outputImage;
  LTAssert(result, @"Failed to configure CIEdgePreserveUpsampleFilter");
  [self.ciContext render:result toCVPixelBuffer:output bounds:CGRectFromSize(outputSize)
              colorSpace:NULL];
}

- (CGSize)outputSizeWithInputSize:(CGSize)size {
  return [self.network optimalInputSizeWithSize:size];
}

@end

#endif

NS_ASSUME_NONNULL_END

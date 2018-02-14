// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKStyleTransferProcessor.h"

#import "MPSImage+Factory.h"
#import "MPSTemporaryImage+Factory.h"
#import "PNKAvailability.h"
#import "PNKConstantAlpha.h"
#import "PNKDeviceAndCommandQueue.h"
#import "PNKImageBilinearScale.h"
#import "PNKNeuralNetworkModel.h"
#import "PNKNeuralNetworkModelFactory.h"
#import "PNKPixelBufferUtils.h"
#import "PNKStyleTransferNetwork.h"
#import "PNKStyleTransferState.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKStyleTransferState ()

/// Initializes a new state object with the given original input size and the resulting image to be
/// used as input for the neural network of the processor.
- (instancetype)initWithOriginalInputSize:(CGSize)size image:(MPSImage *)image;

/// Resized and color converted image to be used as input for the stylization network.
@property (readonly, nonatomic) MPSImage *networkInputImage;

/// Size of the original input image used to create this state.
@property (readonly, nonatomic) CGSize originalInputSize;

@end

@implementation PNKStyleTransferState

- (instancetype)initWithOriginalInputSize:(CGSize)size image:(MPSImage *)image {
  if (self = [super init]) {
    _originalInputSize = size;
    _networkInputImage = image;
  }
  return self;
}

@end

@interface PNKStyleTransferProcessor ()

/// Neural network performing the style transfer.
@property (readonly, nonatomic) PNKStyleTransferNetwork *network;

/// Device to encode thie operations of this processor.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Command queue used to create command buffer objects used to encode this processor's operation.
@property (readonly, nonatomic) id<MTLCommandQueue> commandQueue;

/// Pinky kernel used to resize and color transform the input of the processor.
@property (readonly, nonatomic) PNKImageBilinearScale *inputResizer;

/// Pinky kernel used to set the alpha channel of the output to 1.
@property (readonly, nonatomic) PNKConstantAlpha *alphaCorrect;

/// Serial queue used to perform the operations when the processor's asynchronic API is called.
/// This separate queue is used because encoding the network can take a non-negligible time.
@property (readonly, nonatomic) dispatch_queue_t dispatchQueue;

@end

@implementation PNKStyleTransferProcessor

- (nullable instancetype)initWithModel:(NSURL *)modelURL error:(NSError *__autoreleasing *)error {
  if (self = [super init]) {
    auto model = [[[PNKNeuralNetworkModelFactory alloc] init] modelWithCoreMLModel:modelURL
                                                                             error:error];
    if (!model) {
      return nil;
    }
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
    _network = [[PNKStyleTransferNetwork alloc] initWithDevice:self.device model:*model];

    _dispatchQueue = dispatch_queue_create("com.lightricks.Pinky.StyleTransferProcessor",
                                           DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);

    _stylizedOutputSmallSide = 1024;
    _stylizedOutputChannels = self.network.outputChannels > 1 ? 4 : 1;
    _stylesCount = self.network.stylesCount;

    _inputResizer = [[PNKImageBilinearScale alloc] initWithDevice:self.device];
    _alphaCorrect = [[PNKConstantAlpha alloc] initWithDevice:self.device alpha:1.];
  } else {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Failed creating super initializer"];
    }
    return nil;
  }
  return self;
}

- (void)stylizeWithInput:(CVPixelBufferRef)input output:(CVPixelBufferRef)output
              styleIndex:(NSUInteger)styleIndex
              completion:(PNKStyleTransferCompletionBlock)completion {
  LTParameterAssert(completion, @"Completion block must not be nil");
  [self verifySizeWithInputBuffer:input outputBuffer:output];

  dispatch_async(self.dispatchQueue, ^{
    [self encodeAndCommitWithInput:input output:output styleIndex:styleIndex completion:completion];
  });
}

- (void)verifySizeWithInputBuffer:(CVPixelBufferRef)input outputBuffer:(CVPixelBufferRef)output {
  PNKAssertPixelBufferFormat(input);

  auto inputWidth = CVPixelBufferGetWidth(input);
  auto inputHeight = CVPixelBufferGetHeight(input);
  [self verifyOutputBuffer:output withSize:CGSizeMake(inputWidth, inputHeight)];
}

- (void)verifyOutputBuffer:(CVPixelBufferRef)output withSize:(CGSize)size {
  auto outputWidth = CVPixelBufferGetWidth(output);
  auto outputHeight = CVPixelBufferGetHeight(output);
  auto expectedOutputSize = [self outputSizeWithInputSize:size];
  LTParameterAssert(expectedOutputSize == CGSizeMake(outputWidth, outputHeight), @"output size "
                    "must be (%f, %f), got (%lu, %lu)", expectedOutputSize.width,
                    expectedOutputSize.height, (unsigned long)outputWidth,
                    (unsigned long)outputHeight);
}

- (void)stylizeWithState:(PNKStyleTransferState *)state output:(CVPixelBufferRef)output
              styleIndex:(NSUInteger)styleIndex completion:(LTCompletionBlock)completion {
  LTParameterAssert(completion, @"Completion block must not be nil");
  [self verifySizeWithState:state outputBuffer:output];

  dispatch_async(self.dispatchQueue, ^{
    [self encodeAndCommitWithState:state output:output styleIndex:styleIndex completion:completion];
  });
}

- (void)verifySizeWithState:(PNKStyleTransferState *)state outputBuffer:(CVPixelBufferRef)output {
  LTParameterAssert(state, @"State must not be nil");
  [self verifyOutputBuffer:output withSize:state.originalInputSize];
}

- (void)encodeAndCommitWithInput:(CVPixelBufferRef)input output:(CVPixelBufferRef)output
                      styleIndex:(NSUInteger)styleIndex
                      completion:(PNKStyleTransferCompletionBlock)completion {
  MPSImage *inputImage = PNKImageFromPixelBuffer(input, self.device);

  auto commandBuffer = [self.commandQueue commandBuffer];

  auto netInputImage = [MPSImage pnk_unorm8ImageWithDevice:self.device
                                                     width:CVPixelBufferGetWidth(output)
                                                    height:CVPixelBufferGetHeight(output)
                                                  channels:self.network.inputChannels];

  [self encodePreProcessWithCommandBuffer:commandBuffer input:inputImage
                                   output:netInputImage];

  [commandBuffer commit];

  PNKStyleTransferState *state =
      [[PNKStyleTransferState alloc] initWithOriginalInputSize:CGSizeMake(inputImage.width,
                                                                          inputImage.height)
                                                         image:netInputImage];
  [self encodeAndCommitWithState:state output:output styleIndex:styleIndex completion:^{
    completion(state);
  }];
}

- (void)encodeAndCommitWithState:(PNKStyleTransferState *)state output:(CVPixelBufferRef)output
                      styleIndex:(NSUInteger)styleIndex completion:(LTCompletionBlock)completion {
  MPSImage *outputImage = PNKImageFromPixelBuffer(output, self.device, self.stylizedOutputChannels);

  auto commandBuffer = [self.commandQueue commandBuffer];

  if (self.stylizedOutputChannels != 1) {
    auto netOutputImage =
        [MPSTemporaryImage pnk_unorm8ImageWithCommandBuffer:commandBuffer
                                                      width:outputImage.width
                                                     height:outputImage.height
                                                   channels:self.network.outputChannels];
    [self.network encodeWithCommandBuffer:commandBuffer inputImage:state.networkInputImage
                              outputImage:netOutputImage styleIndex:styleIndex];

    [self encodePostProcessWithCommandBuffer:commandBuffer inputImage:netOutputImage
                                 outputImage:outputImage];

  } else {
    [self.network encodeWithCommandBuffer:commandBuffer inputImage:state.networkInputImage
                              outputImage:outputImage styleIndex:styleIndex];
  }

  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer>) {
    completion();
  }];

  [commandBuffer commit];
}

- (void)encodePreProcessWithCommandBuffer:(id<MTLCommandBuffer>)buffer input:(MPSImage *)input
                                   output:(MPSImage *)output {
  [self.inputResizer encodeToCommandBuffer:buffer inputImage:input outputImage:output];
}

- (void)encodePostProcessWithCommandBuffer:(id<MTLCommandBuffer>)buffer inputImage:(MPSImage *)input
                               outputImage:(MPSImage *)output {
  [self.alphaCorrect encodeToCommandBuffer:buffer inputImage:input outputImage:output];
}

- (CGSize)outputSizeWithInputSize:(CGSize)size {
  CGFloat smallSide = std::min(size.width, size.height);
  if (smallSide <= self.stylizedOutputSmallSide) {
    return size;
  }
  CGSize sizeToFill = CGSizeMake(self.stylizedOutputSmallSide, self.stylizedOutputSmallSide);
  CGSize resizedInputSize = CGSizeAspectFill(size, sizeToFill);
  resizedInputSize.width = ((int)(resizedInputSize.width + 3) / 4) * 4;
  resizedInputSize.height = ((int)(resizedInputSize.height + 3) / 4) * 4;
  return resizedInputSize;
}

@end

#else

@implementation PNKStyleTransferState

@end

@implementation PNKStyleTransferProcessor

- (nullable instancetype)initWithModel:(__unused NSURL *)networkModelURL
                                 error:(__unused NSError *__autoreleasing *)error {
  return nil;
}

- (void)stylizeWithInput:(__unused CVPixelBufferRef)input output:(__unused CVPixelBufferRef)output
              styleIndex:(__unused NSUInteger)styleIndex
              completion:(__unused PNKStyleTransferCompletionBlock)completion {
}

- (void)stylizeWithState:(PNKStyleTransferState __unused *)state
                  output:(__unused CVPixelBufferRef)output
              styleIndex:(__unused NSUInteger)styleIndex
              completion:(__unused LTCompletionBlock)completion {
}

- (CGSize)outputSizeWithInputSize:(__unused CGSize)size {
  return CGSizeZero;
}

@end
#endif

NS_ASSUME_NONNULL_END

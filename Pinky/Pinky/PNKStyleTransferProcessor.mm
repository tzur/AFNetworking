// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKStyleTransferProcessor.h"

#import <MetalToolbox/MPSImage+Factory.h>
#import <MetalToolbox/MPSTemporaryImage+Factory.h>

#import "LTEasyBoxing+Pinky.h"
#import "PNKAvailability.h"
#import "PNKConstantAlpha.h"
#import "PNKDeviceAndCommandQueue.h"
#import "PNKImageScale.h"
#import "PNKPixelBufferUtils.h"
#import "PNKRunnableNeuralNetwork.h"
#import "PNKStyleTransferState.h"

NS_ASSUME_NONNULL_BEGIN

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
@property (readonly, nonatomic) PNKRunnableNeuralNetwork *network;

/// Device to encode thie operations of this processor.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Command queue used to create command buffer objects used to encode this processor's operation.
@property (readonly, nonatomic) id<MTLCommandQueue> commandQueue;

/// Pinky kernel used to resize and color transform the input of the processor.
@property (readonly, nonatomic) PNKImageScale *inputResizer;

/// Pinky kernel used to set the alpha channel of the output to 1.
@property (readonly, nonatomic) PNKConstantAlpha *alphaCorrect;

/// Number of feature channels in the \c network input image.
@property (readonly, nonatomic) NSUInteger networkInputChannels;

/// Number of feature channels in the \c network output image.
@property (readonly, nonatomic) NSUInteger networkOutputChannels;

/// Serial queue used to perform the operations when the processor's asynchronic API is called.
/// This separate queue is used because encoding the network can take a non-negligible time.
@property (readonly, nonatomic) dispatch_queue_t dispatchQueue;

@end

@implementation PNKStyleTransferProcessor

- (nullable instancetype)initWithModel:(NSURL *)modelURL error:(NSError *__autoreleasing *)error {
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

    auto scheme = [PNKNetworkSchemeFactory schemeWithDevice:self.device coreMLModel:modelURL
                                                      error:error];
    if (!scheme) {
      return nil;
    }

    _network = [[PNKRunnableNeuralNetwork alloc] initWithNetworkScheme:*scheme];
    [self validateNetwork];
    [self setChannelCounts];

    _dispatchQueue = dispatch_queue_create("com.lightricks.Pinky.StyleTransferProcessor",
                                           DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);

    _stylizedOutputSmallSide = 1024;
    _stylizedOutputLargeSide = 3072;

    _inputResizer = [[PNKImageScale alloc] initWithDevice:self.device];
    _alphaCorrect = [[PNKConstantAlpha alloc] initWithDevice:self.device alpha:1.];

    _stylesCount = (NSUInteger)[self.network.metadata[@"NumberOfStyles"] integerValue];
    LTParameterAssert(self.networkInputChannels, @"Network metadata must contain a valid value for "
                      "styles count");
  } else {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Failed creating super initializer"];
    }
    return nil;
  }
  return self;
}

- (void)validateNetwork {
  LTParameterAssert(self.network.inputImageNames.count == 1, @"Network must have 1 input image, "
                    "got %lu", (unsigned long)self.network.inputImageNames.count);
  LTParameterAssert(self.network.inputImageNamesToSizes.size() == 1, @"Network must have "
                    "inputImageNamesToSizes dictionary with 1 entry, got %lu",
                    (unsigned long)self.network.inputImageNamesToSizes.size());
  LTParameterAssert(self.network.inputParameterNames.count == 1, @"Network must have 1 input "
                    "parameter, got %lu", (unsigned long)self.network.inputParameterNames.count);
  LTParameterAssert(self.network.outputImageNames.count == 1, @"Network must have 1 output image, "
                    "got %lu", (unsigned long)self.network.outputImageNames.count);
}

- (void)setChannelCounts {
  auto inputImageName = self.network.inputImageNames[0];
  auto inputImageSize = self.network.inputImageNamesToSizes[inputImageName.UTF8String];
  _networkInputChannels = inputImageSize.depth;

  auto outputImageName = self.network.outputImageNames[0];
  auto outputImageNamesToSizes =
      [self.network outputImageSizesFromInputImageSizes:self.network.inputImageNamesToSizes];
  auto outputImageSize = outputImageNamesToSizes[outputImageName.UTF8String];
  _networkOutputChannels = outputImageSize.depth;
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

  auto netInputImage = [MPSImage mtb_unorm8ImageWithDevice:self.device
                                                     width:CVPixelBufferGetWidth(output)
                                                    height:CVPixelBufferGetHeight(output)
                                                  channels:self.networkInputChannels];

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
  MPSImage *outputImage = PNKImageFromPixelBuffer(output, self.device);

  auto commandBuffer = [self.commandQueue commandBuffer];

  LTParameterAssert(styleIndex < [self stylesCount], @"Style index must be less then %lu, "
                    "got %lu", (unsigned long)[self stylesCount], (unsigned long)styleIndex);
  NSString *inputImageName = self.network.inputImageNames[0];
  NSString *inputParameterName = self.network.inputParameterNames[0];
  NSString *outputImageName = self.network.outputImageNames[0];

  if ([self stylizedOutputChannels] != 1) {
    auto netOutputImage =
        [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                               width:outputImage.width
                                                              height:outputImage.height
                                                            channels:self.networkOutputChannels];
    [self.network encodeWithCommandBuffer:commandBuffer
                              inputImages:@{inputImageName: state.networkInputImage}
                          inputParameters:@{inputParameterName: @(styleIndex)}
                             outputImages:@{outputImageName: netOutputImage}];

    [self encodePostProcessWithCommandBuffer:commandBuffer inputImage:netOutputImage
                                 outputImage:outputImage];

  } else {
    [self.network encodeWithCommandBuffer:commandBuffer
                              inputImages:@{inputImageName: state.networkInputImage}
                          inputParameters:@{inputParameterName: @(styleIndex)}
                             outputImages:@{outputImageName:outputImage}];
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

- (NSUInteger)stylizedOutputChannels {
  return (self.networkOutputChannels == 3) ? 4 : self.networkOutputChannels;
}

- (CGSize)outputSizeWithInputSize:(CGSize)size {
  CGFloat smallSide = std::min(size.width, size.height);
  CGFloat largeSide = std::max(size.width, size.height);

  CGSize resizedInputSize;
  if (smallSide <= self.stylizedOutputSmallSide && largeSide <= self.stylizedOutputLargeSide) {
    resizedInputSize = size;
  } else {
    CGSize sizeToFit = (size.width < size.height) ?
        CGSizeMake(self.stylizedOutputSmallSide, self.stylizedOutputLargeSide) :
        CGSizeMake(self.stylizedOutputLargeSide, self.stylizedOutputSmallSide);
    resizedInputSize = CGSizeAspectFit(size, sizeToFit);
  }

  resizedInputSize.width = ((int)(resizedInputSize.width + 3) / 4) * 4;
  resizedInputSize.height = ((int)(resizedInputSize.height + 3) / 4) * 4;
  return resizedInputSize;
}

@end

NS_ASSUME_NONNULL_END

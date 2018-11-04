// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKInpaintingProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTKit/LTCGExtensions.h>
#import <MetalToolbox/MPSTemporaryImage+Factory.h>

#import "PNKAvailability.h"
#import "PNKConstantAlpha.h"
#import "PNKDeviceAndCommandQueue.h"
#import "PNKImageScale.h"
#import "PNKInpaintingHighFrequencyTransfer.h"
#import "PNKInpaintingRegionOfInterest.h"
#import "PNKNetworkSchemeFactory.h"
#import "PNKPixelBufferUtils.h"
#import "PNKRunnableNeuralNetwork.h"

NS_ASSUME_NONNULL_BEGIN

/// Width and height of image and mask inputs for the Inpainting net.
static const NSUInteger kNetInputSize = 512;

@interface PNKInpaintingProcessor ()

/// Neural network performing the segmentation.
@property (readonly, nonatomic) PNKRunnableNeuralNetwork *network;

/// Device to encode this network operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Command queue used to create command buffer objects used to encode this network operation.
@property (readonly, nonatomic) id<MTLCommandQueue> commandQueue;

/// Kernel used to copy the input image into the output image.
@property (readonly, nonatomic) PNKImageScale *imageCopyKernel;

/// Kernel used to crop and scale the input image.
@property (readonly, nonatomic) PNKImageScale *inputScaleKernel;

/// Kernel used to crop and scale the mask.
@property (readonly, nonatomic) PNKImageScale *maskScaleKernel;

/// Pinky kernel used to set the alpha channel of the output to half-float value of 1 (corresponds
/// to unsigned char value of 255).
@property (readonly, nonatomic) PNKConstantAlpha *correctAlphaKernel;

/// Serial queue used to perform the operations when the processor's asynchronous API is called.
/// This separate queue is used because encoding the network can take a non-negligible time.
@property (readonly, nonatomic) dispatch_queue_t dispatchQueue;

@end

@implementation PNKInpaintingProcessor

- (nullable instancetype)initWithNetworkModel:(NSURL *)networkModelURL
                                        error:(NSError *__autoreleasing *)error {
  if (self = [super init]) {
    _device = PNKDefaultDevice();
    if (![self.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily3_v1]) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                               description:@"Inpainting is not supported on GPU family %@",
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
    [self validateNetwork];

    _imageCopyKernel = [[PNKImageScale alloc] initWithDevice:self.device];
    _inputScaleKernel = [[PNKImageScale alloc] initWithDevice:self.device];
    _maskScaleKernel = [[PNKImageScale alloc] initWithDevice:self.device
                                               interpolation:PNKInterpolationTypeNearestNeighbor];

    _correctAlphaKernel = [[PNKConstantAlpha alloc] initWithDevice:self.device alpha:1.];
    _dispatchQueue = dispatch_queue_create("com.lightricks.Pinky.InpaintingProcessor",
                                           DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);
  }
  return self;
}

- (void)validateNetwork {
  LTParameterAssert(self.network.inputImageNames.count == 2, @"Network must have 2 input images, "
                    "got %lu", (unsigned long)self.network.inputImageNames.count);
  LTParameterAssert(self.network.inputImageNamesToSizes.size() == 2, @"Network must have "
                    "inputImageNamesToSizes dictionary with 2 entries, got %lu",
                    (unsigned long)self.network.inputImageNamesToSizes.size());
  LTParameterAssert(self.network.outputImageNames.count == 1, @"Network must have 1 output image, "
                    "got %lu", (unsigned long)self.network.outputImageNames.count);

  auto inputImageName = self.network.inputImageNames[0];
  auto inputImageSize = self.network.inputImageNamesToSizes[inputImageName.UTF8String];
  LTParameterAssert(inputImageSize.depth == 3, @"Input image expected channel count must be 3, got "
                    "%lu", inputImageSize.depth);

  auto maskImageName = self.network.inputImageNames[1];
  auto maskImageSize = self.network.inputImageNamesToSizes[maskImageName.UTF8String];
  LTParameterAssert(maskImageSize.depth == 1, @"Mask image expected channel count must be 1, got "
                    "%lu", maskImageSize.depth);
}

- (void)inpaintWithInput:(CVPixelBufferRef)input mask:(CVPixelBufferRef)mask
                  output:(CVPixelBufferRef)output
              completion:(LTCompletionBlock)completion {
  [self verifyInputBuffer:input maskBuffer:mask outputBuffer:output];

  dispatch_async(self.dispatchQueue, ^{
    [self doInpaintingWithInput:input mask:mask output:output completion:completion];
  });
}

- (void)verifyInputBuffer:(CVPixelBufferRef)input maskBuffer:(CVPixelBufferRef)mask
             outputBuffer:(CVPixelBufferRef)output {
  auto inputWidth = CVPixelBufferGetWidth(input);
  auto inputHeight = CVPixelBufferGetHeight(input);
  auto inputPixelFormat = CVPixelBufferGetPixelFormatType(input);

  auto maskWidth = CVPixelBufferGetWidth(mask);
  auto maskHeight = CVPixelBufferGetHeight(mask);
  LTParameterAssert(inputWidth == maskWidth, @"Input width and mask width must be equal; got "
                    "(input: %lu, mask: %lu) ", inputWidth, maskWidth);
  LTParameterAssert(inputHeight == maskHeight, @"Input height and mask height must be equal; got "
                    "(input: %lu, mask: %lu) ", inputHeight, maskHeight);

  auto outputWidth = CVPixelBufferGetWidth(output);
  auto outputHeight = CVPixelBufferGetHeight(output);
  auto outputPixelFormat = CVPixelBufferGetPixelFormatType(output);
  LTParameterAssert(inputWidth == outputWidth, @"Input width and output width must be equal; got "
                    "(input: %lu, output: %lu) ", outputHeight, maskWidth);
  LTParameterAssert(inputHeight == outputHeight, @"Input height and output height must be equal; "
                    "got (input: %lu, output: %lu) ", inputHeight, maskHeight);
  LTParameterAssert(inputPixelFormat == outputPixelFormat, @"Input pixel format and output pixel "
                    "format must be equal; got (input: %d, output: %d) ", inputPixelFormat,
                    outputPixelFormat);
}

- (void)doInpaintingWithInput:(CVPixelBufferRef)input mask:(CVPixelBufferRef)mask
                       output:(CVPixelBufferRef)output completion:(LTCompletionBlock)completion {
  auto regionOfInterestAroundHole = [self regionOfInterestWihMask:mask];

  auto scaledCroppedOutput = LTCVPixelBufferCreate(kNetInputSize, kNetInputSize,
                                                   CVPixelBufferGetPixelFormatType(output));

  [self runInpaintingNetworkWithInput:input mask:mask output:output
                  scaledCroppedOutput:scaledCroppedOutput.get()
                     regionOfInterest:regionOfInterestAroundHole];

  [self transferHighFrequencyWithInput:input mask:mask output:output
                   scaledCroppedOutput:scaledCroppedOutput.get()
                      regionOfInterest:regionOfInterestAroundHole];
  completion();
}

- (MTLRegion)regionOfInterestWihMask:(CVPixelBufferRef)mask {
  __block MTLRegion regionOfInterest;
  LTCVPixelBufferImageForReading(mask, ^(const cv::Mat& image) {
    regionOfInterest = pnk_inpainting::regionOfInterestAroundHole(image);
  });
  return regionOfInterest;
}

- (void)runInpaintingNetworkWithInput:(CVPixelBufferRef)input mask:(CVPixelBufferRef)mask
                               output:(CVPixelBufferRef)output
                  scaledCroppedOutput:(CVPixelBufferRef)scaledCroppedOutput
                     regionOfInterest:(MTLRegion)regionOfInterest {
  auto commandBuffer = [self.commandQueue commandBuffer];
  auto scaledCroppedInputImage =
      [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer width:kNetInputSize
                                                            height:kNetInputSize channels:3];
  auto scaledCroppedMaskImage =
      [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer width:kNetInputSize
                                                            height:kNetInputSize channels:1];
  auto networkOutputImage =
    [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer width:kNetInputSize
                                                          height:kNetInputSize channels:3];

  [self encodeNetworkPreProcessingWithCommandBuffer:commandBuffer input:input mask:mask
                                             output:output
                            scaledCroppedInputImage:scaledCroppedInputImage
                             scaledCroppedMaskImage:scaledCroppedMaskImage
                                   regionOfInterest:regionOfInterest];
  [self encodeNetworkWithCommandBuffer:commandBuffer scaledCroppedInputImage:scaledCroppedInputImage
                scaledCroppedMaskImage:scaledCroppedMaskImage
                    networkOutputImage:networkOutputImage];
  [self encodeNetworkPostProcessingWithCommandBuffer:commandBuffer
                                  networkOutputImage:networkOutputImage
                                 scaledCroppedOutput:scaledCroppedOutput];

  [commandBuffer commit];
  [commandBuffer waitUntilCompleted];
}

- (void)encodeNetworkPreProcessingWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                              input:(CVPixelBufferRef)input
                                               mask:(CVPixelBufferRef)mask
                                             output:(CVPixelBufferRef)output
                            scaledCroppedInputImage:(MPSImage *)scaledCroppedInputImage
                             scaledCroppedMaskImage:(MPSImage *)scaledCroppedMaskImage
                                   regionOfInterest:(MTLRegion)regionOfInterest {
  auto inputImage = PNKImageFromPixelBuffer(input, self.device);
  auto outputImage = PNKImageFromPixelBuffer(output, self.device);
  [self.imageCopyKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                  outputImage:outputImage];

  [self.inputScaleKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                   inputRegion:regionOfInterest
                                   outputImage:scaledCroppedInputImage
                                  outputRegion:{{0, 0, 0}, scaledCroppedInputImage.pnk_size}];

  auto maskImage = PNKImageFromPixelBuffer(mask, self.device);

  [self.maskScaleKernel encodeToCommandBuffer:commandBuffer inputImage:maskImage
                                  inputRegion:regionOfInterest
                                  outputImage:scaledCroppedMaskImage
                                 outputRegion:{{0, 0, 0}, scaledCroppedMaskImage.pnk_size}];
}

- (void)encodeNetworkWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                            scaledCroppedInputImage:(MPSImage *)scaledCroppedInputImage
                             scaledCroppedMaskImage:(MPSImage *)scaledCroppedMaskImage
                                 networkOutputImage:(MPSImage *)networkOutputImage {
  auto inputImageName = self.network.inputImageNames[0];
  auto maskImageName = self.network.inputImageNames[1];
  auto inputImages = @{
    inputImageName: scaledCroppedInputImage,
    maskImageName: scaledCroppedMaskImage
  };

  auto networkOutputImageName = self.network.outputImageNames[0];
  auto outputImages = @{
    networkOutputImageName: networkOutputImage
  };

  [self.network encodeWithCommandBuffer:commandBuffer inputImages:inputImages
                           outputImages:outputImages];
}

- (void)encodeNetworkPostProcessingWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                  networkOutputImage:(MPSImage *)networkOutputImage
                                 scaledCroppedOutput:(CVPixelBufferRef)scaledCroppedOutput {
  auto scaledCroppedOutputImage = PNKImageFromPixelBuffer(scaledCroppedOutput, self.device);

  [self.correctAlphaKernel encodeToCommandBuffer:commandBuffer inputImage:networkOutputImage
                                     outputImage:scaledCroppedOutputImage];
}

- (void)transferHighFrequencyWithInput:(CVPixelBufferRef)input mask:(CVPixelBufferRef)mask
                                output:(CVPixelBufferRef)output
                   scaledCroppedOutput:(CVPixelBufferRef)scaledCroppedOutput
                      regionOfInterest:(MTLRegion)regionOfInterest {
  cv::Rect roi((int)regionOfInterest.origin.x, (int)regionOfInterest.origin.y,
               (int)regionOfInterest.size.width, (int)regionOfInterest.size.height);

  LTCVPixelBufferImageForReading(input, ^(const cv::Mat &inputMat) {
    LTCVPixelBufferImageForReading(mask, ^(const cv::Mat &maskMat) {
      LTCVPixelBufferImageForReading(scaledCroppedOutput, ^(const cv::Mat &scaledOutputMat) {
        LTCVPixelBufferImageForWriting(output, ^(cv::Mat *outputMat) {
          cv::Mat4b croppedInputMat = inputMat(roi);
          cv::Mat1b croppedMaskMat = maskMat(roi);
          cv::Mat4b croppedOutputMat = (*outputMat)(roi);
          pnk_inpainting::transferHighFrequency(croppedInputMat, croppedMaskMat, scaledOutputMat,
                                                &croppedOutputMat);
        });
      });
    });
  });
}

@end

NS_ASSUME_NONNULL_END

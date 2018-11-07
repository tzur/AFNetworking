// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "PNKFaceModelProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <MetalToolbox/MPSImage+Factory.h>
#import <MetalToolbox/MPSTemporaryImage+Factory.h>

#import "MTLRegion+Factory.h"
#import "PNKAvailability.h"
#import "PNKDeviceAndCommandQueue.h"
#import "PNKImageScale.h"
#import "PNKNeuralNetworkOperationsModel.h"
#import "PNKOpenCVExtensions.h"
#import "PNKPixelBufferUtils.h"
#import "PNKRunnableNeuralNetwork.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKFaceModelProcessor ()

/// Neural network performing the fitting of parameters.
@property (readonly, nonatomic) PNKRunnableNeuralNetwork *network;

/// Device to encode this network operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Pinky kernel used to obtain the region around the face from input image.
@property (readonly, nonatomic) PNKImageScale *faceCropper;

/// Serial queue used to perform the operations when the processor's asynchronic API is called.
/// This separate queue is used because encoding the network can take non-negligible time.
@property (readonly, nonatomic) dispatch_queue_t encodingQueue;

/// Holds the result of neural network.
@property (readonly, nonatomic) MPSImage *outputImage;

@end

@implementation PNKFaceModelProcessor

/// Number of channels of the network output tensor.
static const int kOutputTensorChannelsCount = 258;

- (nullable instancetype)initWithNetworkModelURL:(NSURL *)networkModelURL
                                           error:(NSError * __autoreleasing *)error {
  if (self = [super init]) {
    auto device = PNKDefaultDevice();
    if (!PNKSupportsMTLDevice(device)) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                               description:@"MPS framework is not supported on GPU family %@",
                                           device.name];
      }
      return nil;
    }

    auto scheme = [PNKNetworkSchemeFactory schemeWithDevice:device coreMLModel:networkModelURL
                                                      error:error];
    if (!scheme) {
      return nil;
    }

    _device = device;
    _network = [[PNKRunnableNeuralNetwork alloc] initWithNetworkScheme:*scheme];

    _outputImage = [MPSImage mtb_float16ImageWithDevice:self.device width:1 height:1
                                               channels:kOutputTensorChannelsCount];
    _faceCropper = [[PNKImageScale alloc] initWithDevice:self.device];
    _encodingQueue = dispatch_queue_create("com.lightricks.Pinky.FaceShapeModelProcessor",
                                         DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);
  }
  return self;
}

- (void)fitFaceParametersWithInput:(CVPixelBufferRef)input output:(cv::Mat1f *)output
                          faceRect:(CGRect)faceRect completion:(LTSuccessOrErrorBlock)completion {
  LTParameterAssert(output->rows == 1, @"output rows number should be 1, got %d", output->rows);
  LTParameterAssert(output->cols == kOutputTensorChannelsCount,
                    @"output cols number should be %d, got %d",
                    kOutputTensorChannelsCount, output->cols);

  dispatch_async(self.encodingQueue, ^{
    auto inputRegion = MTLRegionFromCGRect(faceRect);

    auto commandBuffer = [[self.device newCommandQueue] commandBuffer];
    [self encodeWithCommandBuffer:commandBuffer input:input inputRegion:inputRegion
                           output:self.outputImage];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    BOOL success = !commandBuffer.error;
    if (success) {
      [self copyImage:self.outputImage toMat:output];
    }

    completion(success, commandBuffer.error);
  });
}

- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                          input:(CVPixelBufferRef)input inputRegion:(MTLRegion)inputRegion
                         output:(MPSImage *)outputImage {
  LTParameterAssert(self.network.inputImageNames.count == 1, @"Network must have 1 input image, "
                    "got %lu", (unsigned long)self.network.inputImageNames.count);
  NSString *inputImageName = self.network.inputImageNames[0];
  LTParameterAssert(self.network.outputImageNames.count == 1, @"Network must have 1 output image, "
                    "got %lu", (unsigned long)self.network.outputImageNames.count);
  NSString *outputImageName = self.network.outputImageNames[0];

  auto inputImage = PNKImageFromPixelBuffer(input, self.device);

  std::string inputImageNameKey([inputImageName cStringUsingEncoding:NSUTF8StringEncoding]);
  auto croppedSize = self.network.inputImageNamesToSizes.at(inputImageNameKey);
  auto resizedInputImage =
      [MPSTemporaryImage mtb_float16TemporaryImageWithCommandBuffer:commandBuffer
                                                              width:croppedSize.width
                                                             height:croppedSize.height
                                                           channels:croppedSize.depth];

  [self.faceCropper encodeToCommandBuffer:commandBuffer inputImage:inputImage
                              inputRegion:inputRegion outputImage:resizedInputImage];

  [self.network encodeWithCommandBuffer:commandBuffer
                            inputImages:@{inputImageName: resizedInputImage}
                           outputImages:@{outputImageName: outputImage}];
}

- (void)copyImage:(MPSImage *)image toMat:(cv::Mat1f *)mat {
  cv::Mat4hf textureSlice((int)image.height, (int)image.width);
  cv::Mat4f floatSlice((int)image.height, (int)image.width);
  for (int i = 0; i < ((int)image.featureChannels + 3) / 4; ++i) {
    PNKCopyMTLTextureToMat(image.texture, i, 0, &textureSlice);
    LTConvertMat(textureSlice, &floatSlice, CV_32FC4);
    cv::Vec4f value = floatSlice(0);
    int elementsToCopy = std::min((int)image.featureChannels - i * 4, 4);
    memcpy(mat->ptr(0, i * 4), value.val, elementsToCopy * sizeof(float));
  }
}

@end

NS_ASSUME_NONNULL_END

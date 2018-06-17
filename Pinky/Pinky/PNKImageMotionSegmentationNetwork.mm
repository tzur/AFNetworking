// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionSegmentationNetwork.h"

#import "MPSTemporaryImage+Factory.h"
#import "PNKArgmax.h"
#import "PNKImageMotionLayerType.h"
#import "PNKIndexTranslator.h"
#import "PNKRunnableNeuralNetwork.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

const static std::array<uchar, 256> kTranslationTable = {{
  pnk::ImageMotionLayerTypeStatic,
  pnk::ImageMotionLayerTypeSky,
  pnk::ImageMotionLayerTypeStatic,
  pnk::ImageMotionLayerTypeStatic,
  pnk::ImageMotionLayerTypeWater,
  pnk::ImageMotionLayerTypeTrees,
  pnk::ImageMotionLayerTypeGrass,
  pnk::ImageMotionLayerTypeStatic
}};

@interface PNKImageMotionSegmentationNetwork ()

/// Neural network performing image segmentation.
@property (readonly, nonatomic) PNKRunnableNeuralNetwork *network;

/// Device to encode the operations of the network as well as pre- and post-procecssing.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel that performs an argmax operation.
@property (readonly, nonatomic) PNKArgmax *argmax;

/// Kernel that translates layer indices into values from \c pnk::ImageMotionLayerType enum.
@property (readonly, nonatomic) PNKIndexTranslator *layerIndexTranslator;

/// Feature channels count for the output image of the core network (before argmax).
@property (readonly, nonatomic) NSUInteger outputChannels;

@end

@implementation PNKImageMotionSegmentationNetwork

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device
                        networkModelURL:(NSURL *)networkModelURL
                                  error:(NSError * __autoreleasing *)error {
  if (self = [super init]) {
    _device = device;

    auto scheme = [PNKNetworkSchemeFactory schemeWithDevice:self.device coreMLModel:networkModelURL
                                                      error:error];
    if (!scheme) {
      return nil;
    }

    _network = [[PNKRunnableNeuralNetwork alloc] initWithNetworkScheme:*scheme];
    [self validateNetwork];
    [self setChannelCounts];

    _argmax = [[PNKArgmax alloc] initWithDevice:device];
    _layerIndexTranslator = [[PNKIndexTranslator alloc] initWithDevice:device
                                                      translationTable:kTranslationTable];
  }
  return self;
}

- (void)validateNetwork {
  LTParameterAssert(self.network.inputImageNames.count == 1, @"Network must have 1 input image, "
                    "got %lu", (unsigned long)self.network.inputImageNames.count);
  LTParameterAssert(self.network.inputImageNamesToSizes.size() == 1, @"Network must have "
                    "inputImageNamesToSizes dictionary with 1 entry, got %lu",
                    (unsigned long)self.network.inputImageNamesToSizes.size());
  LTParameterAssert(self.network.outputImageNames.count == 1, @"Network must have 1 output image, "
                    "got %lu", (unsigned long)self.network.outputImageNames.count);
}

- (void)setChannelCounts {
  auto inputImageName = self.network.inputImageNames[0];
  auto inputImageSize = self.network.inputImageNamesToSizes[inputImageName.UTF8String];
  _inputChannels = inputImageSize.depth;

  auto outputImageName = self.network.outputImageNames[0];
  auto outputImageNamesToSizes =
      [self.network outputImageSizesFromInputImageSizes:self.network.inputImageNamesToSizes];
  auto outputImageSize = outputImageNamesToSizes[outputImageName.UTF8String];
  _outputChannels = outputImageSize.depth;
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  [self verifyParametersWithInputImage:inputImage outputImage:outputImage];

  NSString *inputImageName = self.network.inputImageNames[0];
  NSString *outputImageName = self.network.outputImageNames[0];

  auto networkOutputImage = [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:commandBuffer
                             width:outputImage.width
                             height:outputImage.height
                             channels:self.outputChannels];

  [self.network encodeWithCommandBuffer:commandBuffer inputImages:@{inputImageName: inputImage}
                           outputImages:@{outputImageName: networkOutputImage}];

  auto rawSegmentationImage = [MPSTemporaryImage pnk_unorm8ImageWithCommandBuffer:commandBuffer
                                                                            width:outputImage.width
                                                                           height:outputImage.height
                                                                         channels:1];
  [self.argmax encodeToCommandBuffer:commandBuffer inputImage:networkOutputImage
                         outputImage:rawSegmentationImage];
  [self.layerIndexTranslator encodeToCommandBuffer:commandBuffer inputImage:rawSegmentationImage
                                       outputImage:outputImage];
}

- (void)verifyParametersWithInputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.width == outputImage.width, @"Input image and ouput image must have "
                    "the same width, got (%lu, %lu)", (unsigned long)inputImage.width,
                    (unsigned long)outputImage.width);
  LTParameterAssert(inputImage.height == outputImage.height, @"Input image and ouput image must "
                    "have the same height, got (%lu, %lu)", (unsigned long)inputImage.height,
                    (unsigned long)outputImage.height);
  LTParameterAssert(inputImage.featureChannels == self.inputChannels, @"Input image must have %lu "
                    "feature channels, got %lu", (unsigned long)self.inputChannels,
                    (unsigned long)inputImage.featureChannels);
  LTParameterAssert(outputImage.featureChannels == 1, @"Output image must have 1 feature channel, "
                    "got %lu", (unsigned long)outputImage.featureChannels);
  LTParameterAssert(inputImage.width % 16 == 0, @"Input image width must be divisible by 16, got: "
                    "%lu", (unsigned long)inputImage.width);
  LTParameterAssert(inputImage.height % 16 == 0, @"Input image height must be divisible by 16, "
                    "got: %lu", (unsigned long)inputImage.height);
}

@end

#endif

NS_ASSUME_NONNULL_END

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKRunnableNeuralNetwork.h"

#import <LTKit/NSArray+Functional.h>
#import <MetalToolbox/MPSImage+Factory.h>
#import <MetalToolbox/MPSTemporaryImage+Factory.h>

#import "LTEasyBoxing+Pinky.h"
#import "PNKCollectionUtils.h"
#import "PNKNetworkSchemeFactory.h"
#import "PNKNeuralNode.h"

NS_ASSUME_NONNULL_BEGIN

/// Dictionary of images with their names as keys.
typedef NSDictionary<NSString *, MPSImage *> PNKImageCollection;

/// Mutable dictionary of images with their names as keys.
typedef NSMutableDictionary<NSString *, MPSImage *> PNKMutableImageCollection;

/// Dictionary of image sizes with image names as keys.
typedef std::unordered_map<std::string, MTLSize> PNKSizeCollection;

@interface PNKRunnableNeuralNetwork ()

/// Network scheme to run.
@property (readonly, nonatomic) pnk::NetworkScheme networkScheme;

@end

@implementation PNKRunnableNeuralNetwork

- (instancetype)initWithNetworkScheme:(const pnk::NetworkScheme &)networkScheme {
  if (self = [super init]) {
    _networkScheme = networkScheme;
  }
  return self;
}

- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                    inputImages:(NSDictionary<NSString *, MPSImage *> *)inputImages
                   outputImages:(NSDictionary<NSString *, MPSImage *> *)outputImages {
  [self encodeWithCommandBuffer:commandBuffer inputImages:inputImages
                inputParameters:[NSDictionary dictionary] outputImages:outputImages];
}

- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                    inputImages:(PNKImageCollection *)inputImages
                inputParameters:(NSDictionary<NSString *, NSObject *> *)inputParameters
                   outputImages:(PNKImageCollection *)outputImages {
  PNKValidateCollection(inputImages, self.networkScheme.inputImagesData.allKeys, @"input images");
  PNKValidateCollection(inputParameters, self.networkScheme.inputParameterNames,
                        @"input parameters");
  PNKValidateCollection(outputImages, self.networkScheme.outputImageNames, @"output images");

  PNKSizeCollection temporaryImageSizes = [self temporaryImageSizesWithInputImages:inputImages
                                                                      outputImages:outputImages];
  [self prefetchStorageWithTemporaryImageSizes:temporaryImageSizes commandBuffer:commandBuffer];
  PNKImageCollection *temporaryImages = [self temporaryImagesWithSizes:temporaryImageSizes
                                                         commandBuffer:commandBuffer];

  auto allImages = [PNKMutableImageCollection dictionaryWithDictionary:temporaryImages];
  [allImages addEntriesFromDictionary:inputImages];
  [allImages addEntriesFromDictionary:outputImages];

  [self updateReadCountsOfInputImages:inputImages
                       withDictionary:self.networkScheme.inputImagesData];
  [self encodeWithCommandBuffer:commandBuffer images:allImages
         networkInputParameters:inputParameters];
}

- (PNKSizeCollection)temporaryImageSizesWithInputImages:(PNKImageCollection *)inputImages
                                           outputImages:(PNKImageCollection *)outputImages {
  __block PNKSizeCollection temporaryImageSizes;
  [inputImages enumerateKeysAndObjectsUsingBlock:^(NSString *name, MPSImage *image, BOOL *) {
    temporaryImageSizes[name.UTF8String] = image.pnk_size;
  }];

  for (PNKNeuralNode *node in self.networkScheme.nodes) {
    NSString *primaryInputImageName = node.primaryInputImageName;
    MTLSize primaryInputSize = temporaryImageSizes[primaryInputImageName.UTF8String];

    NSString *secondaryInputImageName = node.secondaryInputImageName;
    MTLSize secondaryInputSize = secondaryInputImageName ?
        temporaryImageSizes[secondaryInputImageName.UTF8String] : MTLSizeMake(0, 0, 0);

    NSString *outputImageName = node.outputImageName;
    MTLSize outputImageSize = [node outputSizeForPrimaryInputSize:primaryInputSize
                                               secondaryInputSize:secondaryInputSize];

    temporaryImageSizes[outputImageName.UTF8String] = outputImageSize;
  }

  [inputImages enumerateKeysAndObjectsUsingBlock:^(NSString *name, MPSImage *, BOOL *) {
    temporaryImageSizes.erase(name.UTF8String);
  }];

  [outputImages enumerateKeysAndObjectsUsingBlock:^(NSString *name, MPSImage *, BOOL *) {
    temporaryImageSizes.erase(name.UTF8String);
  }];

  return temporaryImageSizes;
}

- (void)prefetchStorageWithTemporaryImageSizes:(const PNKSizeCollection &)temporaryImageSizes
                                 commandBuffer:(id<MTLCommandBuffer>)commandBuffer {
  NSMutableArray<MPSImageDescriptor *> *descriptorList =
      [NSMutableArray arrayWithCapacity:temporaryImageSizes.size()];
  for (auto pair: temporaryImageSizes) {
    auto size = pair.second;
    auto descriptor =
        [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16
                                                       width:size.width height:size.height
                                             featureChannels:size.depth];
    descriptor.storageMode = MTLStorageModePrivate;
    [descriptorList addObject:descriptor];
  }
  [MPSTemporaryImage prefetchStorageWithCommandBuffer:commandBuffer
                                  imageDescriptorList:descriptorList];
}

- (PNKImageCollection *)temporaryImagesWithSizes:(const PNKSizeCollection &)temporaryImageSizes
                                   commandBuffer:(id<MTLCommandBuffer>)commandBuffer {
  auto temporaryImages = [PNKMutableImageCollection dictionary];

  for (auto pair: temporaryImageSizes) {
    auto image = [MPSTemporaryImage mtb_float16TemporaryImageWithCommandBuffer:commandBuffer
                                                                          size:pair.second];
    auto name = [NSString stringWithUTF8String:pair.first.c_str()];
    temporaryImages[name] = image;
  }

  return temporaryImages;
}

- (void)updateReadCountsOfInputImages:(PNKImageCollection *)inputImages
                       withDictionary:(NSDictionary<NSString *, NSNumber *> *)readCountDictionary {
  [inputImages enumerateKeysAndObjectsUsingBlock:^(NSString *name, MPSImage *image, BOOL *) {
    if ([image isKindOfClass:[MPSTemporaryImage class]]) {
      NSUInteger readCountInNetwork = readCountDictionary[name].unsignedIntegerValue;
      if (readCountInNetwork > 1) {
        ((MPSTemporaryImage *)image).readCount += (readCountInNetwork - 1);
      }
    }
  }];
}

- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                         images:(PNKImageCollection *)images
         networkInputParameters:(NSDictionary<NSString *, NSObject *> *)networkInputParameters {
  for (PNKNeuralNode *node in self.networkScheme.nodes) {
    NSString *outputImageName = node.outputImageName;
    MPSImage *outputImage = images[outputImageName];

    NSString *primaryInputImageName = node.primaryInputImageName;
    MPSImage *primaryInputImage = images[primaryInputImageName];

    NSString * _Nullable secondaryInputImageName = node.secondaryInputImageName;
    MPSImage * _Nullable secondaryInputImage = images[secondaryInputImageName];

    NSArray * _Nullable inputParameters =
        [node.inputParameterGlobalNames lt_map:^NSObject *(NSString *name) {
          return networkInputParameters[name];
        }];

    [node encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
            secondaryInputImage:secondaryInputImage inputParameters:inputParameters
                    outputImage:outputImage];
  }
}

- (PNKSizeCollection)outputImageSizesFromInputImageSizes:
    (const PNKSizeCollection &)inputImageSizes {
  PNKSizeCollection imageSizes(inputImageSizes);
  for (PNKNeuralNode *node in self.networkScheme.nodes) {
    NSString *primaryInputImageName = node.primaryInputImageName;
    MTLSize primaryInputImageSize = imageSizes[primaryInputImageName.UTF8String];

    NSString * _Nullable secondaryInputImageName = node.secondaryInputImageName;
    MTLSize secondaryInputImageSize = secondaryInputImageName ?
        imageSizes[secondaryInputImageName.UTF8String] : MTLSizeMake(0, 0, 0);

    NSString *outputImageName = node.outputImageName;
    MTLSize outputImageSize = [node outputSizeForPrimaryInputSize:primaryInputImageSize
                                               secondaryInputSize:secondaryInputImageSize];

    imageSizes[outputImageName.UTF8String] = outputImageSize;
  }

  PNKSizeCollection outputImageSizes;
  for (NSString *outputImageName: self.networkScheme.outputImageNames) {
    outputImageSizes[outputImageName.UTF8String] = imageSizes[outputImageName.UTF8String];
  }
  return outputImageSizes;
}

- (NSArray<NSString *> *)inputImageNames {
  return self.networkScheme.inputImagesData.allKeys;
}

- (std::unordered_map<std::string, MTLSize>)inputImageNamesToSizes {
  return self.networkScheme.inputImageNamesToSizes;
}

- (NSArray<NSString *> *)inputParameterNames {
  return self.networkScheme.inputParameterNames;
}

- (NSArray<NSString *> *)outputImageNames {
  return self.networkScheme.outputImageNames;
}

- (NSDictionary<NSString *, NSString *> *)metadata {
  return self.networkScheme.metadata;
}

@end

NS_ASSUME_NONNULL_END

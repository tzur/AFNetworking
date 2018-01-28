// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKRunnableNeuralNetwork.h"

#import "LTEasyBoxing+Pinky.h"
#import "MPSImage+Factory.h"
#import "MPSTemporaryImage+Factory.h"
#import "PNKNetworkSchemeFactory.h"
#import "PNKNeuralNode.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Dictionary of images with their names as keys.
typedef NSDictionary<NSString *, MPSImage *> PNKImageCollection;

/// Mutable dictionary of images with their names as keys.
typedef NSMutableDictionary<NSString *, MPSImage *> PNKMutableImageCollection;

/// Dictionary of image sizes with image names as keys.
typedef std::unordered_map<std::string, MTLSize> PNKSizeCollection;

@interface PNKRunnableNeuralNetwork ()

/// Network scheme to run.
@property (readonly, nonatomic) pnk::NetworkScheme networkScheme;

/// Dispatch queue to perform encoding asynchronously.
@property (readonly, nonatomic) dispatch_queue_t dispatchQueue;

@end

@implementation PNKRunnableNeuralNetwork

- (instancetype)initWithNetworkScheme:(const pnk::NetworkScheme &)networkScheme {
  if (self = [super init]) {
    _networkScheme = networkScheme;
    _dispatchQueue = dispatch_queue_create("com.lightricks.Pinky.RunnableNeuralNetwork",
                                           DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);
  }
  return self;
}

- (void)encodeAndCommitAsyncWithCommandQueue:(id<MTLCommandQueue>)queue
                                 inputImages:(PNKImageCollection *)inputImages
                                outputImages:(PNKImageCollection *)outputImages
                                  completion:(LTCompletionBlock)completion {
  LTParameterAssert(completion, @"Completion block must not be nil.");

  __block auto buffer = [queue commandBuffer];
  dispatch_async(self.dispatchQueue, ^{
    [self encodeWithCommandBuffer:buffer inputImages:inputImages outputImages:outputImages];
    [buffer addCompletedHandler:^(id<MTLCommandBuffer>) {
      completion();
    }];
    [buffer commit];
  });
}

- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                    inputImages:(PNKImageCollection *)inputImages
                   outputImages:(PNKImageCollection *)outputImages {
  [self validateImageCollection:inputImages withNames:self.networkScheme.inputImageNames
                           type:@"input"];
  [self validateImageCollection:outputImages withNames:self.networkScheme.outputImageNames
                           type:@"output"];
  PNKSizeCollection temporaryImageSizes = [self temporaryImageSizesWithInputImages:inputImages
                                                                      outputImages:outputImages];
  [self prefetchStorageWithTemporaryImageSizes:temporaryImageSizes commandBuffer:commandBuffer];
  PNKImageCollection *temporaryImages = [self temporaryImagesWithSizes:temporaryImageSizes
                                                         commandBuffer:commandBuffer];

  auto allImages = [PNKMutableImageCollection dictionaryWithDictionary:temporaryImages];
  [allImages addEntriesFromDictionary:inputImages];
  [allImages addEntriesFromDictionary:outputImages];

  [self encodeWithCommandBuffer:commandBuffer images:allImages];
}

- (void)validateImageCollection:(PNKImageCollection *)images
                      withNames:(NSArray<NSString *> *)names type:(NSString *)type {
  LTParameterAssert(images.count == names.count, @"%@ images collection must have size of %lu, got "
                    "%lu", type, (unsigned long)names.count, (unsigned long)images.count);
  for (NSString *name in names) {
    LTParameterAssert([images objectForKey:name], @"image with name %@ not found in %@ images "
                      "collection", name, type);
  }
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
      [NSMutableArray arrayWithCapacity:(NSUInteger)temporaryImageSizes.size()];
  for (const auto &nameAndSize: temporaryImageSizes) {
    auto size = nameAndSize.second;
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

  for (const auto &nameAndSize: temporaryImageSizes) {
    auto name = [NSString stringWithUTF8String:nameAndSize.first.c_str()];
    auto image = [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:commandBuffer
                                                                 size:nameAndSize.second];
    temporaryImages[name] = image;
  }

  return temporaryImages;
}

- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                         images:(PNKImageCollection *)images {
  for (PNKNeuralNode *node in self.networkScheme.nodes) {
    NSString *outputImageName = node.outputImageName;
    MPSImage *outputImage = images[outputImageName];

    NSString *primaryInputImageName = node.primaryInputImageName;
    MPSImage *primaryInputImage = images[primaryInputImageName];

    NSString * _Nullable secondaryInputImageName = node.secondaryInputImageName;
    MPSImage * _Nullable secondaryInputImage = images[secondaryInputImageName];

    [node encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
            secondaryInputImage:secondaryInputImage outputImage:outputImage];
  }
}

- (NSArray<NSString *> *)inputImageNames {
  return self.networkScheme.inputImageNames;
}

- (NSArray<NSString *> *)outputImageNames {
  return self.networkScheme.outputImageNames;
}

@end

#endif

NS_ASSUME_NONNULL_END

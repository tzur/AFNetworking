// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Class that produces a segmentation map from a still image. The segmentation mask is a single
/// channel image such that each pixel value is one of \c pnk::ImageMotionLayerType.
API_AVAILABLE(ios(10.0))
@interface PNKImageMotionSegmentationNetwork : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a URL to the network model file. Returns \c nil in case it cannot load the
/// network model from \c networkModelURL. In this case \c error will be filled with the
/// appropriate value. The list of possibe \c error values is specified in the
/// \c PNKNetworkSchemeFactory documentation.
- (nullable instancetype)initWithDevice:(id<MTLDevice>)device
                        networkModelURL:(NSURL *)networkModelURL
                                  error:(NSError **)error NS_DESIGNATED_INITIALIZER;

/// Encodes the segmentation operation into \c commandBuffer. \c inputImage contains the input
/// image. \c outputImage will contain the segmentation map once the \c commandBuffer is completed.
/// \c inputImage and \c outputImage must have the same width and height. These width and height
/// must be both divisible by 16. \c inputImage must have number of channels matching the
/// \c inputChannels property of the network while \c outputImage must have a single channel.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage;

/// Number of feature channels in the network input image.
@property (readonly, nonatomic) NSUInteger inputChannels;

@end

#endif

NS_ASSUME_NONNULL_END

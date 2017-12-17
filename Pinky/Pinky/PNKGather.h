// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Kernel that reshuffles the feature channels of the input image in arbitrary order. Omissions and
/// duplications of channels are permitted.
@interface PNKGather : NSObject <PNKUnaryImageKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device and gathers feature channels of the input image
/// according to the channel numbers as they appear in \c outputFeatureChannelIndices. The input
/// umage must have \c inputFeatureChannels feture channels.
- (instancetype)initWithDevice:(id<MTLDevice>)device
          inputFeatureChannels:(NSUInteger)inputFeatureChannels
   outputFeatureChannelIndices:(const std::vector<ushort> &)outputFeatureChannelIndices
    NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage. \c outputImage must have the same width and
/// height as \c inputImage. The \c featureChannels property of \c outputImage must fit the length
/// of \c outputFeatureChannelIndices provided at kernel initialization.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage;

@end

#endif

NS_ASSUME_NONNULL_END

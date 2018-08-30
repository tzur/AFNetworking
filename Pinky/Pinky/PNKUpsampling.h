// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

/// Upsampling type. See https://www.tensorflow.org/api_docs/python/tf/image/resize_images for
/// discussion.
typedef NS_ENUM(NSUInteger, PNKUpsamplingType) {
  /// Nearest neighbor upsampling.
  PNKUpsamplingTypeNearestNeighbor,
  /// Bilinear upsampling with non-aligned corners.
  PNKUpsamplingTypeBilinear,
  /// Bilinear upsampling with aligned corners.
  PNKUpsamplingTypeBilinearAligned
};

/// Kernel that performs a dyadic upsampling of the input.
API_AVAILABLE(ios(10.0))
@interface PNKUpsampling : NSObject <PNKUnaryKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device and magnifies its input by a factor of 2 in both
/// width and height. The precise upsampling algorithm is defined by \c upsamplingType. The
/// upsampling is per feature channel, so feature channel count is unchanged.
- (instancetype)initWithDevice:(id<MTLDevice>)device
                upsamplingType:(PNKUpsamplingType)upsamplingType NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage. \c inputImage.arrayLength must be equal to
/// \c outputImage.arrayLength. \c outputImage.width must be equal to \c inputImage.width multiplied
/// by \c 2. \c outputImage.height must be equal to \c inputImage.height multiplied by \c 2.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage;

@end

NS_ASSUME_NONNULL_END

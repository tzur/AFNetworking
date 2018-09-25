// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

/// Kernel operating in a pixel-wise manner, searching for the maximal value across all channels and
/// assigning the index of the channel where the maximal value was found to the result at the same
/// pixel location.
@interface PNKArgmax : NSObject <PNKUnaryKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device and performs the argmax operation on the input
/// image.
- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage. \c outputImage must have the same width and
/// height as \c inputImage and have a single channel. On kernel completion each pixel of
/// \c outputImage will contain the index of the channel that represents the maximal value among all
/// channels of the same pixel in \c inputImage.
///
/// @note If the same maximal value appears twice, then the lower index will be in the result.
///
/// @note If \c inputImage has more than \c 256 feature channels - \c outputImage must be half-float
/// or float as \c unorm8 format can represent only \c 256 different values.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage;

@end

NS_ASSUME_NONNULL_END

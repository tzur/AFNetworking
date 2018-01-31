// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Kernel that resamples (upsamples or downsamples) the input image using bilinear interpolation.
/// When called with appropriate channels count it performs Y->RGBA transformation (with alpha
/// channel being set to 1) as well.
@interface PNKImageBilinearScale : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device and scales images using bilinear interpolation.
/// The actual scale is defined by input and output image sizes and does not necessarily preserve
/// the aspect ratio.
- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage. The permitted feature channels combinations
/// of input and output image are
/// <tt>(1, 1), (1, 3), (1, 4), (3, 3), (3, 4), (4, 3) and (4, 4)</tt>. When \c inputFeatureChannels
/// is \c 1 and \c outputFeatureChannels is either \c 3 or \c 4 the Y->RGB(A) transformation is
/// applied.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage;

@end

#endif

NS_ASSUME_NONNULL_END

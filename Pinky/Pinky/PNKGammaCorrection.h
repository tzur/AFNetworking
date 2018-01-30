// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Kernel that performs gamma correction. Input is expected to be an RGBA or BGRA image, the
/// correction is performed only for the R, G and B channels.
@interface PNKGammaCorrection : NSObject <PNKUnaryKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device and gamma corrects the input with \c gamma.
- (instancetype)initWithDevice:(id<MTLDevice>)device gamma:(float)gamma NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as
/// input. Output is written asynchronously to \c outputImage. The texture underlying \c inputImage
/// must be a 2D texture of RGBA or BGRA pixel format. \c outputImage must be the same size and
/// pixel format as \c inputImage.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

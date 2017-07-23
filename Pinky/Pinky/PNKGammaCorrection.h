// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

/// Kernel that performs gamma correction. Input is expected to be an RGBA or BGRA image, the
/// correction is performed only for the R, G and B channels.
@interface PNKGammaCorrection : NSObject <PNKUnaryKernel>

/// Initializes a new kernel that runs on \c device and gamma corrects the input with \c gamma.
- (instancetype)initWithDevice:(id<MTLDevice>)device gamma:(float)gamma NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputTexture as
/// input. Output is written asynchronously to \c outputTexture. \c inputTexture must be a 2D
/// texture of RGBA or BGRA pixel format. \c outputTexture must be the same size and pixel format as
/// \c inputTexture.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 inputTexture:(id<MTLTexture>)inputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

/// Kernel that sets the Alpha channel to a constant value. Input is expected to be an RGB(A) or
/// BGR(A) image.
API_AVAILABLE(ios(10.0))
@interface PNKConstantAlpha : NSObject <PNKUnaryKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device and sets the input's alpha channel to \c alpha.
- (instancetype)initWithDevice:(id<MTLDevice>)device alpha:(float)alpha NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as
/// input. Output is written asynchronously to \c outputImage. \c inputImage must have \c 3 or \c 4
/// feature channels with an RGB(A) or BGR(A) pixel format. \c outputImage must be the same size as
/// \c inputImage and have \c 4 feature channels.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage;

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Kernel filling the output image with zeroes. Can be used on images in private GPU memory such as
/// \c MPSTemporaryImage that cannot be accessed by CPU.
@interface PNKFillWithZeroesKernel : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device and fills the output image with zeroes.
- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer. On kernel completion
/// \c outputImage will be filled with zeroes.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                  outputImage:(MPSImage *)outputImage;

@end

NS_ASSUME_NONNULL_END

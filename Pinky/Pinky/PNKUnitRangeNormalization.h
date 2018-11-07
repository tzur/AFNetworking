// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Applies a per-channel shift and scale on a given image such that the minimal value for each
/// channel becomes equal to \c 0 and the maximal value becomes equal to \c 1.
@interface PNKUnitRangeNormalization : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c device.
- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage. Both \c inputImage and \c outputImage must
/// have \c textureType of \c MTLTextureType2D. \c outputImage must have width, height and feature
/// channel count that match \c inputImage.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage;

@end

NS_ASSUME_NONNULL_END

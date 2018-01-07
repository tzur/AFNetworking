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
/// the aspect ratio. The permitted <tt>(inputFeatureChannels, outputFeatureChannels)</tt>
/// combinations are <tt>(1, 1), (4, 4) and (1, 4)</tt>; in the last case the Y->RGBA transformation
/// is applied.
- (instancetype)initWithDevice:(id<MTLDevice>)device
          inputFeatureChannels:(NSUInteger)inputFeatureChannels
         outputFeatureChannels:(NSUInteger)outputFeatureChannels
    NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage. \c inputImage and \c outputImage must have
/// the numbers of feature channels fitting the \c inputFeatureChannels and \c outputFeatureChannels
/// parameters provided at kernel initialization.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputTexture as
/// input. Output is written asynchronously to \c outputTexture.  \c inputImage and \c outputImage
/// must have \c arrayLength property equal to \c 1.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 inputTexture:(id<MTLTexture>)inputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

@end

#endif

NS_ASSUME_NONNULL_END

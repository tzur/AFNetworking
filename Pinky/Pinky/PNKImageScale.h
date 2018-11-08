// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

/// Interpolation type.
typedef NS_ENUM(NSUInteger, PNKInterpolationType) {
  /// Nearest neighbor interpolation.
  PNKInterpolationTypeNearestNeighbor,
  /// Bilinear interpolation.
  PNKInterpolationTypeBilinear
};

/// Kernel that resamples (upsamples or downsamples) the input. When called with appropriate
/// channels count it performs Y->RGBA transformation (with alpha channel being set to 1) or RGB->Y
/// transformation alongside the resampling.
@interface PNKImageScale : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device and scales images using \c interpolation. The
/// actual scale is defined by input and output image sizes and does not necessarily preserve the
/// aspect ratio.
- (instancetype)initWithDevice:(id<MTLDevice>)device
                 interpolation:(PNKInterpolationType)interpolation NS_DESIGNATED_INITIALIZER;

/// Initializes a new kernel that runs on \c device and scales images using bilinear interpolation.
/// The actual scale is defined by input and output image sizes and does not necessarily preserve
/// the aspect ratio.
- (instancetype)initWithDevice:(id<MTLDevice>)device;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage. The feature channels for both \c inputImage
/// and \c outputImage must be either \c 1, \c 3 or \c 4. When the feature channels of \c inputImage
/// is \c 1 and the feature channels of \c outputImage is either \c 3 or \c 4 the <tt>Y->RGB(A)</tt>
/// transformation is applied. When the feature channels of \c inputImage is \c 3 or \c 4 and the
/// feature channels of \c outputImage is \c 1 the <tt>RGB(A)->Y</tt> transformation is applied.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage;

/// Encodes the operation performed by the kernel to \c commandBuffer using the region of
/// \c inputImage defined by \c inputRegion as input. Output is written asynchronously to the whole
/// \c outputImage. Only the first 2 dimensions (x/y/height/width) of \c inputRegion are taken into
/// account. The feature channels for both \c inputImage and \c outputImage must be either \c 1,
/// \c 3 or \c 4. When the feature channels of \c inputImage is \c 1 and the feature channels of
/// \c outputImage is either \c 3 or \c 4 the <tt>Y->RGB(A)</tt> transformation is applied. When the
/// feature channels of \c inputImage is \c 3 or \c 4 and the feature channels of \c outputImage is
/// \c 1 the <tt>RGB(A)->Y</tt> transformation is applied.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage inputRegion:(MTLRegion)inputRegion
                  outputImage:(MPSImage *)outputImage;

/// Encodes the operation performed by the kernel to \c commandBuffer using the region of
/// \c inputImage defined by \c inputRegion as input. Output is written asynchronously to the region
/// of \c outputImage defined by \c outputRegion. Only the first 2 dimensions (x/y/height/width) of
/// both \c inputRegion and \c outputRegion are taken into account. The feature channels for both
/// \c inputImage and \c outputImage must be either \c 1, \c 3 or \c 4. When the feature channels of
/// \c inputImage is \c 1 and the feature channels of \c outputImage is either \c 3 or \c 4 the
/// <tt>Y->RGB(A)</tt> transformation is applied. When the feature channels of \c inputImage is \c 3
/// or \c 4 and the feature channels of \c outputImage is \c 1 the <tt>RGB(A)->Y</tt> transformation
/// is applied.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage inputRegion:(MTLRegion)inputRegion
                  outputImage:(MPSImage *)outputImage outputRegion:(MTLRegion)outputRegion;

@end

NS_ASSUME_NONNULL_END

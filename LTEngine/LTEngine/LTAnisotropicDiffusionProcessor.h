// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import <LTEngine/LTImageProcessor.h>

NS_ASSUME_NONNULL_BEGIN

/// Maximal available size to use when setting the kernel size in the
/// \c LTAnisotropicDiffusionProcessor. The upper bound value depends on the performance of the
/// currently supported devices since a large kernel size can significantly increase the processing
/// time. Upper bound value is determined to be the maximal size for which processing an input of
/// size ~0.2MP to an output of size ~8MP does not exceed <tt>1.3+-0.1</tt> seconds on iPhone 5S.
extern const NSUInteger kKernelSizeUpperBound;

@class LTTexture;

/// Processor for performing an anisotropic defussion from a given texture to a texture with a
/// larger or equal size using a guide texture for determining the extent of the diffusion.
/// Diffusion is applied in two passes: first horizontally and then vertically and without iterative
/// processing.
@interface LTAnisotropicDiffusionProcessor : LTImageProcessor

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c input, and \c output. Identical to:
/// @code
///    [initWithInput:input guide:nil output:output]
/// @endcode
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Initializes with the given \c input, \c guide and \c output. \c input size must be smaller than
/// or equal to the \c output size in both dimensions, \c guide and \c output sizes must be equal
/// and \c input and \c output pixel formats must have the same number of components. If \c guide
/// is set to \c nil, \c input is taken as the guide texture.
- (instancetype)initWithInput:(LTTexture *)input guide:(LTTexture * _Nullable)guide
                       output:(LTTexture *)output
    NS_DESIGNATED_INITIALIZER;

/// Range sigma used when calculating color differences between neighbour pixels in the \c guide
/// texture. Must be a positive value. Set to \c 0.1 by default.
@property (nonatomic) CGFloat rangeSigma;

/// Kernel size of \c guide neighbour pixels to take in account when calculating the diffusion
/// extent of a given pixel. It's recommended to fit the \c kernelSize to the ratio between the
/// \c input size and the \c output size: The larger the ratio is, the larger the kernel size should
/// be. Value must be an odd number in <tt>[1, kKernelSizeUpperBound]</tt>. Set to \c 15 by default.
///
/// @note a large \c kernelSize can significantly increase the processing time.
/// @note automatical mapping between the ratio and the recommended kernel size should be added.
@property (nonatomic) NSUInteger kernelSize;

@end

NS_ASSUME_NONNULL_END

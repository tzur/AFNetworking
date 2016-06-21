// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// Pre-calculated value for the \c LTConsistentGaussianFilterProcessor initializer.
///
/// @note Produces a bad approximation of an actual gaussian blur but the best performance.
extern const CGFloat kGaussianEnergyFactor50Percent;

/// Pre-calculated value for the \c LTConsistentGaussianFilterProcessor initializer.
///
/// @note This value can be used in general applications - provides a reasonable trade-off between
/// the quality and the performance.
extern const CGFloat kGaussianEnergyFactor68Percent;

/// Pre-calculated value for the \c LTConsistentGaussianFilterProcessor initializer.
extern const CGFloat kGaussianEnergyFactor87Percent;

/// Pre-calculated value for the \c LTConsistentGaussianFilterProcessor initializer.
///
/// @note Produces a blur that differs from a real gaussian so little that is not perceivable.
extern const CGFloat kGaussianEnergyFactor95Percent;

/// Pre-calculated value for the \c LTConsistentGaussianFilterProcessor initializer.
///
/// @note Produces an almost perfect approximation of an actual gaussian blur but the worst
/// performance. Probably shouldn't be used in production. Provided for the reference.
extern const CGFloat kGaussianEnergyFactor99Percent;

/// Applies a gaussian blur to an input texture.
///
/// The processor blurs images in such a way that given a \c sigma the blur radius (in pixels)
/// will be proportional to an input image size.
///
/// Effectively this means that if the processed output is scaled down a constant size, the blur
/// radius will depend only on the \c sigma value irrespective to the actual image size.
///
/// @note For images originating from a phone camera the \c sigma of \c 0.003 is a good value to
/// start with and it can be tweaked to achieve the desired results.
@interface LTConsistentGaussianFilterProcessor : LTImageProcessor

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the processor with \c input and \c output textures accordingly.
///
/// @param sigma parameter controls the blur degree - larger value means more blur.
/// @param gaussianEnergyFactor controls how the convolution kernel is calculated.
/// Larger value causes the convolution kernel to be more close to the real gaussian function but
/// worsens the processor performance. The \c kGaussianEnergyFactorXX constants provide
/// a convenience way to choose the value. Must be in \c (0, 4).
///
/// @see \c LTGaussianConvolutionDivider for constraints on \c sigma and \c gaussianEnergyFactor.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output sigma:(CGFloat)sigma
         gaussianEnergyFactor:(CGFloat)gaussianEnergyFactor NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

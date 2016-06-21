// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

NS_ASSUME_NONNULL_BEGIN

/// Utility class that can be used to calculate a way to split a required gaussian function
/// convolution into a series of convolutions with a smaller kernel that will result in the same
/// effect on the image. It's based on the fact that the convolution of two gaussians is a gaussian.
@interface LTGaussianConvolutionDivider : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes an instance of \c LTGaussianConvolutionDivider.
/// @param sigma is the standard deviation of the gaussian function to convolve with. Must be
/// > \c 0.
/// @param spatialUnit is the metric distance between two adjacent pixels/convolution kernel taps.
/// Must be > \c 0.
/// @param maxFilterTaps is the maximum convolution kernel length allowed. Must be odd and > \c 3.
/// @param gaussianEnergyFactor is the coefficient that controls the math. correctness of
/// the smaller kernel used in the series. It is scaled as \c sigma times. Must be in \c (0, 4).
///
/// @see https://en.wikipedia.org/wiki/68–95–99.7_rule
- (instancetype)initWithSigma:(CGFloat)sigma spatialUnit:(CGFloat)spatialUnit
                maxFilterTaps:(NSUInteger)maxFilterTaps
         gaussianEnergyFactor:(CGFloat)gaussianEnergyFactor NS_DESIGNATED_INITIALIZER;

/// Length of convolution series.
@property (readonly, nonatomic) NSUInteger iterationsRequired;

/// Gaussian function standard deviation used in each iteration.
@property (readonly, nonatomic) CGFloat iterationSigma;

/// Minimum amount of the convolution kernel taps based on \c gaussianEnergyFactor and \c sigma.
@property (readonly, nonatomic) NSUInteger numberOfFilterTaps;

/// Maximum sigma that can be reached in a single iteration based on \c spatialUnit and
/// \c gaussianEnergyFactor.
@property (readonly, nonatomic) CGFloat maxSigmaPerIteration;

@end

NS_ASSUME_NONNULL_END

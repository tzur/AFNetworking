// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

@class LT3DLUT, LTTexture;

/// Processor calculating 3D lookup tables that map the color palette of an input image to the color
/// palette of a reference image. This can be used to match the appearance of two images when
/// combining them, or to create unique filters that are "adaptive", since the lookup table is
/// generated based on the input, rather than being fixed.
@interface LTColorTransferProcessor : NSObject

/// Block used as progress handler for color transfer lookup tables calculation, providing the
/// color transfer 3D lookup table and the number of completed iterations after every iteration.
typedef void (^LTColorTransferProgressBlock)(NSUInteger iterationsCompleted, LT3DLUT *lut);

/// Returns a 3D lookup table that can be used to map the \c input's color palette to the
/// \c reference's palette. If \c progress is provided, it will be called with the result lookup
/// table after every iteration of the algorithm, representing the gradual transition from the
/// \c input palette to the \c reference's.

/// @important Both \c input and \c reference must be of \c LTGLPixelFormatRGBA8Unorm pixel format,
/// and should be already downsampled to have the \c recommendedNumberOfPixels for optimal running
/// time.
/// @important The alpha channel of both textures is ignored, and the other channels must not be
/// premultiplied for accurate results.
///
- (LT3DLUT *)lutForInputTexture:(LTTexture *)input referenceTexture:(LTTexture *)reference
                       progress:(nullable LTColorTransferProgressBlock)progress;

/// Returns a 3D lookup table that can be used to map the \c input's color palette to the
/// \c reference's palette. If \c progress is provided, it will be called with the result lookup
/// table after every iteration of the algorithm (except for the last one), representing the gradual
/// transition from the \c input palette to the \c reference's.
///
/// @important Both \c input and \c refernece must should be already downsampled to have the
/// \c recommendedNumberOfPixels for optimal running time.
/// @important The alpha channel of both textures is ignored, and the other channels must not be
/// premultiplied for accurate results.
/// @note Can run on any thread, callback will be called on the same thread.
- (LT3DLUT *)lutForInputMat:(const cv::Mat4b &)input referenceMat:(const cv::Mat4b &)reference
                   progress:(nullable LTColorTransferProgressBlock)progress;

/// Recommended number of pixels for both \c input and \reference for optimal combination of
/// results quality and running time.
@property (class, readonly, nonatomic) NSUInteger recommendedNumberOfPixels;

/// Number of iterations to run, higher number increases the quality of results and running time.
/// Must be in range <tt>[0, 50]</tt>, default is \c 20.
@property (nonatomic) NSUInteger iterations;
LTPropertyDeclare(NSUInteger, iterations, Iterations);

/// Number of histogram bins used for the color transfer. Must be in range <tt>[2, 255]</tt>,
/// default is \c 32.
@property (nonatomic) NSUInteger histogramBins;
LTPropertyDeclare(NSUInteger, histogramBins, HistogramBins);

/// Damping factor for progress of each iteration towards the reference. Lower values yield smaller
/// steps towards the reference's palette in each iteration, but increase the chance of convergence.
/// Must be in range <tt>[0, 1]</tt>, default is \c 0.2.
@property (nonatomic) float dampingFactor;
LTPropertyDeclare(float, dampingFactor, DampingFactor);

/// Number of additional noisy copies used for regularization. Small number of copies (or none) may
/// yield artifcats where very close colors are mapped to very different ones. Must be in range
/// <tt>[0, 5]</tt>, default is \c 1.
@property (nonatomic) NSUInteger noisyCopies;
LTPropertyDeclare(NSUInteger, noisyCopies, NoisyCopies);

/// Standard deviation of the gaussian noise applied the noisy copies. Must be nonnegative, default
/// is \c 0.1.
@property (nonatomic) float noiseStandardDeviation;
LTPropertyDeclare(float, noiseStandardDeviation, NoiseStandardDeviation);

@end

NS_ASSUME_NONNULL_END

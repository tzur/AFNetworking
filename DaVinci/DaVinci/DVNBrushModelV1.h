// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTInterval.h>

#import "DVNBrushModel.h"

NS_ASSUME_NONNULL_BEGIN

@class DVNBlendMode;

/// Mode determining the way the source image (but not the mask) defined in a \c DVNBrushModelV1
/// object should be sampled in order to compute the color values mapped onto the brush tip
/// geometry.
LTEnumDeclare(NSUInteger, DVNSourceSamplingMode,
  /// The source image should be sampled, per rendered fragment of the brush tip geometry, at the
  /// normalized floating-point coordinates of the fragment center.
  DVNSourceSamplingModeFixed,
  /// The source image should be sampled, per rendered fragment of the brush tip geometry, at the
  /// normalized floating-point coordinates of the geometry center.
  DVNSourceSamplingModeQuadCenter,
  /// The source image should be sampled, per rendered fragment of the brush tip geometry, such that
  /// a subimage of the source image is mapped onto the geometry.
  DVNSourceSamplingModeSubimage
);

/// Model determining brushes with version 1. A brush with version 1 is capable of creating brush
/// tip geometry (but no vector stroke geometry) onto which a potentially masked image, constructed
/// by colors sampled from a so-called source image (short: source) and a single-channel image, the
/// so-called mask image (short: mask), is mapped. The model allows several parameters to define
/// random distributions, for the sake of a larger and more interesting variety of brushes.
///
/// The \c isValidTextureMapping: method of an instance of this class returns \c YES if
/// a) the texture mapping contains a value for keys \c sourceImageURL and \c maskImageURL, and
/// b) the texture mapping contains a value for key \c edgeAvoidanceGuideImageURL if the value
/// of the \c edgeAvoidanceGuideImageURL property is not the empty string, and
/// c) the keys of the texture mapping are a subset of the \c imageURLPropertyKeys of the class.
@interface DVNBrushModelV1 : DVNBrushModel

/// Returns a copy of the receiver with the exception of the given \c spacing, clamped to the
/// \c allowedSpacingRange of the receiver.
- (instancetype)copyWithSpacing:(CGFloat)spacing;

/// Returns a copy of the receiver with the exception of the given \c numberOfSamplesPerSequence,
/// clamped to the \c allowedNumberOfSamplesPerSequenceRange of the receiver.
- (instancetype)copyWithNumberOfSamplesPerSequence:(NSUInteger)numberOfSamplesPerSequence;

/// Returns a copy of the receiver with the exception of the given \c sequenceDistance, clamped to
/// the \c allowedSequenceDistanceRange of the receiver.
- (instancetype)copyWithSequenceDistance:(CGFloat)sequenceDistance;

/// Returns a copy of the receiver with the exception of the given \c countRange, clamped to the
/// \c allowedCountRange of the receiver.
- (instancetype)copyWithCountRange:(lt::Interval<NSUInteger>)countRange;

/// Returns a copy of the receiver with the exception of the given \c distanceJitterFactorRange,
/// clamped to the \c allowedDistanceJitterFactorRange of the receiver.
- (instancetype)copyWithDistanceJitterFactorRange:(lt::Interval<CGFloat>)distanceJitterFactorRange;

/// Returns a copy of the receiver with the exception of the given \c angleRange, clamped to the
/// \c allowedAngleRange of the receiver.
- (instancetype)copyWithAngleRange:(lt::Interval<CGFloat>)angleRange;

/// Returns a copy of the receiver with the exception of the given \c scaleJitterRange, clamped to
/// the \c allowedScaleJitterRange of the receiver.
- (instancetype)copyWithScaleJitterRange:(lt::Interval<CGFloat>)scaleJitterRange;

/// Returns a copy of the receiver with the exception of the given \c taperingLengths,
/// component-wise clamped to the \c allowedTaperingLengthRange of the receiver.
- (instancetype)copyWithTaperingLengths:(LTVector2)taperingLengths;

/// Returns a copy of the receiver with the exception of the given \c minimumTaperingScaleFactor,
/// clamped to the \c allowedMinimumTaperingScaleFactorRange of the receiver.
- (instancetype)copyWithMinimumTaperingScaleFactor:(CGFloat)minimumTaperingScaleFactor;

/// Returns a copy of the receiver with the exception of the given \c taperingFactors, clamped to
/// the \c allowedTaperingFactorRange of the receiver.
- (instancetype)copyWithTaperingFactors:(LTVector2)taperingFactors;

/// Returns a copy of the receiver with the exception of the given \c flow, clamped to the
/// \c flowRange of the receiver.
- (instancetype)copyWithFlow:(CGFloat)flow;

/// Returns a copy of the receiver with the exception of the given \c flowExponent, clamped to the
/// range of positive numbers.
- (instancetype)copyWithFlowExponent:(CGFloat)flowExponent;

/// Returns a copy of the receiver with the exception of the given \c color, component-wise clamped
/// to range <tt>[0, 1]</tt>.
- (instancetype)copyWithColor:(LTVector3)color;

/// Returns a copy of the receiver with the exception of the given \c brightnessJitter, clamped to
/// the \c allowedBrightnessJitterRange of the receiver.
- (instancetype)copyWithBrightnessJitter:(CGFloat)brightnessJitter;

/// Returns a copy of the receiver with the exception of the given \c hueJitter, clamped to the
/// \c allowedHueJitterRange of the receiver.
- (instancetype)copyWithHueJitter:(CGFloat)hueJitter;

/// Returns a copy of the receiver with the exception of the given \c saturationJitter, clamped to
/// the \c allowedSaturationJitterRange of the receiver.
- (instancetype)copyWithSaturationJitter:(CGFloat)saturationJitter;

/// Returns a copy of the receiver with the exception of the given \c sourceSamplingMode.
- (instancetype)copyWithSourceSamplingMode:(DVNSourceSamplingMode *)sourceSamplingMode;

/// Returns a copy of the receiver with the exception of the given \c brushTipImageGridSize,
/// component-wise rounded to the closest positive integer number.
- (instancetype)copyWithBrushTipImageGridSize:(LTVector2)brushTipImageGridSize;

/// Returns a copy of the receiver with the exception of the given \c sourceImageURL.
- (instancetype)copyWithSourceImageURL:(NSURL *)sourceImageURL;

/// Returns a copy of the receiver with the exception of the given \c sourceImageIsNonPremultiplied
/// indication.
- (instancetype)copyWithSourceImageIsNonPremultiplied:(BOOL)sourceImageIsNonPremultiplied;

/// Returns a copy of the receiver with the exception of the given \c maskImageURL.
- (instancetype)copyWithMaskImageURL:(NSURL *)maskImageURL;

/// Returns a copy of the receiver with the exception of the given \c blendMode.
- (instancetype)copyWithBlendMode:(DVNBlendMode *)blendMode;

/// Returns a copy of the receiver with the exception of the given \c edgeAvoidance, clamped to the
/// \c allowedEdgeAvoidanceRange of this class.
- (instancetype)copyWithEdgeAvoidance:(CGFloat)edgeAvoidance;

/// Returns a copy of the receiver with the exception of the given \c edgeAvoidanceGuideImageURL.
- (instancetype)copyWithEdgeAvoidanceGuideImageURL:(NSURL *)edgeAvoidanceGuideImageURL;

/// Returns a copy of the receiver with the exception of the given \c edgeAvoidanceSamplingOffset,
/// clamped to the \c allowedEdgeAvoidanceSamplingOffsetRange of this class.
- (instancetype)copyWithEdgeAvoidanceSamplingOffset:(CGFloat)edgeAvoidanceSamplingOffset;

#pragma mark -
#pragma mark Brush Tip Pattern
#pragma mark -

/// Factor, multiplied by \c scale, determining the distance between the centers of the brush tip
/// geometry on the curve along which the brush stroke is rendered. A value of \c 1 causes the brush
/// tip squares to be adjacent on a straight line axis-aligned in the spline coordinate system, for
/// any value of \c scale, while a value of \c 0 causes all squares to be on top of each other.
///
/// (Order) Dependencies:
/// \c scale
@property (readonly, nonatomic) CGFloat spacing;

/// Allowed range of \c spacing.
@property (class, readonly, nonatomic) lt::Interval<CGFloat> allowedSpacingRange;

/// Number of brush tip squares determining a single sequence of brush tips. The brush tip squares
/// inside a sequence is spaced according to \c spacing, while sequences themselves are spaced
/// according to \c sequenceDistance.
///
/// (Order) Dependencies: none
@property (readonly, nonatomic) NSUInteger numberOfSamplesPerSequence;

/// Allowed range of \c numberOfSamplesPerSequence.
@property (class, readonly, nonatomic) lt::Interval<NSUInteger>
    allowedNumberOfSamplesPerSequenceRange;

/// Factor, multiplied by \c scale, determining the distance between the center of the last brush
/// tip geometry of a sequence, as defined by \c numberOfSamplesPerSequence, and the center of the
/// first brush tip geometry of the next sequence. A value of \c 1 causes the square brush tip
/// geometry to be adjacent on a straight line axis-aligned in the spline coordinate system, for any
/// value of \c scale.
///
/// (Order) Dependencies:
/// \c scale
@property (readonly, nonatomic) CGFloat sequenceDistance;

/// Allowed range of \c sequenceDistance.
@property (class, readonly, nonatomic) lt::Interval<CGFloat> allowedSequenceDistanceRange;

#pragma mark -
#pragma mark Brush Tip Duplications
#pragma mark -

/// Non-empty support of the uniform distribution determining the possible number of times each
/// brush tip square can randomly be duplicated, after creation according to \c spacing,
/// \c numberOfSamplesPerSequence, and \c sequenceDistance. A value of <tt>[1, 1]</tt> has the
/// effect that no brush tip square is duplicated at all; a value of <tt>[0, 1]</tt> has the effect
/// that a brush tip square may be removed or not.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
@property (readonly, nonatomic) lt::Interval<NSUInteger> countRange;

/// Allowed range of \c countRange.
@property (class, readonly, nonatomic) lt::Interval<NSUInteger> allowedCountRange;

#pragma mark -
#pragma mark Random Spatial Jittering, Rotation and Scaling of Brush Tip Geometry
#pragma mark -

/// Non-empty support of the uniform distribution determining the possible non-negative number
/// multiplicative factors for computing the random distance by which each brush tip square is
/// randomly translated. A value of <tt>[a, b]</tt> has the effect that the brush tip squares are
/// translated by at least <tt>a * scale</tt> and by at most <tt>b * scale</tt>. A value of
/// <tt>[0, 0]</tt> has the effect that no brush tip square is translated at all.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c countRange
@property (readonly, nonatomic) lt::Interval<CGFloat> distanceJitterFactorRange;

/// Allowed range of \c distanceJitterFactorRange.
@property (class, readonly, nonatomic) lt::Interval<CGFloat> allowedDistanceJitterFactorRange;

/// Non-empty support of the uniform distribution, in range <tt>[0, 4 * M_PI)</tt>, determining the
/// possible angles, in radians, by which the brush tip squares are randomly rotated around their
/// centers. A value of <tt>[a, b]</tt> has the effect that the brush tip square is rotated by at
/// least \c a and by at most \c b radians. A value of <tt>[0, 0]</tt> has the effect that no brush
/// tip square is not rotated at all.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c countRange
@property (readonly, nonatomic) lt::Interval<CGFloat> angleRange;

/// Allowed range of \c angleRange.
@property (class, readonly, nonatomic) lt::Interval<CGFloat> allowedAngleRange;

/// Non-empty support, in <tt>[0, CGFloatMax]</tt>, of the uniform distribution determining the
/// possible scale factors by which the brush tip squares are randomly scaled around their centers.
/// A value of <tt>[1, 1]</tt> has the effect that no brush tip square is scaled; a value of
/// <tt>[0, 0]</tt> has the effect that all brush tip squares are removed. A value of
/// <tt>[0, CGFloatMax]</tt> has the effect that all sizes are possible for the brush tip squares.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c countRange
@property (readonly, nonatomic) lt::Interval<CGFloat> scaleJitterRange;

/// Allowed range of \c scaleJitterRange.
@property (class, readonly, nonatomic) lt::Interval<CGFloat> allowedScaleJitterRange;

#pragma mark -
#pragma mark Tapering
#pragma mark -

/// Factor, multiplied by \c scale, determining the length of the tapering applied to the brush tip
/// geometry at the beginning and at the end of the brush stroke.
///
/// (Order) Dependencies:
/// \c scale
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c countRange
/// \c distanceJitterFactorRange
/// \c angleRange
/// \c scaleJitterRange
@property (readonly, nonatomic) LTVector2 taperingLengths;

/// Allowed range of the x- and y-coordinate of \c taperingLengths.
@property (class, readonly, nonatomic) lt::Interval<float> allowedTaperingLengthRange;

/// Multiplicative factor, in range <tt>[0, 1]</tt>, used for determining the effect of the tapering
/// on the first (/last) brush tip of the entire brush stroke geometry. A value of \c 0 results in
/// the very first (/last) brush tip geometry to be non-existant, while a value of \c 0.5 results in
/// the very first (/last) brush tip geometry having half the edge length of the geometry of the
/// last (/first) brush tip at the start (/end) part of the tapering (if \c scaleJitterRange equals
/// <tt>[1, 1]</tt>).
///
/// (Order) Dependencies:
/// \c scale
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c countRange
/// \c distanceJitterFactorRange
/// \c angleRange
/// \c scaleJitterRange
@property (readonly, nonatomic) CGFloat minimumTaperingScaleFactor;

/// Allowed range of \c minimumTaperingScaleFactor.
@property (class, readonly, nonatomic) lt::Interval<CGFloat> allowedMinimumTaperingScaleFactorRange;

/// Vector, with coordinates in range \c allowedTaperingFactorRange, used for adjusting the growth
/// behavior of the tapering along the brush stroke. The x-coordinate (/y-coordinate) determines
/// the growth behavior at the beginning (/end) of the brush stroke. Each coordinate, \c c, is used
/// for computing the cubic Bezier curve determined by the values \c 0, \c c, \c 1, \c 1, in this
/// order. The values of the Bezier curve are used to compute the scale factor to be applied to the
/// brush tip squares, in addition to the other tapering parameters.
///
/// (Order) Dependencies:
/// \c scale
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c countRange
/// \c distanceJitterFactorRange
/// \c angleRange
/// \c scaleJitterRange
/// \c taperingLengths
/// \c minimumTaperingScaleFactor
@property (readonly, nonatomic) LTVector2 taperingFactors;

/// Allowed range of the x- and y-coordinate of \c taperingFactors.
@property (class, readonly, nonatomic) lt::Interval<float> allowedTaperingFactorRange;

#pragma mark -
#pragma mark Flow
#pragma mark -

/// Multiplicative factor, in range <tt>flowRange</tt>, used as base value for computing the brush
/// flow.
///
/// (Order) Dependencies:
/// \c flowRange
@property (readonly, nonatomic) CGFloat flow;

/// Range of possible brush tip flows, in range <tt>[0, 1]</tt>. Refer to documentation of \c flow
/// property for more details.
@property (readonly, nonatomic) lt::Interval<CGFloat> flowRange;

/// Allowed range of \c flowRange.
@property (class, readonly, nonatomic) lt::Interval<CGFloat> allowedFlowRange;

/// Positive number for computing the final value used as brush flow. The final flow value is given
/// by <tt>flow^flowExponent</tt>.
///
/// (Order) Dependencies:
/// \c flow
@property (readonly, nonatomic) CGFloat flowExponent;

/// Allowed range of \c flowExponent.
@property (class, readonly, nonatomic) lt::Interval<CGFloat> allowedFlowExponentRange;

#pragma mark -
#pragma mark Colors
#pragma mark -

/// Color to be used as base tint of the brush tip.
///
/// (Order) Dependencies: none
@property (readonly, nonatomic) LTVector3 color;

/// Multiplicative factor, in range <tt>[0, 1]</tt>, for computing the range of values from which
/// the brightness of the brush tip is randomly chosen. The aforementioned range is computed by
/// chosing a random number from the uniform distribution with support
/// <tt>[0, brightnessJitter]</tt>, denoted \c offset, then chosing a random number from the uniform
/// distribution with support <tt>[brightness - offset, brightness + offset]</tt>, and finally
/// clamping the value to <tt>[0, 1]</tt>. A value of \c 0 yields an unchanged brush tip brightness,
/// while a value of \c 1 yields allows for arbitrary brightness changes.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c color
@property (readonly, nonatomic) CGFloat brightnessJitter;

/// Allowed range of \c brightnessJitter.
@property (class, readonly, nonatomic) lt::Interval<CGFloat> allowedBrightnessJitterRange;

/// Multiplicative factor, in range <tt>[0, 1]</tt>, for computing the range of values from which
/// the hue of the brush tip is randomly chosen. The aforementioned range is computed by chosing a
/// random number from the uniform distribution with support <tt>[0, hueJitter]</tt>, denoted
/// \c offset, then chosing a random number from the uniform distribution with support
/// <tt>[hue - offset, hue + offset]</tt>, and finally clamping the value to <tt>[0, 1]</tt>. A
/// value of \c 0 yields an unchanged brush tip hue, while a value of \c 1 yields allows for
/// arbitrary hue changes.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c color
@property (readonly, nonatomic) CGFloat hueJitter;

/// Allowed range of \c hueJitter.
@property (class, readonly, nonatomic) lt::Interval<CGFloat> allowedHueJitterRange;

/// Multiplicative factor, in range <tt>[0, 1]</tt>, for computing the range of values from which
/// the saturation of the brush tip is randomly chosen. The aforementioned range is computed by
/// chosing a random number from the uniform distribution with support
/// <tt>[0, saturationJitter]</tt>, denoted \c offset, then chosing a random number from the uniform
/// distribution with support <tt>[saturation - offset, saturation + offset]</tt>, and finally
/// clamping the value to <tt>[0, 1]</tt>. A value of \c 0 yields an unchanged brush tip saturation,
/// while a value of \c 1 yields allows for arbitrary saturation changes.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c color
@property (readonly, nonatomic) CGFloat saturationJitter;

/// Allowed range of \c saturationJitter.
@property (class, readonly, nonatomic) lt::Interval<CGFloat> allowedSaturationJitterRange;

#pragma mark -
#pragma mark Texture Mapping
#pragma mark -

/// Mode determining the way the source (but not the mask) should be sampled in order to compute the
/// color values mapped onto the brush tip geometry.
///
/// (Order) Dependencies: none
@property (readonly, nonatomic) DVNSourceSamplingMode *sourceSamplingMode;

/// Integer vector whose \c x and \c y values define the number of columns and rows, respectively,
/// of the regular grid of subimages of which the mask image is assumed to consist. The subimages
/// are randomly mapped onto the brush tip geometry during brush stroke rendering. If
/// \c sourceSamplingMode is \c DVNSourceSamplingModeSubimage, the source image is assumed to
/// consist of subimages determined by the same aforementioned grid. In this case, the subimages are
/// mapped onto the brush tip geometry as well, analogously to the subimages of the mask image.
///
/// (Order) Dependencies:
/// \c sourceSamplingMode
@property (readonly, nonatomic) LTVector2 brushTipImageGridSize;

/// URL associated with the source image, a single-channel or RGBA image sampled during brush stroke
/// rendering, affected by the previous tonal manipulations such as \c color, \c brightnessJitter,
/// \c hueJitter, and \c saturationJitter. If \c brushTipImageGridSize is used for the image
/// according to \c sourceSamplingMode, the image is assumed to consist of a regular grid of
/// subimages which has size \c brushTipImageGridSize. If \c brushTipImageGridSize is not
/// <tt>(1, 1)</tt>, the subimages are chosen randomly.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c flow
/// \c color
/// \c brightnessJitter
/// \c hueJitter
/// \c saturationJitter
/// \c brushTipImageGridSize
/// \c sourceSamplingMode
@property (readonly, nonatomic) NSURL *sourceImageURL;

/// \c YES if the source image is non-premultiplied.
///
/// (Order) Dependencies:
/// \c sourceImageURL
@property (readonly, nonatomic) BOOL sourceImageIsNonPremultiplied;

/// URL associated with the mask applied to color values sampled from the source image. The mask
/// image is assumed to consist of a regular grid of subimages which has size
/// \c brushTipImageGridSize. If \c brushTipImageGridSize is not <tt>(1, 1)</tt>, the subimages are
/// chosen randomly.
///
/// @important If the \c sourceSamplingMode requires random subimage selection from the source, the
/// random subimage selection for the mask is synchronized. I.e., if subimage in row \c x and column
/// \c y is selected from the source image, the subimage with row \c x and column \c y is selected
/// from the mask as well.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c brushTipImageGridSize
/// \c sourceImageURL
@property (readonly, nonatomic) NSURL *maskImageURL;

#pragma mark -
#pragma mark Blending
#pragma mark -

/// Blend mode to be used to blend the rendered brush stroke geometry with the render target.
///
/// (Order) Dependencies:
/// Geometry
/// \c flow
/// \c color
/// \c brightnessJitter
/// \c hueJitter
/// \c saturationJitter
/// \c sourceImageURL
/// \c brushTipImageGridSize
/// \c maskImageURL
/// Render target
@property (readonly, nonatomic) DVNBlendMode *blendMode;

#pragma mark -
#pragma mark Edge Avoidance
#pragma mark -

/// Multiplicative factor, in range <tt>[0, 1]</tt>, for computing the edge avoidance of the brush.
/// The edge avoidance effect increases proportionally to this value. Ignored if
/// \c edgeAvoidanceGuideImageURL equals the empty string.
///
/// (Order) Dependencies:
/// \c edgeAvoidanceGuideImageURL
@property (readonly, nonatomic) CGFloat edgeAvoidance;

/// Allowed range of \c edgeAvoidance.
@property (class, readonly, nonatomic) lt::Interval<CGFloat> allowedEdgeAvoidanceRange;

/// URL associated with the image used as guide for the edge avoidance. Ignored if equalling the
/// empty string or \c edgeAvoidance is \c 0.
///
/// (Order) Dependencies:
/// \c edgeAvoidance
@property (readonly, nonatomic) NSURL *edgeAvoidanceGuideImageURL;

/// Offset, in inches, used for sampling the edge avoidance texture.
@property (readonly, nonatomic) CGFloat edgeAvoidanceSamplingOffset;

/// Allowed range of the x- and y-coordinate of \c edgeAvoidanceSamplingOffset.
@property (class, readonly, nonatomic) lt::Interval<CGFloat>
    allowedEdgeAvoidanceSamplingOffsetRange;

@end

NS_ASSUME_NONNULL_END

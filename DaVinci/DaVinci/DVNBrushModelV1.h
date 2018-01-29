// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModel.h"

NS_ASSUME_NONNULL_BEGIN

@class DVNBlendMode;

/// Brush model for constructing brush tip geometry (version 1).
@interface DVNBrushModelV1 : DVNBrushModel

#pragma mark -
#pragma mark Randomness
#pragma mark -

/// If \c YES, \c initialSeed is used as initial seed for the \c LTRandom used for computing all
/// random values required by this instance.
///
/// (Order) Dependencies: none
@property (readonly, nonatomic) BOOL randomInitialSeed;

/// Initial seed for the \c LTRandom used for computing all random values required by this instance.
/// Is used only if \c randomInitialSeed is YES.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
@property (readonly, nonatomic) NSUInteger initialSeed;

#pragma mark -
#pragma mark Brush Tip Pattern
#pragma mark -

/// Distance, in floating point pixel units of the brush stroke geometry coordinate system
/// multiplied by \c scale, between the centers of the brush tip geometry on the curve along which
/// the brush stroke is rendered. A value of \c 1 causes the brush tip squares to be adjacent on a
/// straight line axis-aligned in the brush stroke geometry coordinate system, for any value of
/// \c scale, while a value of \c 0 causes all squares to be on top of each other.
///
/// (Order) Dependencies:
/// \c scale
@property (readonly, nonatomic) CGFloat spacing;

/// Number of brush tip squares determining a single sequence of brush tips. The brush tip squares
/// inside a sequence is spaced according to \c spacing, while sequences themselves are spaced
/// according to \c sequenceDistance.
///
/// (Order) Dependencies: none
@property (readonly, nonatomic) NSUInteger numberOfSamplesPerSequence;

/// Distance, in floating point pixel units of the brush stroke geometry coordinate system
/// multiplied by \c scale, between the center of the last brush tip geometry of a sequence, as
/// defined by \c numberOfSamplesPerSequence, and the center of the first brush tip geometry of the
/// next sequence. A value of \c 1 causes the square brush tip geometry to be adjacent on a straight
/// line axis-aligned in the brush stroke geometry coordinate system, for any value of \c scale.
///
/// (Order) Dependencies:
/// \c scale
@property (readonly, nonatomic) CGFloat sequenceDistance;

#pragma mark -
#pragma mark Brush Tip Duplications
#pragma mark -

/// Minimum number of times each brush tip geometry is randomly duplicated, after creation according
/// to \c spacing, \c numberOfSamplesPerSequence, and \c sequenceDistance.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
@property (readonly, nonatomic) NSUInteger minCount;

/// Maximum number of times each brush tip geometry is randomly duplicated, after creation according
/// to \c spacing, \c numberOfSamplesPerSequence, and \c sequenceDistance.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
@property (readonly, nonatomic) NSUInteger maxCount;

#pragma mark -
#pragma mark Random Spatial Jittering, Rotation and Scaling of Brush Tip Geometry
#pragma mark -

/// Non-negative multiplicative factor for computing the minimum distance by which the brush tip
/// geometry is randomly translated. A value of \c x has the effect that the brush tip geometry is
/// translated by at least <tt>x * scale</tt>. In particular, a value of \c 0 has the effect that
/// the brush tip might not be translated at all.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c minCount
/// \c maxCount
@property (readonly, nonatomic) CGFloat minDistanceJitterFactor;

/// Non-negative multiplicative factor for computing the maximum distance by which the brush tip
/// geometry is randomly translated. A value of \c x has the effect that the brush tip is translated
/// by at most <tt>x * scale</tt>. In particular, a value of \c 0 has the effect that the brush tip
/// is not translated at all.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c minCount
/// \c maxCount
@property (readonly, nonatomic) CGFloat maxDistanceJitterFactor;

/// Minimum angle, in radians and in range <tt>[0, 2 * M_PI)</tt>, by which the brush tip geometry
/// is randomly rotated around its center. A value of \c x has the effect that the brush tip is
/// rotated by at least \c x radians. In particular, a value of \c 0 has the effect that the brush
/// tip might not be rotated at all.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c minCount
/// \c maxCount
@property (readonly, nonatomic) CGFloat minAngle;

/// Maximum angle, in radians and in range <tt>[0, 2 * M_PI)</tt>, by which the brush tip geometry
/// is randomly rotated around its center. A value of \c x has the effect that the brush tip is
/// rotated by at most \c x radians. In particular, a value of \c 0 has the effect that the brush
/// tip is not rotated at all.
///
/// (Order) Dependencies:
/// \c randomInitialSeed
/// \c initialSeed
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c minCount
/// \c maxCount
@property (readonly, nonatomic) CGFloat maxAngle;

/// Multiplicative factor, in range <tt>[0, 1]</tt>, for computing the minimum factor by which the
/// brush tip geometry is randomly scaled around its center. A value of \c 1 yields an unchanged
/// brush tip, while a value of \c 0 yields a non-existant brush tip.
///
/// (Order) Dependencies:
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c minCount
/// \c maxCount
@property (readonly, nonatomic) CGFloat minScaleJitter;

/// Multiplicative factor, in range <tt>[1, CGFLOAT_MAX]</tt>, for computing the maximum factor by
/// which the  brush tip geometry is randomly scaled around its center. A value of \c 1 yields an
/// unchanged brush tip, while a value of \c CGFLOAT_MAX yields an infinitely large brush tip.
///
/// (Order) Dependencies:
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c minCount
/// \c maxCount
@property (readonly, nonatomic) CGFloat maxScaleJitter;

#pragma mark -
#pragma mark Tapering
#pragma mark -

/// Length, in floating point pixel units of the brush stroke geometry coordinate system
/// multiplied by \c scale, of the tapering applied to the brush tip geometry at the beginning of
/// the brush stroke.
///
/// (Order) Dependencies:
/// \c scale
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c minCount
/// \c maxCount
/// \c minDistanceJitterFactor
/// \c maxDistanceJitterFactor
/// \c minAngle
/// \c maxAngle
/// \c minScaleJitter
/// \c maxScaleJitter
@property (readonly, nonatomic) CGFloat lengthOfStartTapering;

/// Length, in floating point pixel units of the brush stroke geometry coordinate system
/// multiplied by \c scale, of the tapering applied to the brush tip geometry at the end of the
/// brush stroke.
///
/// (Order) Dependencies:
/// \c scale
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c minCount
/// \c maxCount
/// \c minDistanceJitterFactor
/// \c maxDistanceJitterFactor
/// \c minAngle
/// \c maxAngle
/// \c minScaleJitter
/// \c maxScaleJitter
@property (readonly, nonatomic) CGFloat lengthOfEndTapering;

/// Multiplicative factor, in range <tt>[0, 1]</tt>, used for determining the effect of the tapering
/// on the first (/last) brush tip of the entire brush stroke geometry. A value of \c 0 results in
/// the very first (/last) brush tip geometry to be non-existant, while a value of \c 0.5 results in
/// the very first (/last) brush tip geometry having half the edge length of the geometry of the
/// last (/first) brush tip at the start (/end) part of the tapering (if \c minScaleJitter and
/// \c maxScaleJitter are both \c 1).
///
/// (Order) Dependencies:
/// \c scale
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c minCount
/// \c maxCount
/// \c minDistanceJitterFactor
/// \c maxDistanceJitterFactor
/// \c minAngle
/// \c maxAngle
/// \c minScaleJitter
/// \c maxScaleJitter
@property (readonly, nonatomic) CGFloat minimumTaperingScaleFactor;

/// Positive number for adjusting the growth behavior of the tapering along the brush stroke. In
/// particular, the value is used in the power term <tt>a^taperingExponent</tt>, where \c a is the
/// scale factor (in range <tt>[0, 1]</tt>) for the corresponding brush tip square computed
/// according to the other tapering parameters, in order to compute the final scale factor.
///
/// (Order) Dependencies:
/// \c scale
/// \c spacing
/// \c numberOfSamplesPerSequence
/// \c sequenceDistance
/// \c minCount
/// \c maxCount
/// \c minDistanceJitterFactor
/// \c maxDistanceJitterFactor
/// \c minAngle
/// \c maxAngle
/// \c minScaleJitter
/// \c maxScaleJitter
@property (readonly, nonatomic) CGFloat taperingExponent;

#pragma mark -
#pragma mark Flow
#pragma mark -

/// Multiplicative factor, in range <tt>[\c minFlow, \c maxFlow]</tt>, used as base value for
/// computing the brush flow.
///
/// (Order) Dependencies:
/// \c minFlow
/// \c maxFlow
@property (readonly, nonatomic) CGFloat flow;

/// Minimum brush tip flow, in range <tt>[0, 1]</tt>. Refer to documentation of \c flow property for
/// more details.
@property (readonly, nonatomic) CGFloat minFlow;

/// Maximum brush tip flow, in range <tt>[minFlow, 1]</tt>.  Refer to documentation of \c flow
/// property for more details.
@property (readonly, nonatomic) CGFloat maxFlow;

/// Positive number for computing the final value used as brush flow. In particular, the final flow
/// value is given by <tt>flow^flowExponent</tt>.
///
/// (Order) Dependencies:
/// \c flow
@property (readonly, nonatomic) CGFloat flowExponent;

#pragma mark -
#pragma mark Colors
#pragma mark -

/// Color to be used as base tint of the brush tip.
///
/// (Order) Dependencies: none
@property (readonly, nonatomic) LTVector3 color;

/// Multiplicative factor, in range <tt>[0, 1]</tt>, for computing the range of values from which
/// the brightness of the brush tip is randomly chosen. In particular, the aforementioned range is
/// computed by chosing a random number from the uniform distribution with support
/// <tt>[0, brightnessJitter]</tt>, denoted \c offset, then chosing a random number from the uniform
/// distribution with support <tt>[brightness - offset, brightness + offset]</tt>, and finally
/// clamping the value to <tt>[0, 1]</tt>. A value of \c 0 yields an unchanged brush tip brightness,
/// while a value of \c 1 yields allows for arbitrary brightness changes.
///
/// (Order) Dependencies:
/// \c color
@property (readonly, nonatomic) CGFloat brightnessJitter;

/// Multiplicative factor, in range <tt>[0, 1]</tt>, for computing the range of values from which
/// the hue of the brush tip is randomly chosen. In particular, the aforementioned range is computed
/// by chosing a random number from the uniform distribution with support <tt>[0, hueJitter]</tt>,
/// denoted \c offset, then chosing a random number from the uniform distribution with support
/// <tt>[hue - offset, hue + offset]</tt>, and finally clamping the value to <tt>[0, 1]</tt>. A
/// value of \c 0 yields an unchanged brush tip hue, while a value of \c 1 yields allows for
/// arbitrary hue changes.
///
/// (Order) Dependencies:
/// \c color
@property (readonly, nonatomic) CGFloat hueJitter;

/// Multiplicative factor, in range <tt>[0, 1]</tt>, for computing the range of values from which
/// the saturation of the brush tip is randomly chosen. In particular, the aforementioned range is
/// computed by chosing a random number from the uniform distribution with support
/// <tt>[0, saturationJitter]</tt>, denoted \c offset, then chosing a random number from the uniform
/// distribution with support <tt>[saturation - offset, saturation + offset]</tt>, and finally
/// clamping the value to <tt>[0, 1]</tt>. A value of \c 0 yields an unchanged brush tip saturation,
/// while a value of \c 1 yields allows for arbitrary saturation changes.
///
/// (Order) Dependencies:
/// \c color
@property (readonly, nonatomic) CGFloat saturationJitter;

#pragma mark -
#pragma mark Texture Mapping
#pragma mark -

/// URL to the image mapped onto the brush tip geometry during brush stroke rendering, possibly
/// affected by previously computed tonal values.
///
/// (Order) Dependencies:
/// \c flow
/// \c color
/// \c brightnessJitter
/// \c hueJitter
/// \c saturationJitter
@property (readonly, nonatomic) NSURL *brushTipImageURL;

/// Vector whose \c x and \c y value define the number of columns and rows, respectively, of the
/// regular grid dividing the image defined by \c brushTipImageURL into the subimages randomly
/// mapped onto the brush tip squares during brush stroke rendering.
///
/// (Order) Dependencies:
/// \c brushTipImageURL
@property (readonly, nonatomic) LTVector2 brushTipImageGridSize;

/// Name of the overlay image mapped onto the brush tip geometry during brush stroke rendering.
///
/// (Order) Dependencies:
/// \c flow
/// \c color
/// \c brightnessJitter
/// \c hueJitter
/// \c saturationJitter
@property (readonly, nonatomic) NSURL *overlayImageURL;

#pragma mark -
#pragma mark Edge Avoidance
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
/// \c brushTipImageURL
/// \c brushTipImageGridSize
/// \c overlayImageURL
/// Render target
@property (readonly, nonatomic) DVNBlendMode *blendMode;

#pragma mark -
#pragma mark Edge Avoidance
#pragma mark -

/// Multiplicative factor, in range <tt>[0, 1]</tt>, for computing the edge avoidance of the brush.
/// The edge avoidance effect increases proportionally to this value.
@property (readonly, nonatomic) CGFloat edgeAvoidance;

/// Offset, in normalized floating-point units of the coordinate system of each brush tip geometry,
/// used for sampling the edge avoidance texture.
@property (readonly, nonatomic) CGFloat edgeAvoidanceSamplingOffset;

@end

NS_ASSUME_NONNULL_END

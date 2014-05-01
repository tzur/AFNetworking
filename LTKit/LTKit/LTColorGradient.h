// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

@class LTTexture;

/// Color gradient control point is a mapping of a single point in the intensity domain to color.
@interface LTColorGradientControlPoint : NSObject

/// Initializes color gradient control point with position and color.
///
/// @param position position of the control point. Should be in [0-1] range.
/// @param color color of the control point with alpha component.
- (instancetype)initWithPosition:(CGFloat)position colorWithAlpha:(GLKVector4)color;

/// Initializes color gradient control point with position and color.
///
/// @param position position of the control point. Should be in [0-1] range.
/// @param color color of the control point without alpha component. Alpha is set to 1 in this case.
- (instancetype)initWithPosition:(CGFloat)position color:(GLKVector3)color;

/// Convenience class method that creates a color gradient control point with position and opaque
/// color.
+ (LTColorGradientControlPoint *)controlPointWithPosition:(CGFloat)position color:(GLKVector3)color;

/// Convenience class method that creates a color gradient control point with position and color
/// with alpha.
+ (LTColorGradientControlPoint *)controlPointWithPosition:(CGFloat)position
                                           colorWithAlpha:(GLKVector4)color;

/// Position of the point.
@property (readonly, nonatomic) CGFloat position;

/// Color of the point.
@property (readonly, nonatomic) GLKVector4 color;

@end

/// Color gradient is a smooth mapping of intensity to color.
/// The mapping is constructed by a linear interpolation (and extrapolation) of the control points.
@interface LTColorGradient : NSObject

/// Initializes the color gradient with an array of LTColorGradientControlPoints.
///
/// @param controlPoints control points that define intensity-to-color mapping. Should include at
/// least two control points. Positions should be monotonically @a increasing.
- (instancetype)initWithControlPoints:(NSArray *)controlPoints;

/// Discretize [0-1] range, sample gradient values and write these values to texture.
///
/// @param numberOfPoints is a number of points to sample the gradient with.
/// Number of sampling points should be at least two. First point samples at 0.0, last one at 1.0.
/// Using low number of sampling points can result in an inadequate representation of the gradient.
///
/// @return texture that holds the sampled values.
/// Size of the texture is [numberOfPoints x 1 x 3]
- (LTTexture *)textureWithSamplingPoints:(NSUInteger)numberOfPoints;

/// Creates an instance of LTColorGradient that represents a linear gradient. Linear gradient can be
/// thought of as an identity mapping between the position and the range value: y = x across the
/// color channels.
///
/// @return color gradient that represents an identity manipulation.
+ (LTColorGradient *)identityGradient;

@end

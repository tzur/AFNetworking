// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTTexture.h"

/// @class
///
/// Color gradient control point is a mapping of a single point in the intensity domain to color.
@interface LTColorGradientControlPoint : NSObject

- (id)initWithPosition:(CGFloat)position color:(GLKVector3)color;

// Position on the point.
@property (readonly, nonatomic) CGFloat position;
// Color of the point.
@property (readonly, nonatomic) GLKVector3 color;

@end

/// @class
///
/// Color gradient is a smooth mapping of intensity to color.
/// The mapping is constructed by a linear inerpolation (and extrapolation) of the control points.
@interface LTColorGradient : NSObject

/// Initializes the color gradient with a set of control points.
///
/// @param controlPoints control points that define intensity-to-color mapping. Should include at
/// least two control points. Positions should be monotonically @a increasing.
- (id)initWithControlPoints:(NSArray *)controlPoints;

/// Discretize [0-1] range, sample gradient values and write them these values to texture.
///
/// @param number number of points to sample the gradient. Number of sampling points should be at
/// least two. First point samples at 0.0, last one at 1.0. Using low number of sampling points can
/// result in an inadequate representation of the gradient.
///
/// @return texture that holds the sampled values.
- (LTTexture *)toTexure:(NSUInteger)number;

@end

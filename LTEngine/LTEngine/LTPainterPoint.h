// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTInterpolatableObject.h"

/// This class represents a point used in the \c LTPainter mechanism, with interpolated properties.
@interface LTPainterPoint : NSObject <LTInterpolatableObject, NSCopying>

/// initializes a point with the default primitive values and the current timestamp.
- (instancetype)initWithCurrentTimestamp;

/// Designated initializer: create a point with the default primitive values for its properties.
- (instancetype)init;

/// Timestamp of the point, clamped to range [0,Inf).
@property (nonatomic) CFTimeInterval timestamp;

/// Position of the point, in screen coordinates.
@property (nonatomic) CGPoint screenPosition;

/// Position of the point, in content coordinates.
@property (nonatomic) CGPoint contentPosition;

/// Zoom scale of the view at the time the point is taken, clamped to range [0,Inf), Default is
/// \c 1.
@property (nonatomic) CGFloat zoomScale;

/// Radius (in points) of the touch, in screen coordinates. Default is \c 1.
///
/// @see Relevant properties (\c touchRadius, \c majorRadiusTolerance) of \c UITouch.
@property (nonatomic) CGFloat touchRadius;

/// Tolerance (in points) of the touch’s radius, in screen coordinates. Default is \c 1.
/// This value determines the accuracy of the value in the touchRadius property. Add this value to
/// the radius to get the maximum touch radius. Subtract the value to get the minimum touch radius.
///
/// @see Relevant properties (\c touchRadius, \c majorRadiusTolerance) of \c UITouch.
@property (nonatomic) CGFloat touchRadiusTolerance;

/// Distance of the point from the start of the stroke it belongs to. Clamped to range [0,Inf).
@property (nonatomic) CGFloat distanceFromStart;

/// Diameter of the point in pixels, clamped to range [0,Inf).
@property (nonatomic) CGFloat diameter;

@end

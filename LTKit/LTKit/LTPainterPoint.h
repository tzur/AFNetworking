// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTInterpolatedObject.h"

/// This class represents a point used in the \c LTPainter mechanism, with interpolated properties.
@interface LTPainterPoint : NSObject <LTInterpolatedObject>

/// initializes a point with the default primitive values and the current timestamp.
-(instancetype)initWithCurrentTimestamp;

/// Designated initializer: create a point with the default primitive values for its properties.
- (instancetype)init;

/// Timestamp of the point, clamped to range [0,Inf).
@property (nonatomic) CFTimeInterval timestamp;

/// Position of the point, in screen coordinates.
@property (nonatomic) CGPoint screenPosition;

/// Position of the point, in content coordinates.
@property (nonatomic) CGPoint contentPosition;

/// Zoom scale of the view at the time the point is taken, clamped to range [0,Inf).
@property (nonatomic) CGFloat zoomScale;

/// Distance of the point from the start of the stroke it belongs to. Clamped to range [0,Inf).
@property (nonatomic) CGFloat distanceFromStart;

/// Diameter of the point in pixels, clamped to range [0,Inf).
@property (nonatomic) CGFloat diameter;

@end

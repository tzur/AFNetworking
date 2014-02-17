// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTInterpolatedObject.h"

/// This class represents a point used in the \c LTPainter mechaism, with interpolated properties.
@interface LTPainterPoint : NSObject <LTInterpolatedObject>

/// Initializes the point with the given position, zoom scale, and the current timestamp.
- (instancetype)initWithScreenPosition:(CGPoint)screenPosition
                       contentPosition:(CGPoint)contentPosition
                           atZoomScale:(CGFloat)zoomScale;

/// Initializes the point with the given position, zoom scale, and timestamp.
- (instancetype)initWithScreenPosition:(CGPoint)screenPosition
                       contentPosition:(CGPoint)contentPosition
                           atZoomScale:(CGFloat)zoomScale
                         withTimestamp:(CFTimeInterval)timestamp;

/// Designated initializer: create an uninitialized point.
- (instancetype)init;

/// Timestamp of the point.
@property (nonatomic) CFTimeInterval timestamp;

/// The position of the point, in screen coordinates.
@property (nonatomic) CGPoint screenPosition;

/// The position of the point, in content coordinates.
@property (nonatomic) CGPoint contentPosition;

/// The zoom scale of the view at the time the point is taken.
@property (nonatomic) CGFloat zoomScale;

/// Distance of the point from the start of the stroke it belongs to.
@property (nonatomic) CGFloat distanceFromStart;

/// Diameter of the point, in pixels.
@property (nonatomic) CGFloat diameter;

@end

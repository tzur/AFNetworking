// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@class LTPainterStrokeSegment, LTPainterPoint;
@protocol LTInterpolationRoutineFactory;

/// This class represents a painter stroke, used in the \c LTPainter mechanism.
/// The main purpose of this class is to generate interpolated points on the segment.
@interface LTPainterStroke : NSObject

- (instancetype)initWithInterpolationRoutineFactory:(id<LTInterpolationRoutineFactory>)factory
                                      startingPoint:(LTPainterPoint *)startingPoint;

/// Adds and returns a new segment from the last point to the given point.
- (LTPainterStrokeSegment *)addSegmentTo:(LTPainterPoint *)point;

/// Adds an unconnected point at the end of the stroke.
- (void)addPointAt:(LTPainterPoint *)point;

/// Starting point of the stroke.
@property (readonly, nonatomic) LTPainterPoint *startingPoint;

/// Array of either \c LTPainterStrokeSegment, or \c LTPainterPoint consisting the stroke.
/// segment instances mark a segment connected from the previous point (or segment end) while point
/// instances mark a point not connected to its predecessor.
@property (readonly, nonatomic) NSArray *segments;

@end

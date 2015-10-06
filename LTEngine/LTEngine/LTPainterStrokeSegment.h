// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@class LTInterpolationRoutine, LTPainterPoint;

/// This class represents a segment of a painter stroke, used in the \c LTPainter mechanism.
/// The main purpose of this class is to generate interpolated points on the segment.
@interface LTPainterStrokeSegment : NSObject

/// Initializes the segment.
///
/// @param index index of the segment on the stroke it belongs to.
/// @param distanceFromStart distance of the segment start from the stroke's starting point.
/// @param interpolationRoutine the interpolation routine used to generate points on along the
/// segment.
- (instancetype)initWithSegmentIndex:(NSUInteger)index
                   distanceFromStart:(CGFloat)distance
             andInterpolationRoutine:(LTInterpolationRoutine *)routine;

/// Returns a list of points on the segment.
- (NSArray *)pointsWithInterval:(CGFloat)distance startingAtOffset:(CGFloat)offset;

/// Index of the segment in the stroke.
@property (readonly, nonatomic) NSUInteger index;

/// Distance (in pixels) of the segment's starting point from the stroke's starting point.
@property (readonly, nonatomic) CGFloat distanceFromStart;

/// Approximated length of the segment.
@property (readonly, nonatomic) CGFloat length;

/// Starting point of the segment.
@property (readonly, nonatomic) LTPainterPoint *startPoint;

@end

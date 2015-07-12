// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTSingleBrushPaintingStrategy.h"

#import "LTPropertyMacros.h"

/// POD for holding a single airbrush point used to generate painting directions by the
/// \c LTSingleAirbrushPaintingStrategy.
typedef struct {
  CGPoint position;
  CGPoint normalizedPosition;
  CGFloat scaleFactor;
} LTSingleAirbrushPoint;

typedef std::vector<LTSingleAirbrushPoint> LTSingleAirbrushPoints;

/// Protocol used for processing the array of ordered points that needs to be drawn during a full
/// processing cycle. This allows composition-based implementations that manipulate or update the
/// points after they are generated. For example, a sparse strategy can discard specific points
/// according to various conditions.
@protocol LTSingleAirbrushPaintingStrategyPointsTransformer <NSObject>

/// Returns an array of processed points from the given input array of ordered points. Processing
/// can be creating additional points, updating existing points, or removing points.
/// This method will be called whenever the \c points property of the
/// \c LTSingleAirbrushPaintingStrategy instance is set.
- (LTSingleAirbrushPoints)transformedPoints:(const LTSingleAirbrushPoints &)points;

@end

/// Protocol for defining a strategy for painting, one point at a time. A key attribute of this
/// type of painting is that the array of \c LTPainterPoints to be drawn is generated prior to
/// painting (for example, in the \c paintingWillBeginWithPainter: method).
/// The \c pointsTransformer, if set, should be applied on the points generated.
@protocol LTSingleAirbrushPaintingStrategy <LTPaintingStrategy>

/// When set, this should be used to postprocess the array of points after generating it.
@property (weak, nonatomic) id<LTSingleAirbrushPaintingStrategyPointsTransformer> pointsTransformer;

@end

/// Basic class defining a strategy for painting, one point at a time, using a single \c LTBrush
/// on an \c LTPaintingImageProcessor. This class implements the \c paintingWillBeginWithPainter:
/// method by generating an evenly spread points on the canvas, according to its \c fillFactor and
/// \c fillRandomness properties. Once these points are generated prior to painting, the painting
/// directions generate a single stroke with the points corresponding to the target progress
/// interval.
///
/// @see LTPaintingStrategy
@interface LTSingleAirbrushPaintingStrategy : LTSingleBrushPaintingStrategy
    <LTSingleAirbrushPaintingStrategy>

/// Controls the density of the filling. Small values mean sparser painting, and higher values mean
/// denser painting. Must be in range [0.1,10], default is 1.
@property (nonatomic) CGFloat fillFactor;
LTPropertyDeclare(CGFloat, fillFactor, FillFactor);

/// Controls the scattering randomness of the generated points. \c 0 indicates no randomness, such
/// that the points are generated on a grid with fixed distances between them. \c 1 indicates the
/// maximum randomness such that every point can fall anywhere on square determined by the brush
/// radius. Must be in range [0,1], default is 1.
@property (nonatomic) CGFloat fillRandomness;
LTPropertyDeclare(CGFloat, fillRandomness, FillRandomness);

@end

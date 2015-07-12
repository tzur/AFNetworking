// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@class LTBrush, LTPainter, LTPainterPoint, LTPainterStroke;

/// Container class for holding a pair of \c LTBrush and \c LTPainterStroke, used as painting
/// directions by the \c LTPaintingStrategy protocol.
@interface LTPaintingDirections : NSObject

/// Creates an \c LTPaintingDirections object with the given brush and stroke (both must not be
/// \c nil).
+ (LTPaintingDirections *)directionsWithBrush:(LTBrush *)brush stroke:(LTPainterStroke *)stroke;

/// Creates an \c LTPaintingDirections object with the given brush, and a linearly interpolated
/// stroke starting at the given point (both must not be nil).
+ (LTPaintingDirections *)directionsWithBrush:(LTBrush *)brush
                       linearStrokeStartingAt:(LTPainterPoint *)point;

/// Brush to use for painting the corresponding stroke.
@property (readonly, nonatomic) LTBrush *brush;

/// Stroke to paint.
@property (readonly, nonatomic) LTPainterStroke *stroke;

@end

/// Protocol for defining a strategy for painting using an \c LTPaintingImageProcessor. The strategy
/// provides directions for painting in a given progress interval, and prepares the painter for
/// painting.
@protocol LTPaintingStrategy <NSObject>

/// Notifies that a painting is about to begin, allowing the strategy to do some preprocessing with
/// respect to the configuration of the painter to be used.
- (void)paintingWillBeginWithPainter:(LTPainter *)painter;

/// Returns an array of \c LTPaintingDirections objects indicating the strokes that should be
/// painted for the given progress interval, and the brush that should be used for each stroke.
- (NSArray *)paintingDirectionsForStartingProgress:(double)startingProgress
                                    endingProgress:(double)endingProgress;

@end

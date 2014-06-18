// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTSingleAirbrushPaintingStrategy.h"

#import "LTBrush.h"
#import "LTCGExtensions.h"
#import "LTLinearInterpolationRoutine.h"
#import "LTPainter.h"
#import "LTPainterPoint.h"
#import "LTPainterStroke.h"
#import "LTTexture.h"

@interface LTSingleAirbrushPaintingStrategy ()

/// Array of \c LTPainterPoints representing all the points (ordered) that needs to be drawn during
/// a full processing cycle.
///
/// @note subclasses are responsible for generating this array prior to painting, for example, when
/// the \c paintingWillBegin: method is called.
@property (strong, nonatomic) NSArray *points;

@end

@implementation LTSingleAirbrushPaintingStrategy

@synthesize pointsTransformer;

#pragma mark -
#pragma mark LTPaintingStrategy
#pragma mark -

- (void)paintingWillBeginWithPainter:(LTPainter *)painter {
  LTSingleAirbrushPoints points = [self generatePointsForCanvasSize:painter.canvasTexture.size];
  if (self.pointsTransformer) {
    points = [self.pointsTransformer transformedPoints:points];
  }
  self.points = [self painterPointsFromSingleAirbrushPoints:points];
}

- (LTSingleAirbrushPoints)generatePointsForCanvasSize:(CGSize)size {
  // TODO:(amit) replace with LTRandom when available.
  srand48(arc4random());
  CGFloat diameter = self.brush.baseDiameter * self.brush.scale / self.fillFactor;
  CGFloat radius = diameter / 2;
  CGFloat maxOffset = self.fillRandomness * radius;
  LTSingleAirbrushPoints points;
  for (NSUInteger row = 0; row <= size.height / diameter; ++row) {
    for (NSUInteger col = 0; col <= size.width / diameter; ++col) {
      CGPoint position = CGPointMake(col * diameter + radius, row * diameter + radius);
      position.x += (2 * drand48() - 1) * maxOffset;
      position.y += (2 * drand48() - 1) * maxOffset;
      points.push_back({.position = position,
        .normalizedPosition = position / size,
        .scaleFactor = 1});
    }
  }
  return points;
}

- (NSArray *)painterPointsFromSingleAirbrushPoints:(const LTSingleAirbrushPoints &)points {
  NSMutableArray *painterPoints = [NSMutableArray array];
  for (const auto &point : points) {
    [painterPoints addObject:[self painterPointWithSingleAirbrushPoint:point]];
  }
  return painterPoints;
}

- (LTPainterPoint *)painterPointWithSingleAirbrushPoint:(const LTSingleAirbrushPoint &)point {
  LTPainterPoint *painterPoint = [[LTPainterPoint alloc] init];
  painterPoint.zoomScale = point.scaleFactor ? (1.0 / point.scaleFactor) : INFINITY;
  painterPoint.contentPosition = point.position;
  return painterPoint;
}

- (NSArray *)paintingDirectionsForStartingProgress:(double)startingProgress
                                    endingProgress:(double)endingProgress {
  LTParameterAssert(startingProgress >= 0);
  LTParameterAssert(endingProgress <= 1);
  LTParameterAssert(startingProgress <= endingProgress);
  
  NSUInteger startIdx = std::ceil(startingProgress * (self.points.count - 1));
  NSUInteger endIdx = std::floor(endingProgress * (self.points.count - 1));
  if (startIdx > endIdx) {
    return @[];
  }
  
  LTPaintingDirections *directions =
      [LTPaintingDirections directionsWithBrush:self.brush
                         linearStrokeStartingAt:self.points[startIdx]];
  for (NSUInteger i = startIdx; i <= endIdx; ++i) {
    [directions.stroke addPointAt:self.points[i]];
  }
  return @[directions];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTProperty(CGFloat, fillFactor, FillFactor, 0.1, 10, 1);
LTProperty(CGFloat, fillRandomness, FillRandomness, 0, 1, 1);

@end

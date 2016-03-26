// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainter+LTView.h"

#import "LTBrush.h"
#import "LTFbo.h"
#import "LTMathUtils.h"
#import "LTPainterPoint.h"
#import "LTPainterStroke.h"
#import "LTPainterStrokeSegment.h"
#import "LTRectDrawer.h"
#import "LTSlidingWindowFilter.h"
#import "LTTouchCollector.h"
#import "LTTouchCollectorDistanceFilter.h"
#import "LTTouchCollectorFilter.h"
#import "LTTouchCollectorTimeIntervalFilter.h"

#pragma mark -
#pragma mark LTPainter+LTView
#pragma mark -

@interface LTPainter ()

@property (strong, nonatomic) LTFbo *canvasFbo;
@property (strong, nonatomic) LTFbo *strokeFbo;
@property (strong, nonatomic) LTRectDrawer *strokeDrawer;
@property (strong, nonatomic) NSMutableArray *mutableStrokes;

- (LTFbo *)fboForPainting;
- (void)mergeStrokeCanvasWithPainterCanvasIfNecessary;

#pragma mark -
#pragma mark Category Properties
#pragma mark -

/// Touch collector used for receiving touch events from an \c LTView.
@property (readonly, nonatomic) LTTouchCollector *touchCollector;

/// Currently active stroke.
@property (strong, nonatomic) LTPainterStroke *currentStroke;

/// Last point that was actually painted (not necessarily the ending point of the last segment).
@property (strong, nonatomic) LTPainterPoint *lastDrawnPoint;

/// Used for generating smoother transitions of the touch radiuses during a stroke.
@property (strong, nonatomic) LTSlidingWindowFilter *touchRadiusFilter;

@end

@implementation LTPainter (LTView)

#pragma mark -
#pragma mark LTTouchCollectorDelegate
#pragma mark -

- (void)ltTouchCollector:(LTTouchCollector __unused *)touchCollector
         startedStrokeAt:(LTPainterPoint *)touch {
  LTAssert(!self.currentStroke, @"started a stroke, but stroke is already in progress");
  LTPainterPoint *point = [self pointForTargetCoordinateSystem:touch];
  [self startStrokeAt:point];
}

- (void)ltTouchCollector:(LTTouchCollector __unused *)touchCollector
    collectedStrokeTouch:(LTPainterPoint *)touch {
  LTAssert(self.currentStroke, @"collected stroke touch, but no stroke in progress");
  LTPainterPoint *point = [self pointForTargetCoordinateSystem:touch];
  LTPainterStrokeSegment *segment = [self.currentStroke addSegmentTo:point];
  if (segment) {
    LTPainterPoint *lastDrawnPoint;
    NSArray *paintedRects = [self.brush drawStrokeSegment:segment
                                        fromPreviousPoint:self.lastDrawnPoint
                                            inFramebuffer:self.fboForPainting
                                     saveLastDrawnPointTo:&lastDrawnPoint];
    self.lastDrawnPoint = lastDrawnPoint ?: self.lastDrawnPoint;
    if (paintedRects.count) {
      [self.delegate ltPainter:self didPaintInRotatedRects:paintedRects];
    }
  }
}

- (void)ltTouchCollector:(LTTouchCollector __unused *)touchCollector
     collectedTimerTouch:(LTPainterPoint *)touch {
  LTAssert(self.currentStroke, @"collected timer touch, but no stroke in progress");
  if (!self.airbrush) {
    return;
  }

  LTPainterPoint *point = [self pointForTargetCoordinateSystem:touch];
  point.distanceFromStart = self.lastDrawnPoint.distanceFromStart +
      CGPointDistance(point.contentPosition, self.lastDrawnPoint.contentPosition);
  [self drawSinglePoint:point];
}

- (void)drawSinglePoint:(LTPainterPoint *)point {
  [self.currentStroke addPointAt:point];
  NSArray *paintedRects = [self.brush drawPoint:point inFramebuffer:self.fboForPainting];
  self.lastDrawnPoint = point;
  [self.delegate ltPainter:self didPaintInRotatedRects:paintedRects];
}

- (void)ltTouchCollectorFinishedStroke:(LTTouchCollector __unused *)touchCollector
                             cancelled:(BOOL)cancelled {
  LTAssert(self.currentStroke, @"finished a stroke, but no stroke in progress");

  // Identify a tap gesture and draw a point for it.
  if (!cancelled && !self.lastDrawnPoint) {
    [self drawSinglePoint:self.currentStroke.startingPoint];
  }
  [self endStroke];
}

/// Returns a copy of the given point, after applying the alternative coordinate system transform
/// (if available) on its contentPosition, and replacing its zoomScale (if available).
- (LTPainterPoint *)pointForTargetCoordinateSystem:(LTPainterPoint *)point {
  LTPainterPoint *newPoint = [point copy];
  if ([self.delegate respondsToSelector:@selector(alternativeCoordinateSystemTransform)]) {
    newPoint.contentPosition =
    CGPointApplyAffineTransform(newPoint.contentPosition,
                                [self.delegate alternativeCoordinateSystemTransform]);
  }
  if ([self.delegate respondsToSelector:@selector(alternativeZoomScale)]) {
    newPoint.zoomScale = [self.delegate alternativeZoomScale];
  }

  [self createTouchRadiusFilterIfNeeded];
  newPoint.touchRadius = [self.touchRadiusFilter pushValueAndFilter:point.touchRadius];
  return newPoint;
}

static const NSUInteger kTouchRadiusFilterWindowSize = 11;
static const CGFloat kTouchRadiusFilterSigma = 5;

- (void)createTouchRadiusFilterIfNeeded {
  if (!self.touchRadiusFilter) {
    CGFloats kernel = LTCreateHalfGaussian(kTouchRadiusFilterWindowSize - 1,
                                           kTouchRadiusFilterSigma);
    self.touchRadiusFilter = [[LTSlidingWindowFilter alloc] initWithKernel:kernel];
  }
}

#pragma mark -
#pragma mark Painting
#pragma mark -

- (void)startStrokeAt:(LTPainterPoint *)point {
  if ([self.delegate respondsToSelector:@selector(ltPainterWillBeginStroke:)]) {
    [self.delegate ltPainterWillBeginStroke:self];
  }

  self.currentStroke =
      [[LTPainterStroke alloc]
       initWithInterpolantFactory:self.brush.splineFactory ?: self.splineFactory
       startingPoint:point];
  [self.brush startNewStrokeAtPoint:point];
}

- (void)endStroke {
  [self.mutableStrokes addObject:self.currentStroke];
  [self.touchRadiusFilter clear];
  self.lastDrawnPoint = nil;
  self.currentStroke = nil;
  [self mergeStrokeCanvasWithPainterCanvasIfNecessary];
  if ([self.delegate respondsToSelector:@selector(ltPainter:didFinishStroke:)]) {
    [self.delegate ltPainter:self didFinishStroke:self.mutableStrokes.lastObject];
  }
}

#pragma mark -
#pragma mark Category Properties
#pragma mark -

LTCategoryProperty(LTPainterPoint *, lastDrawnPoint, LastDrawnPoint);
LTCategoryProperty(LTPainterStroke *, currentStroke, CurrentStroke);
LTCategoryProperty(LTTouchCollector *, touchCollector, TouchCollector);
LTCategoryProperty(LTSlidingWindowFilter *, touchRadiusFilter, TouchRadiusFilter);
LTCategoryWeakProperty(LTTouchCollector *, delegate, Delegate);

- (id<LTViewTouchDelegate>)touchDelegateForLTView {
  if (!self.touchCollector) {
    self.touchCollector = [self createTouchCollector];
  }

  return self.touchCollector;
}

- (LTTouchCollector *)createTouchCollector {
  LTTouchCollector *collector = [[LTTouchCollector alloc] init];
  collector.delegate = self;
  collector.filter = [self createDefaultTouchCollectorFilter];
  return collector;
}

static const CGFloat kMinimalScreenDistanceForDefaultFilter = 5;
static const CGFloat kMinimalTimeIntervalForDefaultFilter = 0.3;

- (id<LTTouchCollectorFilter>)createDefaultTouchCollectorFilter {
  return [[LTTouchCollectorOrFilter alloc] initWithFilters:@[
              [LTTouchCollectorTimeIntervalFilter
                  filterWithMinimalTimeInterval:kMinimalTimeIntervalForDefaultFilter],
              [LTTouchCollectorDistanceFilter
                  filterWithMinimalScreenDistance:kMinimalScreenDistanceForDefaultFilter]]];
}

@end

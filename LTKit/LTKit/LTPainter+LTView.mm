// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainter+LTView.h"

#import "LTBrush.h"
#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTPainterPoint.h"
#import "LTPainterStroke.h"
#import "LTPainterStrokeSegment.h"
#import "LTRectDrawer.h"
#import "LTTouchCollector.h"
#import "LTTouchCollectorDistanceFilter.h"
#import "LTTouchCollectorFilter.h"
#import "LTTouchCollectorTimeIntervalFilter.h"

#pragma mark -
#pragma mark Protected Properties
#pragma mark -

@interface LTPainter ()

@property (strong, nonatomic) LTFbo *canvasFbo;
@property (strong, nonatomic) LTFbo *strokeFbo;
@property (strong, nonatomic) LTRectDrawer *strokeDrawer;
@property (strong, nonatomic) NSMutableArray *mutableStrokes;

- (LTFbo *)fboForPainting;
- (void)mergeStrokeCanvasWithPainterCanvasIfNecessary;

@end

#pragma mark -
#pragma mark Category Properties
#pragma mark -

@interface LTPainter ()

/// Touch collector used for receiving touch events from an \c LTView.
@property (readonly, nonatomic) LTTouchCollector *touchCollector;

/// Currently active stroke.
@property (strong, nonatomic) LTPainterStroke *currentStroke;

/// Last point that was actually painted (not necessarily the ending point of the last segment).
@property (strong, nonatomic) LTPainterPoint *lastDrawnPoint;

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
  LTPainterPoint *point = [self pointForTargetCoordinateSystem:touch];
  if (!self.airbrush) {
    return;
  }
  
  point.distanceFromStart = self.lastDrawnPoint.distanceFromStart +
  CGPointDistance(point.contentPosition, self.lastDrawnPoint.contentPosition);
  
  [self.currentStroke addPointAt:point];
  LTRotatedRect *paintedRect = [self.brush drawPoint:point inFramebuffer:self.fboForPainting];
  self.lastDrawnPoint = point;
  [self.delegate ltPainter:self didPaintInRotatedRects:@[paintedRect]];
}

- (void)ltTouchCollectorFinishedStroke:(LTTouchCollector __unused *)touchCollector
                             cancelled:(BOOL)cancelled {
  LTAssert(self.currentStroke, @"finished a stroke, but no stroke in progress");
  // Identify a tap gesture and draw a point for it.
  if (!cancelled && !self.lastDrawnPoint) {
    LTRotatedRect *paintedRect = [self.brush drawPoint:self.currentStroke.startingPoint
                                         inFramebuffer:self.fboForPainting];
    [self.delegate ltPainter:self didPaintInRotatedRects:@[paintedRect]];
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
  return newPoint;
}

#pragma mark -
#pragma mark Painting
#pragma mark -

- (void)startStrokeAt:(LTPainterPoint *)point {
  self.currentStroke = [[LTPainterStroke alloc]
                        initWithInterpolationRoutineFactory:self.splineFactory
                        startingPoint:point];
  [self.brush startNewStrokeAtPoint:point];
}

- (void)endStroke {
  [self.mutableStrokes addObject:self.currentStroke];
  self.lastDrawnPoint = nil;
  self.currentStroke = nil;
  [self mergeStrokeCanvasWithPainterCanvasIfNecessary];
  if ([self.delegate respondsToSelector:@selector(ltPainter:didFinishStroke:)]) {
    [self.delegate ltPainter:self didFinishStroke:self.mutableStrokes.lastObject];
  }
}

#pragma mark -
#pragma mark - Category Properties
#pragma mark -

static const void *_delegateKey = &_delegateKey;
static const void *_currentStrokeKey = &_currentStrokeKey;
static const void *_lastDrawnPointKey = &_lastDrawnPointKey;
static const void *_kTouchCollectorKey = &_kTouchCollectorKey;

- (id<LTPainterDelegate>)delegate {
  return objc_getAssociatedObject(self, _delegateKey);
}

- (void)setDelegate:(id<LTPainterDelegate>)delegate {
  objc_setAssociatedObject(self, _delegateKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (LTPainterPoint *)lastDrawnPoint {
  return objc_getAssociatedObject(self, _lastDrawnPointKey);
}

- (void)setLastDrawnPoint:(LTPainterPoint *)lastDrawnPoint {
  objc_setAssociatedObject(self, _lastDrawnPointKey, lastDrawnPoint,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (LTPainterStroke *)currentStroke {
  return objc_getAssociatedObject(self, _currentStrokeKey);
}

- (void)setCurrentStroke:(LTPainterStroke *)currentStroke {
  objc_setAssociatedObject(self, _currentStrokeKey, currentStroke,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (LTTouchCollector *)touchCollector {
  LTTouchCollector *touchCollector = objc_getAssociatedObject(self, _kTouchCollectorKey);
  if (!touchCollector) {
    touchCollector = [self createTouchCollector];
    objc_setAssociatedObject(self, _kTouchCollectorKey, touchCollector,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return touchCollector;
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

- (id<LTViewTouchDelegate>)touchDelegateForLTView {
  return self.touchCollector;
}

@end

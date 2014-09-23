// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTouchCollector.h"

#import "LTCGExtensions.h"
#import "LTTouchCollectorDistanceFilter.h"
#import "LTTouchCollectorFilter.h"
#import "LTTouchCollectorTimeIntervalFilter.h"
#import "LTPainterPoint.h"
#import "LTView.h"

@interface LTTouchCollector ()

/// Filter used for the initial stroke movement. A seperate filter is used to avoid misdetecting the
/// beginning of two finger gestures as touches.
@property (strong, nonatomic) id<LTTouchCollectorFilter> filterForInitialMovement;

/// Filter used for disabling the navigation gestures of the \c LTView after a stroke started and
/// gained enough momentum.
@property (strong, nonatomic) id<LTTouchCollectorFilter> filterForDisablingNavigation;

/// Timer used to trigger touch events based on time, even if there was no movement.
@property (strong, nonatomic) NSTimer *timer;

/// The touch object representing the finger painting. This object is persistent througout a
/// multi-touch sequence, meaning that once we set this in the beginning of the stroke, we can
/// expect all touches by the same finger to update this object.
///
/// @see \c UITouch class reference for more details.
@property (weak, nonatomic) UITouch *paintingTouch;

/// Instance of the \c LTView being painted on. This is kept througout the stroke to allow timer
/// events and user cancellation events to access the view if necessary.
@property (weak, nonatomic) LTView *paintingView;

/// Array with all touch points collected during the current stroke.
@property (strong, nonatomic) NSMutableArray *strokeTouchPoints;

/// Indicates that the navigation mode of the \c LTView was set to none, and that it should be
/// restored when the stroke ends.
@property (nonatomic) BOOL forcedNavigationMode;

/// Navigation mode of the LTView prior to the stroke.
@property (nonatomic) LTViewNavigationMode previousNavigationMode;

@end

@implementation LTTouchCollector

/// Minimal screen distance for the default filter, in case no filter is provided.
static const CGFloat kMinimalScreenDistanceDuringStroke = 1;

/// Minimal distance from the stroke starting point, that will trigger the initial movement touch.
static const CGFloat kMinimalScreenDistanceForInitialMovement = 10;

/// Minimal time interval from the starting touch time, that will trigger the initial timer touch.
static const CGFloat kMinimalTimeIntervalForInitialMovement = 0.3;

/// Minimal distance from the stroke starting point, for disabling the navigation gestures.
static const CGFloat kMinimalScreenDistanceForDisablingNavigation = 30;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    self.filter = [self createDefaultFilter];
    self.filterForDisablingNavigation = [self createFilterForDisablingNavigation];
    self.previousNavigationMode = LTViewNavigationNone;
  }
  return self;
}

- (id<LTTouchCollectorFilter>)createDefaultFilter {
  return [LTTouchCollectorDistanceFilter
          filterWithMinimalScreenDistance:kMinimalScreenDistanceDuringStroke];
}

- (id<LTTouchCollectorFilter>)createFilterForDisablingNavigation {
  return [LTTouchCollectorDistanceFilter
          filterWithMinimalScreenDistance:kMinimalScreenDistanceForDisablingNavigation];
}

#pragma mark -
#pragma mark LTViewTouchDelegate
#pragma mark -

- (void)ltView:(LTView *)view touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  if (self.paintingTouch || [event allTouches].count != 1)  {
    return;
  }
  
  // expecting touches to be a subset of [event allTouches].
  LTAssert(touches.count == 1);
  self.paintingTouch = [touches anyObject];
  self.paintingView = view;
  LTPainterPoint *point = [self pointFromTouch:self.paintingTouch inView:view];
  self.strokeTouchPoints = [NSMutableArray arrayWithObject:point];
  [self.delegate ltTouchCollector:self startedStrokeAt:point];
  [self startTimer];
}

- (void)ltView:(LTView *)view touchesMoved:(NSSet __unused *)touches
     withEvent:(UIEvent __unused *)event {
  if (!self.paintingTouch || self.paintingTouch.phase != UITouchPhaseMoved) {
    return;
  }

  // Test the new point with the current filter, and collect it if accepted.
  LTPainterPoint *newPoint = [self pointFromTouch:self.paintingTouch inView:view];
  LTPainterPoint *oldPoint = self.lastPoint;
  if ([[self filterForCurrentStrokeState] acceptNewPoint:newPoint withOldPoint:oldPoint]) {
    [self.strokeTouchPoints addObject:newPoint];
    [self.delegate ltTouchCollector:self collectedStrokeTouch:newPoint];
  }
  
  // Disable the two finger navigation if moved enough from the initial touch location.
  if ([self.filterForDisablingNavigation acceptNewPoint:newPoint withOldPoint:self.firstPoint]) {
    if (!self.forcedNavigationMode) {
      self.forcedNavigationMode = YES;
      self.previousNavigationMode = view.navigationMode;
      view.navigationMode = LTViewNavigationNone;
    }
  }
}

- (void)ltView:(LTView *)view touchesEnded:(NSSet *)touches withEvent:(UIEvent __unused *)event {
  [self handlePossibleStrokeEndingTouches:touches inView:view];
}

- (void)ltView:(LTView *)view touchesCancelled:(NSSet *)touches
     withEvent:(UIEvent __unused *)event {
  [self handlePossibleStrokeEndingTouches:touches inView:view];
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (void)cancelActiveStroke {
  if (self.paintingTouch) {
    [self finishStroke:YES];
  }
}

#pragma mark -
#pragma mark Painting Utilities
#pragma mark -

- (void)handlePossibleStrokeEndingTouches:(NSSet *)touches inView:(LTView __unused *)view {
  if ([touches containsObject:self.paintingTouch]) {
    BOOL cancelled = self.paintingTouch.phase == UITouchPhaseCancelled;
    [self finishStroke:cancelled];
  }
}

- (void)finishStroke:(BOOL)cancelled {
  self.paintingTouch = nil;
  [self endTimer];
  if (self.forcedNavigationMode) {
    self.paintingView.navigationMode = self.previousNavigationMode;
    self.previousNavigationMode = LTViewNavigationNone;
    self.forcedNavigationMode = NO;
  }
  self.paintingView = nil;
  [self.delegate ltTouchCollectorFinishedStroke:self cancelled:cancelled];
}

- (id<LTTouchCollectorFilter>)filterForCurrentStrokeState {
  return (self.strokeTouchPoints.count > 1) ? self.filter : self.filterForInitialMovement;
}

#pragma mark -
#pragma mark Timer-Based Touches
#pragma mark -

/// Creates and starts the timer running during the stroke, triggering time-based touch events when
/// the touches are stationary.
- (void)startTimer {
  LTAssert(!self.timer, @"Starting a stroke timer, but timer already exists.");
  self.timer = [NSTimer timerWithTimeInterval:0.01 target:self selector:@selector(touchTimerFired:)
                                     userInfo:nil repeats:YES];
  [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)endTimer {
  [self.timer invalidate];
  self.timer = nil;
}

/// Triggered by a timer during a stroke, collects time-based events for stationary toches.
- (void)touchTimerFired:(NSTimer __unused *)timer {
  if (!self.paintingTouch || !self.paintingView ||
      self.paintingTouch.phase != UITouchPhaseStationary) {
    return;
  }
  
  // Test the new point with the current filter, and collect it if accepted.
  LTPainterPoint *newPoint = [self pointFromTouch:self.paintingTouch inView:self.paintingView];
  LTPainterPoint *oldPoint = self.lastPoint;
  if ([[self filterForCurrentStrokeState] acceptNewPoint:newPoint withOldPoint:oldPoint]) {
    [self.strokeTouchPoints addObject:newPoint];
    [self.delegate ltTouchCollector:self collectedTimerTouch:newPoint];
  }
}

#pragma mark -
#pragma mark Painting Touch Points
#pragma mark -

- (LTPainterPoint *)pointFromTouch:(UITouch *)touch inView:(LTView *)view {
  LTPainterPoint *point = [[LTPainterPoint alloc] initWithCurrentTimestamp];
  point.contentPosition =
      [touch locationInView:view.viewForContentCoordinates] * view.contentScaleFactor;
  point.screenPosition = [touch locationInView:view];
  point.zoomScale = view.zoomScale;
  return point;
}

- (LTPainterPoint *)firstPoint {
  return self.strokeTouchPoints.firstObject;
}

- (LTPainterPoint *)lastPoint {
  return self.strokeTouchPoints.lastObject;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setFilter:(id<LTTouchCollectorFilter>)filter {
  _filter = filter ?: [self createDefaultFilter];
  self.filterForInitialMovement = [self createFilterForInitialMovement];
}

- (id<LTTouchCollectorFilter>)createFilterForInitialMovement {
  LTAssert(self.filter);
  LTTouchCollectorOrFilter *initialMovementFilter =
      [[LTTouchCollectorOrFilter alloc] initWithFilters:@[
          [LTTouchCollectorTimeIntervalFilter
              filterWithMinimalTimeInterval:kMinimalTimeIntervalForInitialMovement],
          [LTTouchCollectorDistanceFilter
              filterWithMinimalScreenDistance:kMinimalScreenDistanceForInitialMovement]]];
  
  return [[LTTouchCollectorAndFilter alloc] initWithFilters:@[initialMovementFilter, self.filter]];
}

@end

// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTouchCollector.h"

#import "LTContentInteraction.h"
#import "LTInteractionMode.h"
#import "LTTouchCollectorDistanceFilter.h"
#import "LTTouchCollectorFilter.h"
#import "LTTouchCollectorTimeIntervalFilter.h"
#import "LTTouchEvent.h"
#import "LTTouchEventProvider.h"
#import "LTPainterPoint.h"

@interface LTTouchCollector ()

/// Filter used for the initial stroke movement. A seperate filter is used to avoid misdetecting the
/// beginning of two finger gestures as touches.
@property (strong, nonatomic) id<LTTouchCollectorFilter> filterForInitialMovement;

/// Filter accepting points with a sufficient distance from the first point of the most recent
/// content touch event sequence. Used to decide when to update the interaction mode of the
/// \c interactionModeManager of this instance.
@property (strong, nonatomic) id<LTTouchCollectorFilter> filterForDisablingNavigation;

/// Timer used to trigger touch events based on time, even if there was no movement.
@property (strong, nonatomic) NSTimer *timer;

/// ID of the currently occurring touch event sequence. \c nil if no touch event sequence is
/// currently occurring.
@property (strong, nonatomic, nullable) NSNumber *sequenceID;

/// Object via which the interaction mode can be updated.
@property (strong, nonatomic) id<LTInteractionModeManager> interactionModeManager;

/// Array with all touch points collected during the current stroke.
@property (strong, nonatomic) NSMutableArray *strokeTouchPoints;

/// \c YES during active strokes, indicating that the interaction mode was set to
/// \c LTInteractionModeNone, and that it should be restored when the stroke ends.
@property (nonatomic) BOOL useStrokeInteractionMode;

/// Interaction mode right before a currently occuring content touch event sequence.
@property (nonatomic) LTInteractionMode previousInteractionMode;

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

- (instancetype)initWithInteractionModeManager:(id<LTInteractionModeManager>)manager {
  if (self = [super init]) {
    self.filter = [self createDefaultFilter];
    self.filterForDisablingNavigation = [self createFilterForDisablingNavigation];
    self.previousInteractionMode = LTInteractionModeNone;
    self.interactionModeManager = manager;
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
#pragma mark LTContentTouchEventDelegate
#pragma mark -

- (void)receivedContentTouchEvents:(LTContentTouchEvents *)touchEvents
                   predictedEvents:(__unused LTContentTouchEvents *)predictedTouchEvents
           touchEventSequenceState:(LTTouchEventSequenceState)state {
  if (state == LTTouchEventSequenceStateStart) {
    LTParameterAssert(touchEvents.count);
  }

  if (!self.sequenceID && touchEvents.firstObject) {
    self.sequenceID = @(touchEvents.firstObject.sequenceID);
  } else if (self.sequenceID &&
             touchEvents.firstObject.sequenceID != [self.sequenceID unsignedIntegerValue]) {
    // Currently only a single touch event sequence is handled.
    return;
  }

  switch (state) {
    case LTTouchEventSequenceStateStart:
      [self handleStartingTouchEvent:touchEvents.firstObject];
      if (touchEvents.count > 1) {
        LTContentTouchEvents *unhandledTouchEvents =
            [touchEvents subarrayWithRange:NSMakeRange(1, touchEvents.count - 1)];
        [self handleContinuingTouchEvents:unhandledTouchEvents];
      }
      return;
    case LTTouchEventSequenceStateContinuation:
      [self handleContinuingTouchEvents:touchEvents];
      return;
    case LTTouchEventSequenceStateEnd:
      [self finishStroke:NO];
      return;
    case LTTouchEventSequenceStateCancellation:
      [self finishStroke:YES];
      return;
  }
}

- (void)receivedUpdatesOfContentTouchEvents:(LTContentTouchEvents __unused *)contentTouchEvents {
}

- (void)contentTouchEventSequencesWithIDs:(NSSet<NSNumber *> *)sequenceIDs
                      terminatedWithState:(LTTouchEventSequenceState)state {
  LTParameterAssert([sequenceIDs containsObject:self.sequenceID],
                    @"The given sequence IDs (%@) do not contain the currently stored ID (%@)",
                    sequenceIDs, self.sequenceID);
  [self finishStroke:state == LTTouchEventSequenceStateCancellation];
}

- (void)handleStartingTouchEvent:(id<LTContentTouchEvent>)touchEvent {
  LTPainterPoint *point = [self pointFromTouchEvent:touchEvent];
  self.strokeTouchPoints = [NSMutableArray arrayWithObject:point];
  [self.delegate ltTouchCollector:self startedStrokeAt:point];
  [self startTimer];
}

- (void)handleContinuingTouchEvents:(LTContentTouchEvents *)touchEvents {
  for (id<LTContentTouchEvent> touchEvent in touchEvents) {
    // Test the new point with the current filter, and collect it if accepted.
    LTPainterPoint *newPoint = [self pointFromTouchEvent:touchEvent];
    LTPainterPoint *oldPoint = self.lastPoint;
    if ([[self filterForCurrentStrokeState] acceptNewPoint:newPoint withOldPoint:oldPoint]) {
      [self.strokeTouchPoints addObject:newPoint];
      [self.delegate ltTouchCollector:self collectedStrokeTouch:newPoint];
    }

    // Disable any gesture interaction if moved enough from the initial touch location.
    if ([self.filterForDisablingNavigation acceptNewPoint:newPoint withOldPoint:self.firstPoint]) {
      if (!self.useStrokeInteractionMode) {
        self.useStrokeInteractionMode = YES;
        self.previousInteractionMode = self.interactionModeManager.interactionMode;
        self.interactionModeManager.interactionMode = LTInteractionModeTouchEvents;
      }
    }
  }
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (void)cancelActiveStroke {
  if (self.sequenceID) {
    [self finishStroke:YES];
  }
}

#pragma mark -
#pragma mark Painting Utilities
#pragma mark -

- (void)finishStroke:(BOOL)cancelled {
  self.sequenceID = nil;
  [self endTimer];
  if (self.useStrokeInteractionMode &&
      self.interactionModeManager.interactionMode == LTInteractionModeTouchEvents) {
    self.interactionModeManager.interactionMode = self.previousInteractionMode;
    self.previousInteractionMode = LTInteractionModeNone;
    self.useStrokeInteractionMode = NO;
  }
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
  if (!self.sequenceID) {
    return;
  }
  NSSet<id<LTContentTouchEvent>> *stationaryTouchEvents =
      [self.touchEventProvider stationaryContentTouchEvents];

  for (id<LTContentTouchEvent> contentTouchEvent in stationaryTouchEvents) {
    if (contentTouchEvent.sequenceID != [self.sequenceID unsignedIntegerValue]) {
      continue;
    }

    // Test the new point with the current filter, and collect it if accepted.
    LTPainterPoint *newPoint = [self pointFromTouchEvent:contentTouchEvent];
    LTPainterPoint *oldPoint = self.lastPoint;
    if ([[self filterForCurrentStrokeState] acceptNewPoint:newPoint withOldPoint:oldPoint]) {
      [self.strokeTouchPoints addObject:newPoint];
      [self.delegate ltTouchCollector:self collectedTimerTouch:newPoint];
    }
  }
}

#pragma mark -
#pragma mark Painting Touch Points
#pragma mark -

- (LTPainterPoint *)pointFromTouchEvent:(id<LTContentTouchEvent>)touchEvent {
  LTPainterPoint *point = [[LTPainterPoint alloc] initWithCurrentTimestamp];
  point.contentPosition = touchEvent.contentLocation;
  point.screenPosition = touchEvent.viewLocation;
  point.zoomScale = touchEvent.contentZoomScale;
  point.touchRadius = touchEvent.majorRadius;
  point.touchRadiusTolerance = touchEvent.majorRadiusTolerance;
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

// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTViewDelegates.h"

#import "LTPainterPoint.h"

@protocol LTTouchCollectorFilter;
@class LTTouchCollector;

/// This protocol is used to receive collection events from the \c LTTouchCollector.
@protocol LTTouchCollectorDelegate <NSObject>

/// Called when a touch event starting a stroke is received.
- (void)ltTouchCollector:(LTTouchCollector *)touchCollector startedStrokeAt:(LTPainterPoint *)touch;

/// Called when a touch event during an active stroke is collected.
- (void)ltTouchCollector:(LTTouchCollector *)touchCollector
    collectedStrokeTouch:(LTPainterPoint *)touch;

/// Called when a timer-generated touch event during an active stroke is collected.
- (void)ltTouchCollector:(LTTouchCollector *)touchCollector
     collectedTimerTouch:(LTPainterPoint *)touch;

/// Called when the collector finished collecting touches for the stroke.
- (void)ltTouchCollectorFinishedStroke:(LTTouchCollector *)touchCollector;

@end

/// The \c LTTouchCollector class is used to collect single-finger painting touch events, handling
/// the logic of ignoring the multi-finger events, disabling navigation on the \c LTView after
/// a stroke started, etc.
/// Additionally, the collector can be configured with a \c LTTouchCollectorFilter for filtering
/// the events based on differences (distance, time interval, etc.) between the last collected touch
/// and the newly collected one.
@interface LTTouchCollector : NSObject <LTViewTouchDelegate>

/// This delegate will be notified on collected events.
@property (weak, nonatomic) id<LTTouchCollectorDelegate> delegate;

/// Filter used to decide whether to collect a new touch event, based on the differences with the
/// previously collected touch.
@property (strong, nonatomic) id<LTTouchCollectorFilter> filter;

@end

// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventDelegate.h"

#import "LTPainterPoint.h"

@protocol LTContentTouchEventProvider, LTInteractionModeDelegate, LTTouchCollectorFilter;

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
- (void)ltTouchCollectorFinishedStroke:(LTTouchCollector *)touchCollector cancelled:(BOOL)cancelled;

@end

/// The \c LTTouchCollector class is used to filter content touch events of a single content touch
/// event sequence and convert them to corresponding \c LTPainterPoint objects. This class also
/// handles the logic of updating the interaction mode of a given \c LTInteractionModeDelegate
/// during occurring touch event sequences. The filtering of the incoming content touch events is
/// performed by an \c LTTouchCollectorFilter.
@interface LTTouchCollector : NSObject <LTContentTouchEventDelegate>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c delegate.
- (instancetype)initWithInteractionModeDelegate:(id<LTInteractionModeDelegate>)delegate
    NS_DESIGNATED_INITIALIZER;

/// Cancels the currently active stroke, or do nothing in case there is no active stroke.
- (void)cancelActiveStroke;

/// This delegate will be notified on collected events.
@property (weak, nonatomic) id<LTTouchCollectorDelegate> delegate;

/// Provider of content touch events.
@property (weak, nonatomic) id<LTContentTouchEventProvider> touchEventProvider;

/// Filter used to decide whether to collect a new touch event, based on the differences with the
/// previously collected touch. When the object is initialized, or when filter is set to nil, a
/// default filter with a single screen point distance threshold will be used.
@property (strong, nonatomic) id<LTTouchCollectorFilter> filter;

@end

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInterval.h"

NS_ASSUME_NONNULL_BEGIN

@class LTContentTouchEvent;

/// Object constituting a FIFO queue buffering \c LTContentTouchEvent objects based on their
/// \c timestamp and their speed. Due to its task, the object is intrinsically stateful.
///
/// Objects of this class can e.g. be used to buffer \c LTContentTouchEvent objects used for
/// brush painting, in order to achieve nicer tapering effects. Since the buffering of the
/// \c LTContentTouchEvent objects adapts to their speed, the final tapering can be achieved without
/// having an unjustifiable impact on the brush painting experience.
///
/// Conceptually, the object has two states: idle and active. In the idle state, which is also the
/// initial state, no events are buffered. Any call to the
/// \c processAndPossiblyBufferContentTouchEvents:returnAllEvents: method with \c returnAllEvents
/// set to \c NO causes the object to transition into the active state. In the active state,
/// incoming events are buffered if the period of time which passed between their \c timestamp and
/// the \c timestamp of the event most recently returned by aforementioned method is smaller than a
/// certain threshold.
/// Buffered events are returned in conjunction with incoming events if they do not fulfill
/// aforementioned condition anymore or if the method was called with \c returnAllEvents set to
/// \c YES.
/// The object transitions into the idle state if and only if the aforementioned method is called
/// with \c returnAllEvents set to \c YES.
///
/// The aforementioned threshold is dynamically computed as follows: first, the speed of an incoming
/// touch event is approximated according to its \c viewLocation and \c timestamp difference w.r.t
/// those of the touch event preceeding it in the handled stream of touch events. The speed is then
/// converted into a factor between \c 0 and \c 1, by dividing it by a \c maxSpeed and clamping it.
/// The factor is then used to compute the time interval allowed between the \c timestamp of the
/// discussed touch event and the one of the event most recently returned by the
/// \c processAndPossiblyBufferContentTouchEvents:returnAllEvents:method. The range of time
/// intervals is determined by the \c timeInterval property.
///
/// @note It is guaranteed that the events are always returned in the order in which they have been
/// provided.
@interface LTSpeedBasedContentTouchEventBuffer : NSObject

/// Returns a subset of the given \c contentTouchEvents, potentially in conjunction with events
/// which have previously been buffered. Returns the given \c contentTouchEvents in conjunction with
/// all previously buffered content touch events if \c returnAllEvents is \c YES.
///
/// @important The method assumes that the \c timestamp values of the given \c contentTouchEvents
/// are strictly monotonically increasing, also across different method calls, except if the object
/// is in idle state.
- (NSArray<LTContentTouchEvent *> *)
    processAndPossiblyBufferContentTouchEvents:(NSArray<LTContentTouchEvent *> *)contentTouchEvents
                               returnAllEvents:(BOOL)returnAllEvents;

/// Content touch events currently buffered by this instance. Is empty in idle state or if no events
/// are currently buffered.
@property (readonly, nonatomic) NSArray<LTContentTouchEvent *> *bufferedEvents;

/// Maximum speed used for determining whether an incoming event is buffered. Initial value is
/// \c 5000. Must be non-negative.
@property (nonatomic) CGFloat maxSpeed;

/// Interval of time intervals used for determining whether an incoming event is buffered. For
/// events with speed \c 0 \c timeIntervals.min() is used, while for events with speed greater than
/// or equal to \c maxSpeed \c timeIntervals.max() is used.
/// Initial value is <tt>[1.0 / 120, 1.0 / 20]</tt>
@property (nonatomic) lt::Interval<NSTimeInterval> timeIntervals;

@end

NS_ASSUME_NONNULL_END

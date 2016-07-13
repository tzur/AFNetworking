// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@protocol LTTouchEvent;

/// Ordered collection of \c id<LTTouchEvent> objects.
typedef NSArray<id<LTTouchEvent>> LTTouchEvents;

/// Mutable ordered collection of \c id<LTTouchEvent> objects.
typedef NSMutableArray<id<LTTouchEvent>> LTMutableTouchEvents;

/// Possible states of a touch event sequence.
typedef NS_ENUM(NSUInteger, LTTouchEventSequenceState) {
  /// Indicates that the touch event sequences has just started. Initial state of a touch event
  /// sequence. Possible next states are \c LTTouchEventSequenceStateContinuation and
  /// \c LTTouchEventSequenceStateContinuationStationary.
  LTTouchEventSequenceStateStart,
  /// Indicates that the touch event sequence is currently being continued. Possible next states are
  /// \c LTTouchEventSequenceStateContinuation, \c LTTouchEventSequenceStateContinuationStationary,
  /// \c LTTouchEventSequenceStateEnd, and \c LTTouchEventSequenceStateCancellation.
  LTTouchEventSequenceStateContinuation,
  /// Indicates that the touch event sequence is currently being continued, but the touch events
  /// are occurring at the same location as before. Possible next states are
  /// \c LTTouchEventSequenceStateContinuation, \c LTTouchEventSequenceStateContinuationStationary,
  /// \c LTTouchEventSequenceStateEnd, and \c LTTouchEventSequenceStateCancellation.
  LTTouchEventSequenceStateContinuationStationary,
  /// Indicates that the touch event sequence has just ended. Final state of a touch event sequence.
  LTTouchEventSequenceStateEnd,
  /// Indicates that the touch event sequence has just been cancelled. Final state of a touch event
  /// sequence.
  LTTouchEventSequenceStateCancellation
};

/// Protocol to be implemented by objects representing the discrete state of a touch (event)
/// sequence associated with a view. A touch event sequence starts with an input device (e.g.
/// finger, stylus, etc.) entering the area in which touches are sensorically recognized and ends
/// either due to the input device leaving that area or due to cancellation. A sequence consists of
/// a discrete series of touch events which are result of the discretization of the sequence
/// according to the sampling rate of the device sensors. In iOS, a touch event sequence is
/// represented by a single \c UITouch object that persists during the entire sequence. According to
/// the documentation of \c UITouch, any such object should never be retained. Hence, this class is
/// used to store the current state of a given \c UITouch object.
@protocol LTTouchEvent <NSObject, NSCopying>

/// ID of the sequence to which this touch belongs.
///
/// @important Temporally consecutive touch event sequences might have the same sequence ID.
/// However, it is guaranteed that there are no concurrently occurring touch event sequences with
/// the same sequence ID, if the sequences originate from the same \c UIResponder.
@property (readonly, nonatomic) NSUInteger sequenceID;

/// Location of the touch during the touch event, in coordinates of the \c view.
@property (readonly, nonatomic) CGPoint viewLocation;

/// Location of the touch during the previous touch event, in coordinates of the \c view.
@property (readonly, nonatomic) CGPoint previousViewLocation;

#pragma mark -
#pragma mark Properties of UITouch
#pragma mark -

/// Timestamp of the touch event.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic) NSTimeInterval timestamp;

/// View in which the touch event sequence started.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic, nullable) UIView *view;

/// Phase of the touch during the event.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic) UITouchPhase phase;

/// Number of taps associated with this touch event.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic) NSUInteger tapCount;

/// Radius, in point units of the presentation coordinate system, of the touch during the event.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic) CGFloat majorRadius;

/// Tolerance, in point units of the presentation coordinate system, of the radius of this touch
/// event.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic) CGFloat majorRadiusTolerance;

/// Type of the touch event. \c UITouchTypeDirect if the \c UITouch object whose current state is
/// represented by this instance does not provide a type.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic) UITouchType type;

/// Boxed force value, of type \c CGFloat, of the touch during the event. \c nil if the \c UITouch
/// object whose current state is represented by this instance does not provide a force value.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic, nullable) NSNumber *force;

/// Boxed maximum possible force value, of type \c CGFloat, of the touch. \c nil if the \c UITouch
/// object whose current state is represented by this instance does not provide a maximum possible
/// force value.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic, nullable) NSNumber *maximumPossibleForce;

/// Boxed azimuth angle value, of type \c CGFloat, of the touch during the event, relative to the
/// window in which the touch event sequence started. \c nil if the \c UITouch object whose current
/// state is represented by this instance does not provide an azimuth angle value.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic, nullable) NSNumber *azimuthAngle;

/// Azimuth unit vector, of type \c CGFloat, of the touch during the event, relative to the window
/// in which the touch event sequence started. \c LTVector2::null() if the \c UITouch object whose
/// current state is represented by this instance does not provide an azimuth unit vector.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic) LTVector2 azimuthUnitVector;

/// Boxed altitude angle value, of type \c CGFloat, of the touch during the event. \c nil if the
/// \c UITouch object whose current state is represented by this instance does not provide an
/// altitude angle value.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic, nullable) NSNumber *altitudeAngle;

/// Boxed index number for correlating an updated touch event with the original touch event. \c nil
/// if the \c UITouch object whose current state is represented by this instance does not provide an
/// estimation update index or does not expect/represent an update.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic, nullable) NSNumber *estimationUpdateIndex;

/// Set of properties of the touch event that have estimated values.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic) UITouchProperties estimatedProperties;

/// Set of properties of the touch event whose estimated values are expected to be updated in the
/// future.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic) UITouchProperties estimatedPropertiesExpectingUpdates;

@end

/// Immmutable value class constituting a touch event. Refer to the \c LTTouchEvent protocol for
/// more information.
@interface LTTouchEvent : NSObject <LTTouchEvent>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the properties of the given \c touch and the given \c sequenceID. The given
/// \c touch is not retained by the returned object. The \c timestamp of the returned object equals
/// the \c timestamp of the given \c touch.
+ (instancetype)touchEventWithPropertiesOfTouch:(UITouch *)touch sequenceID:(NSUInteger)sequenceID;

/// Initializes with the properties of the given \c touch, \c timestamp, and \c sequenceID. The
/// given \c touch is not retained by the returned object.
+ (instancetype)touchEventWithPropertiesOfTouch:(UITouch *)touch timestamp:(NSTimeInterval)timestamp
                                     sequenceID:(NSUInteger)sequenceID;

@end

NS_ASSUME_NONNULL_END

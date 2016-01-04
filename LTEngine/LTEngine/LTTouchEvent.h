// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Immmutable value object representing the discrete state of a touch (event) sequence associated
/// with a view. A touch event sequence starts with an input device (e.g. finger, stylus, etc.)
/// entering the area in which touches are sensorically recognized and ends either due to the input
/// device leaving that area or due to cancellation. A sequence consists of a discrete series of
/// touch events which are result of the discretization of the sequence according to the sampling
/// rate of the device sensors. In iOS, a touch event sequence is represented by a single \c UITouch
/// object that persists during the entire sequence. According to the documentation of \c UITouch,
/// any such object should never be retained. Hence, this class is used to store the current state
/// of a given \c UITouch object.
@interface LTTouchEvent : NSObject <NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the properties of the given \c touch and the given \c sequenceID. The given
/// \c touch is not retained by the returned object.
+ (instancetype)touchEventWithPropertiesOfTouch:(UITouch *)touch sequenceID:(NSUInteger)sequenceID;

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
@property (readonly, nonatomic) CGFloat tapCount;

/// Radius, in points, of the touch during the event.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic) CGFloat majorRadius;

/// Tolerance, in points, of the radius of this touch event.
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
@property (nonatomic, readonly, nullable) NSNumber *estimationUpdateIndex;

/// Set of properties of the touch event that have estimated values.
///
/// @see Homonymous property of \c UITouch.
@property (nonatomic,readonly) UITouchProperties estimatedProperties;

/// Set of properties of the touch event whose estimated values are expected to be updated in the
/// future.
///
/// @see Homonymous property of \c UITouch.
@property (nonatomic,readonly) UITouchProperties estimatedPropertiesExpectingUpdates;

@end

NS_ASSUME_NONNULL_END

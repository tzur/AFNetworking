// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventCancellation.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTTouchEventDelegate;

/// View converting incoming \c UITouch objects to \c LTTouchEvent objects and passing them on to
/// its delegate. In particular, the view informs its delegate about a) \c LTTouchEvent objects
/// generated due to calls to the <tt>touchesBegan/Moved/Ended/Cancelled:withEvent:</tt>methods
/// of \c UIView, and b) possibly existing stationary \c LTTouchEvent objects generated once per
/// frame.
@interface LTTouchEventView : UIView <LTTouchEventCancellation>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

/// Initializes with the given \c frame and the given \c delegate to which converted touch events
/// are delegated. The given \c delegate is held weakly.
- (instancetype)initWithFrame:(CGRect)frame
                     delegate:(id<LTTouchEventDelegate>)delegate NS_DESIGNATED_INITIALIZER;

/// Delegate to which converted touch events are delegated.
@property (weak, readonly, nonatomic) id<LTTouchEventDelegate> delegate;

/// Desired rate, in Hertz, at which stationary touch events are to be forwarded to the \c delegate
/// of this instance. The actual rate is kept as close as possible to the desired rate, but may be
/// lower due to hardware constraints and/or other tasks being executing simultaneously.
///
/// Initial value is \c 60. Setting this value to \c 0 causes the forwarding of stationary touch
/// events to stop.  Must not be greater than \c 60.
@property (nonatomic) NSUInteger desiredRateForStationaryTouchEventForwarding
    NS_AVAILABLE_IOS(10_0);

@end

NS_ASSUME_NONNULL_END

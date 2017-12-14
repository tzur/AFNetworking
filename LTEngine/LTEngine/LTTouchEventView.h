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

/// Indication whether this instance is currently receiving touch events.
@property (readonly, nonatomic) BOOL isCurrentlyReceivingTouchEvents;

/// Indication whether to forward stationary touch events to \c delegate, at the display refresh
/// rate. Default value is \c YES.
@property (nonatomic) BOOL forwardStationaryTouchEvents;

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTypedefs.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTTimeProvider;

/// Class used for timing blocks of code using a high-precision timer which is independent on a
/// runloop (such as \c NSTimer).
@interface LTTimer : NSObject

/// Initializes a new timer with the given time provider.
- (instancetype)initWithTimeProvider:(id<LTTimeProvider>)timeProvider NS_DESIGNATED_INITIALIZER;

/// Returns the time took to execute the given block.
+ (CFTimeInterval)timeForBlock:(LTVoidBlock)block;

/// Starts the timer. If the timer is already started, the call is ignored.
- (void)start;

/// Returns the time elapsed since the timer was started or the last split, if available.
- (CFTimeInterval)split;

/// Stops the timer and returns the time elapsed, in seconds, since the timer was started. If the
/// timer is already stopped, this method will return \c 0.
- (CFTimeInterval)stop;

/// Returns \c YES if the timer is currently running.
@property (readonly, nonatomic) BOOL isRunning;

@end

/// Protocol for object that returns the current time in seconds.
@protocol LTTimeProvider <NSObject>

/// Returns the current time in seconds. The time is relative to a fixed time point, which can be
/// different than the Epoch (for example, the device uptime in seconds).
- (CFTimeInterval)currentTime;

@end

NS_ASSUME_NONNULL_END

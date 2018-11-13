// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

@protocol LTTimeIntervalProvider;

/// Contains time spent in various states of the application since the start of a timer.
typedef struct {
  /// Time spent in foreground.
  NSTimeInterval foregroundRunTime;

  /// Time spent in foreground and background.
  NSTimeInterval totalRunTime;
} INTAppRunTimes;

/// Times an activity duration in an application, including its total time and the time it spent
/// while the app is in foreground.
@protocol INTAppLifecycleTimer <NSObject>

/// Time spent in various states of the application since the timer started.
@property (readonly, nonatomic) INTAppRunTimes appRunTimes;

@end

/// Default implementation of an \c INTAppLifecycleTimer. The timer does not increment
/// \c appRunTimes until started. The timer cannot be stopped once started. This class is thread
/// safe.
@interface INTAppLifecycleTimer : NSObject <INTAppLifecycleTimer>

/// Initializes with \c timeProvider used to provide time samples for generating \c appRunTimes.
- (instancetype)initWithTimeProvider:(id<LTTimeIntervalProvider>)timeProvider
    NS_DESIGNATED_INITIALIZER;

/// Starts the timer. Calling this method after it was called once has no effect.
- (void)start;

@end

NS_ASSUME_NONNULL_END

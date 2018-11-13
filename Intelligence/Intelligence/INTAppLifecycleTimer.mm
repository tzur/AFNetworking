// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAppLifecycleTimer.h"

#import <LTKit/LTTimer.h>

NS_ASSUME_NONNULL_BEGIN

/// Provides the time measured by the kernels \c CLOCK_MONOTONIC. \c CLOCK_MONOTONIC represents a
/// strictly ascending elapsed time since an arbitrary point, and is not affected by changes to the
/// systems' time-of-day clock, nor does it pause or reset at least as long the system is running,
/// including in sleep mode. These properties guarantee that the time provided during the lifetime
/// of an application is strictly ascending. The other common approach of providing a monotonic time
/// is to use the \c CACurrentMediaTime() call, but this clock pauses when the system is in standby
/// (locked) mode for a few minutes, making it unreliable for tracking a total run time of a
/// process.
///
/// @see http://www.manpagez.com/man/3/clock_gettime/
/// @see https://bendodson.com/weblog/2013/01/29/ca-current-media-time/
@interface INTMonotonicTimeProvider : NSObject <LTTimeIntervalProvider>
@end

@implementation INTMonotonicTimeProvider

- (CFTimeInterval)currentTime {
  struct timespec time;
  clock_gettime(CLOCK_MONOTONIC, &time);
  return time.tv_sec + (double)time.tv_nsec / NSEC_PER_SEC;
}

@end

@interface INTAppLifecycleTimer ()

/// Used for calculating elapsed times.
@property (readonly, nonatomic) id<LTTimeIntervalProvider> timeProvider;

/// \c YES if the timer is running.
@property (nonatomic) BOOL isRunning;

/// Time when \c start had been called, or \c 0 if the timer is not yet active.
@property (nonatomic) NSTimeInterval startTime;

/// Time spent in background since the app started, or \c 0 if the timer is not yet active.
@property (nonatomic) NSTimeInterval backgroundRunTime;

/// Time the latest background activity started. \c nil if the application is in foreground.
@property (nonatomic, nullable) NSNumber *backgroundStartTime;

@end

@implementation INTAppLifecycleTimer

- (instancetype)init {
  return [self initWithTimeProvider:[[INTMonotonicTimeProvider alloc] init]];
}

- (instancetype)initWithTimeProvider:(id<LTTimeIntervalProvider>)timeProvider {
  if (self = [super init]) {
    @synchronized (self) {
      _timeProvider = timeProvider;
    }

    [self bindNotificationObservation];
  }

  return self;
}

- (void)bindNotificationObservation {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
}

- (void)appWillEnterForeground:(NSNotification * __unused)notification {
  @synchronized (self) {
    if (!self.backgroundStartTime) {
      return;
    }

    self.backgroundRunTime +=
        ([self.timeProvider currentTime] - self.backgroundStartTime.doubleValue);
    self.backgroundStartTime = 0;
  }
}

- (void)appDidEnterBackground:(NSNotification * __unused)notification {
  @synchronized (self) {
    if (!self.isRunning) {
      return;
    }

    self.backgroundStartTime = @([self.timeProvider currentTime]);
  }
}

- (void)start {
  @synchronized (self) {
    if (self.isRunning) {
      return;
    }

    self.isRunning = YES;
    self.startTime = [self.timeProvider currentTime];
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark INTAppLifecycleTimer
#pragma mark -

- (INTAppRunTimes)appRunTimes {
  @synchronized (self) {
    if (!self.isRunning) {
      return {
        .foregroundRunTime = 0,
        .totalRunTime = 0
      };
    }

    auto currentTime = [self.timeProvider currentTime];

    auto totalRunTime = currentTime - self.startTime;
    auto backgroundRunTime = 0;

    if (self.backgroundStartTime) {
      backgroundRunTime = currentTime - self.backgroundStartTime.doubleValue +
          self.backgroundRunTime;
    } else {
      backgroundRunTime = self.backgroundRunTime;
    }
    auto foregroundRunTime = totalRunTime - backgroundRunTime;

    return {
      .foregroundRunTime = foregroundRunTime,
      .totalRunTime = totalRunTime
    };
  }
}

@end

NS_ASSUME_NONNULL_END

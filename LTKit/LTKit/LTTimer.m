// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTimer.h"

@interface LTDefaultTimeProvider : NSObject <LTTimeProvider>
@end

@implementation LTDefaultTimeProvider

- (CFTimeInterval)currentTime {
  return CACurrentMediaTime();
}

@end

@interface LTTimer ()

/// Time provider to use when calculating time intervals.
@property (nonatomic) id<LTTimeProvider> timeProvider;

/// Time the timer started.
@property (nonatomic) CFTimeInterval startTime;

/// Time the timer was last split.
@property (nonatomic) CFTimeInterval splitTime;

/// Returns \c YES if the timer is currently running.
@property (readwrite, nonatomic) BOOL isRunning;

@end

@implementation LTTimer

- (id)init {
  return [self initWithTimeProvider:[[LTDefaultTimeProvider alloc] init]];
}

+ (CFTimeInterval)timeForBlock:(LTVoidBlock)block {
  LTParameterAssert(block);

  LTTimer *timer = [[LTTimer alloc] init];
  [timer start];
  block();
  return [timer stop];
}

- (void)start {
  if (self.isRunning) {
    return;
  }

  self.startTime = [self.timeProvider currentTime];
  self.splitTime = self.startTime;
  self.isRunning = YES;
}

- (CFTimeInterval)split {
  CFTimeInterval currentTime = [self.timeProvider currentTime];
  CFTimeInterval timeElapsed = currentTime - self.splitTime;

  self.splitTime = currentTime;

  return timeElapsed;
}

- (CFTimeInterval)stop {
  if (!self.isRunning) {
    return 0;
  }

  CFTimeInterval timeElapsed = [self.timeProvider currentTime] - self.startTime;

  self.startTime = 0;
  self.splitTime = 0;
  self.isRunning = NO;

  return timeElapsed;
}

@end

@implementation LTTimer (ForTesting)

- (instancetype)initWithTimeProvider:(id<LTTimeProvider>)timeProvider {
  if (self = [super init]) {
    self.timeProvider = timeProvider;
  }
  return self;
}

@end

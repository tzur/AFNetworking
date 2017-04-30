// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTRecorderLogger.h"

NS_ASSUME_NONNULL_BEGIN

@interface INTRecorderLogger ()

/// Holds all the events that were logged by this logger, in the order they were received.
@property (readonly, nonatomic) NSMutableArray *events;

/// Filter returning \c NO if an event should not be logged.
@property (readonly, nonatomic) INTEventFilterBlock eventFilter;

/// Block that should be invoked each time \c events is updated.
@property (readonly, nonatomic) INTRecorderLoggerEventBlock eventBlock;

@end

@implementation INTRecorderLogger

- (instancetype)init {
  return [self initWithNewEventBlock:^(id){}];
}

- (instancetype)initWithEventFilter:(INTEventFilterBlock)eventFilter {
  return [self initWithEventFilter:eventFilter newEventBlock:^(id){}];
}

- (instancetype)initWithNewEventBlock:(INTRecorderLoggerEventBlock)eventBlock {
  return [self initWithEventFilter:^(id) {
    return YES;
  } newEventBlock:eventBlock];
}

- (instancetype)initWithEventFilter:(BOOL (^)(id _Nonnull))eventFilter
                      newEventBlock:(INTRecorderLoggerEventBlock)eventBlock {
  if (self = [super init]) {
    @synchronized (self) {
      _eventFilter = eventFilter;
      _events = [NSMutableArray array];
      _eventBlock = eventBlock;
    }
  }
  return self;
}

- (void)logEvent:(id)event {
  @synchronized (self) {
    LTParameterAssert([self isEventSupported:event], @"event %@ is not supported by %@", event,
                      self);

    [self.events addObject:event];
    self.eventBlock([self.events copy]);
  }
}

- (BOOL)isEventSupported:(id)event {
  @synchronized (self) {
    return self.eventFilter(event);
  }
}

- (NSArray *)eventsLogged {
  @synchronized (self) {
   return [self.events copy];
  }
}

@end

NS_ASSUME_NONNULL_END

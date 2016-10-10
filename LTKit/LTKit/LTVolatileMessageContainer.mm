// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "LTVolatileMessageContainer.h"

#import "LTBoundedQueue.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTVolatileMessageContainer ()

/// Queue to hold the most recent log entries.
@property (readonly, nonatomic) LTBoundedQueue *queue;

@end

@implementation LTVolatileMessageContainer

- (instancetype)initWithMaxNumberOfEntries:(NSUInteger)maxNumberOfEntries {
  if (self = [super init]) {
    _queue = [[LTBoundedQueue alloc] initWithMaximalCapacity:maxNumberOfEntries];
    _maxNumberOfEntries = maxNumberOfEntries;
  }
  return self;
}

- (void)addMessage:(NSString *)message {
  @synchronized (self.queue) {
    [self.queue pushObject:message];
  }
}

- (NSString *)messageLog {
  @synchronized (self.queue) {
    return [self.queue.array componentsJoinedByString:@"\n"];
  }
}

- (NSArray<NSString *> *)messages {
  @synchronized (self.queue) {
    return self.queue.array;
  }
}

@end

NS_ASSUME_NONNULL_END

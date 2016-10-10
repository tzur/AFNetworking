// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEventBusLoggerTarget.h"

#import "LTEventBus.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTLoggerEvent

- (instancetype)initWithMessage:(NSString *)message {
  if (self = [super init]) {
    _message = message;
  }
  return self;
}

@end

@interface LTEventBusLoggerTarget ()

/// Event bus to send events to.
@property (readonly, nonatomic) LTEventBus *eventBus;

@end

@implementation LTEventBusLoggerTarget

- (instancetype)initWithEventBus:(LTEventBus *)eventBus {
  if (self = [super init]) {
    _eventBus = eventBus;
  }
  return self;
}

#pragma mark -
#pragma mark LTLoggerTarget
#pragma mark -

- (void)outputString:(NSString *)message {
  [self.eventBus post:[[LTLoggerEvent alloc] initWithMessage:message]];
}

@end

NS_ASSUME_NONNULL_END

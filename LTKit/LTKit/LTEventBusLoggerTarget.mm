// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEventBusLoggerTarget.h"

#import "LTEventBus.h"
#import "NSDate+Formatting.h"

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

- (void)outputString:(NSString *)message file:(const char *)file line:(int)line
            logLevel:(LTLogLevel)logLevel {
  NSString *formattedMessage = [NSString stringWithFormat:@"%@ [%@] [%s:%d] %@",
                                [[NSDate date] lt_deviceTimezoneString],
                                NSStringFromLTLogLevel(logLevel),
                                file, line, message];
  [self.eventBus post:[[LTLoggerEvent alloc] initWithMessage:formattedMessage]];
}

@end

NS_ASSUME_NONNULL_END

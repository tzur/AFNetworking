// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "LTEventBusObserver.h"

#import "LTEventBus.h"
#import "LTMessageContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTEventBusObserver () <LTLoggerTarget>

/// Container that saves logs.
@property (readonly, nonatomic) id<LTMessageContainer> messageContainer;

/// Event classes to ignore. All events are logged except the ones that are listed in this array.
@property (readonly, nonatomic) NSSet<Class> *ignoredEventsClasses;

/// Event bus to be observed.
@property (readonly, nonatomic) LTEventBus *eventBus;

/// Date formatter for the date section of event logs.
@property (readonly, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation LTEventBusObserver

- (instancetype)initWithMessageContainer:(id<LTMessageContainer>)messageContainer
                                eventBus:(LTEventBus *)eventBus
                ignoredEventsClasses:(NSArray<Class> *)ignoredEventsClasses {
  if (self = [super init]) {
    _messageContainer = messageContainer;
    _ignoredEventsClasses = [NSSet setWithArray:ignoredEventsClasses];
    _dateFormatter = [self createDateFormatter];
    _eventBus = eventBus;

    [self startObserving];
  }
  return self;
}

- (NSDateFormatter *)createDateFormatter {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"yyyy:MM:dd:HH:mm:ss.SSS";
  dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
  return dateFormatter;
}

- (void)dealloc {
  [self.eventBus removeObserver:self forClass:NSObject.class];
}

#pragma mark -
#pragma mark EventBus
#pragma mark -

- (void)startObserving {
  [self.eventBus addObserver:self selector:@selector(handleEvent:) forClass:NSObject.class];
}

- (void)handleEvent:(NSObject *)event {
  if ([self.ignoredEventsClasses containsObject:event.class]) {
    return;
  }

  NSString *message = [NSString stringWithFormat:@"%@ [%@] %@",
                       [self.dateFormatter stringFromDate:[NSDate date]],
                       event.class, event.description];

  [self.messageContainer addMessage:message];
}

#pragma mark -
#pragma mark LTLoggerTarget
#pragma mark -

- (void)outputString:(NSString *)message {
  [self.messageContainer addMessage:message];
}

@end

NS_ASSUME_NONNULL_END

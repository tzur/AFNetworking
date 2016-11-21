// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "LTEventBusObserver.h"

#import "LTEventBus.h"
#import "LTMessageContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTEventBusObserver ()

/// Container that saves logs.
@property (readonly, nonatomic) id<LTMessageContainer> messageContainer;

/// Filter that returns \c NO on events that should not be saved.
@property (readonly, nonatomic) LTEventBusObserverFilterBlock eventFilter;

/// Event bus to be observed.
@property (readonly, nonatomic) LTEventBus *eventBus;

/// Date formatter for the date section of event logs.
@property (readonly, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation LTEventBusObserver

- (instancetype)initWithMessageContainer:(id<LTMessageContainer>)messageContainer
                                eventBus:(LTEventBus *)eventBus
                             eventFilter:(LTEventBusObserverFilterBlock)eventFilter {
  if (self = [super init]) {
    _messageContainer = messageContainer;
    _eventFilter = eventFilter;
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
  if (!self.eventFilter(event)) {
    return;
  }

  NSString *message = [NSString stringWithFormat:@"%@ [%@] %@",
                       [self.dateFormatter stringFromDate:[NSDate date]],
                       event.class, event.description];

  [self.messageContainer addMessage:message];
}

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "LTEventBusObserver.h"

#import "LTEventBus.h"
#import "LTMessageContainer.h"

@interface LTTestEvent : NSObject
@end

@implementation LTTestEvent

- (NSString *)description {
  return @"description";
}

@end

@interface LTAnotherTestEvent : NSObject
@end

@implementation LTAnotherTestEvent
@end

SpecBegin(LTEventBusObserver)

__block LTEventBusObserver *observer;

__block NSMutableArray<NSString *> *receivedLogs;
__block LTEventBus *eventBus;
__block id<LTMessageContainer> containerMock;

beforeEach(^{
  receivedLogs = [[NSMutableArray alloc] init];
  eventBus = [[LTEventBus alloc] init];

  containerMock = OCMProtocolMock(@protocol(LTMessageContainer));
  OCMStub([containerMock addMessage:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained NSString *log;
    [invocation getArgument:&log atIndex:2];
    [receivedLogs addObject:log];
  });

  observer = [[LTEventBusObserver alloc] initWithMessageContainer:containerMock eventBus:eventBus
                                             ignoredEventsClasses:@[LTAnotherTestEvent.class]];
});

it(@"should log a formatted event", ^{
  LTTestEvent *event = [[LTTestEvent alloc] init];
  [eventBus post:event];

  NSArray<NSString *> *separatedLog = [receivedLogs[0] componentsSeparatedByString:@" "];

  expect(separatedLog.count).to.equal(3);
  expect(separatedLog[1]).to.equal(
      [NSString stringWithFormat:@"[%@]", NSStringFromClass(LTTestEvent.class)]);
  expect(separatedLog[2]).to.equal(event.description);
});

it(@"should not log event of an ignored type", ^{
  LTAnotherTestEvent *event = [[LTAnotherTestEvent alloc] init];
  [eventBus post:event];

  expect(receivedLogs.count).to.equal(0);
});

SpecEnd

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEventBusLoggerTarget.h"

#import "LTEventBus.h"
#import "LTEventTarget.h"

SpecBegin(LTEventBusLoggerTarget)

__block LTEventBusLoggerTarget *target;

__block LTEventBus *eventBus;
__block LTEventTarget *eventTarget;

beforeEach(^{
  eventBus = [[LTEventBus alloc] init];
  eventTarget = [[LTEventTarget alloc] init];
  [eventBus addObserver:eventTarget selector:@selector(handleEvent:) forClass:NSObject.class];

  target = [[LTEventBusLoggerTarget alloc] initWithEventBus:eventBus];
});

it(@"should send event with message containing all info", ^{
  [target outputString:@"foo" file:"myFile.mm" line:1337 logLevel:LTLogLevelDebug];

  LTLoggerEvent *event = eventTarget.object;
  expect(event).to.beKindOf([LTLoggerEvent class]);
  expect(event.message).to.contain(@"foo");
  expect(event.message).to.contain(@"myFile.mm");
  expect(event.message).to.contain(@"1337");
});

it(@"should send event on each logger output", ^{
  [target outputString:@"foo" file:"myFile.mm" line:1337 logLevel:LTLogLevelDebug];
  [target outputString:@"bar" file:"myFile2.mm" line:1338 logLevel:LTLogLevelDebug];
  [target outputString:@"baz" file:"myFile3.mm" line:1339 logLevel:LTLogLevelDebug];

  expect(eventTarget.counter).to.equal(3);
});

SpecEnd

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

it(@"should send event with proper message", ^{
  [target outputString:@"foo"];

  LTLoggerEvent *event = eventTarget.object;
  expect(event).to.beKindOf([LTLoggerEvent class]);
  expect(event.message).to.equal(@"foo");
});

it(@"should send event on each logger output", ^{
  [target outputString:@"foo"];
  [target outputString:@"bar"];
  [target outputString:@"baz"];

  expect(eventTarget.counter).to.equal(3);
});

SpecEnd

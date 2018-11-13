// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTimer.h"

SpecBegin(LTTimer)

__block id timeProvider;

beforeEach(^{
  timeProvider = [OCMockObject mockForProtocol:@protocol(LTTimeIntervalProvider)];
});

it(@"should measure time correctly between start and stop", ^{
  [[[timeProvider expect] andReturnValue:@(0.0)] currentTime];
  [[[timeProvider expect] andReturnValue:@(1.0)] currentTime];

  LTTimer *timer = [[LTTimer alloc] initWithTimeProvider:timeProvider];

  [timer start];
  expect([timer stop]).to.equal(1);
  OCMVerifyAll(timeProvider);
});

it(@"should measure time correctly between start and splits", ^{
  [[[timeProvider expect] andReturnValue:@(0.0)] currentTime];
  [[[timeProvider expect] andReturnValue:@(1.0)] currentTime];
  [[[timeProvider expect] andReturnValue:@(2.0)] currentTime];

  LTTimer *timer = [[LTTimer alloc] initWithTimeProvider:timeProvider];

  [timer start];
  expect([timer split]).to.equal(1);
  expect([timer split]).to.equal(1);
  OCMVerifyAll(timeProvider);
});

it(@"should measure time correctly with start, split and stop", ^{
  [[[timeProvider expect] andReturnValue:@(0.0)] currentTime];
  [[[timeProvider expect] andReturnValue:@(1.0)] currentTime];
  [[[timeProvider expect] andReturnValue:@(2.0)] currentTime];

  LTTimer *timer = [[LTTimer alloc] initWithTimeProvider:timeProvider];

  [timer start];
  expect([timer split]).to.equal(1);
  expect([timer stop]).to.equal(2);
  OCMVerifyAll(timeProvider);
});

SpecEnd

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAloomaLogger.h"

#import <Alooma-iOS/Alooma.h>
#import <LTKit/NSArray+NSSet.h>

#import "NSUUID+Zero.h"

SpecBegin(INTAloomaLogger)

__block Alooma *alooma;
__block INTAloomaLogger *logger;

beforeEach(^{
  alooma = OCMClassMock(Alooma.class);
  logger = [[INTAloomaLogger alloc] initWithAlooma:alooma
                                 whitelistedEvents:[@[@"foo", @"bar"] lt_set]];
});

context(@"serialization error event", ^{
  it(@"should return a serializable event", ^{
    auto event = INTAloomaJSONSerializationErrorEvent(@{@"event": @"bar", @"foo": [NSUUID UUID]});
    expect([NSJSONSerialization isValidJSONObject:event]).to.beTruthy();
  });

  it(@"should return a serializable event in case of nil identifier for vendor", ^{
    UIDevice *device = OCMClassMock(UIDevice.class);
    auto event =
        INTAloomaJSONSerializationErrorEvent(@{@"event": @"bar", @"foo": [NSUUID UUID]}, device);
    expect([NSJSONSerialization isValidJSONObject:event]).to.beTruthy();
  });
});

it(@"should log dictionaries with the event key to Alooma", ^{
  [logger logEvent:@{@"event": @"bar"}];

  OCMVerify([alooma trackCustomEvent:@{@"event": @"bar"}]);
});

it(@"should accept only dictionaries with the event key with string value", ^{
  expect([logger isEventSupported:@{@"event": @"bar"}]).to.beTruthy();
  expect([logger isEventSupported:@{}]).to.beFalsy();
  expect([logger isEventSupported:@"foo"]).to.beFalsy();
  expect([logger isEventSupported:@{@"event": @1}]).to.beFalsy();
});

it(@"should replace non json serializable events with error event", ^{
  auto event = @{@"event": @"foo", @"bar": [NSUUID UUID]};
  [logger logEvent:event];

  OCMVerify([alooma trackCustomEvent:INTAloomaJSONSerializationErrorEvent(event)]);
});

it(@"should resume supporting non mandatory events", ^{
  auto nonWhitelistedEvents1 = @{@"event": @"baz"};
  OCMReject([alooma trackCustomEvent:nonWhitelistedEvents1]);
  logger.shouldWhitelistEvents = YES;

  [logger logEvent:@{@"event": @"foo"}];
  OCMVerify([alooma trackCustomEvent:@{@"event": @"foo"}]);
  [logger logEvent:@{@"event": @"bar"}];
  OCMVerify([alooma trackCustomEvent:@{@"event": @"bar"}]);
  [logger logEvent:nonWhitelistedEvents1];

  logger.shouldWhitelistEvents = NO;
  [logger logEvent:@{@"event": @"foo"}];
  OCMVerify([alooma trackCustomEvent:@{@"event": @"foo"}]);
  [logger logEvent:@{@"event": @"bar"}];
  OCMVerify([alooma trackCustomEvent:@{@"event": @"bar"}]);
  auto nonWhitelistedEvents2 = @{@"event": @"baz", @"bob": @"flop"};
  [logger logEvent:nonWhitelistedEvents2];
  OCMVerify([alooma trackCustomEvent:nonWhitelistedEvents2]);
});

it(@"should have default NO value for shouldWhitelistEvents", ^{
  expect(logger.shouldWhitelistEvents).to.beFalsy();
});

SpecEnd

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAloomaLogger.h"

#import <Alooma-iOS/Alooma.h>

SpecBegin(INTAloomaLogger)

__block Alooma *alooma;
__block INTAloomaLogger *logger;

beforeEach(^{
  alooma = OCMClassMock(Alooma.class);
  logger = [[INTAloomaLogger alloc] initWithAlooma:alooma];
});

it(@"should log dictionaries with the event key to Alooma", ^{
  [logger logEvent:@{@"event": @"bar"}];

  OCMVerify([alooma trackCustomEvent:@{@"event": @"bar"}]);
});

it(@"should accept only dictionaries with the event key", ^{
  expect([logger isEventSupported:@{@"event": @"bar"}]).to.beTruthy();
  expect([logger isEventSupported:@{}]).to.beFalsy();
  expect([logger isEventSupported:@"foo"]).to.beFalsy();
});

SpecEnd

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAloomaLogger.h"

#import <Alooma-iOS/Alooma.h>

#import "INTFakeAnalytricksEvent.h"

SpecBegin(INTAloomaLogger)

__block Alooma *alooma;
__block INTAloomaLogger *logger;

beforeEach(^{
  alooma = OCMClassMock(Alooma.class);
  logger = [[INTAloomaLogger alloc] initWithAlooma:alooma];
});

it(@"should log INTAnalytricsEvent to Alooma", ^{
  auto event = [[INTFakeAnalytricksEvent alloc] initWithProperties:@{@"foo": @"bar"}];
  [logger logEvent:event];

  OCMVerify([alooma trackCustomEvent:@{@"foo": @"bar"}]);
});

it(@"should accept INTAnalytricksEvent", ^{
  auto event = [[INTFakeAnalytricksEvent alloc] initWithProperties:@{}];
  expect([logger isEventSupported:event]).to.beTruthy();
});

SpecEnd

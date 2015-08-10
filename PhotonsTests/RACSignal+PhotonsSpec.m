// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "RACSignal+Photons.h"

SpecBegin(RACSignal_Photons)

__block RACSubject *subject;
__block RACSignal *lastLazily;

beforeEach(^{
  subject = [RACReplaySubject subject];
  lastLazily = [[subject ptn_replayLastLazily] startCountingSubscriptions];
});

it(@"should not subscribe to signal", ^{
  expect(lastLazily).to.beSubscribedTo(0);
});

it(@"should replay a single value", ^{
  [subject sendNext:@1];
  [subject sendNext:@2];
  [subject sendNext:@3];

  expect(lastLazily).to.sendValues(@[@3]);
  expect(lastLazily).to.beSubscribedTo(1);
});

SpecEnd

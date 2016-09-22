// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRTimeProvider.h"

SpecBegin(BZRTimeProvider)

__block BZRTimeProvider *timeProvider;

beforeEach(^{
  timeProvider = [[BZRTimeProvider alloc] init];
});

it(@"should send a single value and complete", ^{
  LLSignalTestRecorder *recorder = [[timeProvider currentTime] testRecorder];

  expect(recorder).will.complete();
  expect(recorder).to.sendValuesWithCount(1);
});

SpecEnd

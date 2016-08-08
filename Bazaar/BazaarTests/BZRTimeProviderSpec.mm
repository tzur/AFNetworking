// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRTimeProvider.h"

SpecBegin(BZRTimeProvider)

__block BZRTimeProvider *timeProvider;

beforeEach(^{
  timeProvider = [[BZRTimeProvider alloc] init];
});

context(@"verifying current time", ^{
  LLSignalTestRecorder *recorder = [[timeProvider currentTime] testRecorder];

  expect(recorder).will.complete();
  expect(recorder).will.sendValuesWithCount(1);
});

SpecEnd

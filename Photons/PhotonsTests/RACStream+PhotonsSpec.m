// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "RACStream+Photons.h"

SpecBegin(RACStream_Photons)

it(@"should return identical objects until change", ^{
  RACSubject *subject = [RACSubject subject];
  RACSignal *filtered = [subject ptn_identicallyDistinctUntilChanged];

  LLSignalTestRecorder *recorder = [LLSignalTestRecorder recordWithSignal:filtered];
  NSMutableArray *value = [NSMutableArray arrayWithObject:@7];

  [subject sendNext:value];
  [subject sendNext:value];
  [subject sendNext:@7];
  [subject sendNext:value];
  [subject sendNext:[value copy]];

  expect(recorder.values).to.equal(@[value, @7, value, value]);
});

SpecEnd

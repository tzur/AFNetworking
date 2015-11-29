// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "RACSignal+Photons.h"

SpecBegin(RACSignal_Photons)

context(@"ptn_replayLastLazily", ^{
  __block RACSubject *subject;
  __block RACSignal *lastLazily;
  
  beforeEach(^{
    subject = [RACSubject subject];
    lastLazily = [[subject ptn_replayLastLazily] startCountingSubscriptions];
  });
  
  it(@"should not subscribe to signal", ^{
    expect(lastLazily).to.beSubscribedTo(0);
  });
  
  it(@"should pass through all values sent after subscription", ^{
    LLSignalTestRecorder *recorder = [lastLazily testRecorder];
    
    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject sendNext:@3];

    expect(recorder.values).to.equal(@[@1, @2, @3]);
  });
  
  it(@"should replay only the last value sent to late subscribers", ^{
    [lastLazily subscribeNext:^(id __unused x) {}];

    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject sendNext:@3];
    LLSignalTestRecorder *recorder = [lastLazily testRecorder];
    
    expect(recorder.values).to.equal(@[@3]);
  });
  
  it(@"should replay last value and pass through all future values sent to late subscribers", ^{
    [lastLazily subscribeNext:^(id __unused x) {}];


    [subject sendNext:@1];
    [subject sendNext:@2];
    LLSignalTestRecorder *recorder = [lastLazily testRecorder];
    [subject sendNext:@3];
    
    expect(recorder.values).to.equal(@[@2, @3]);
  });
  
  it(@"should continue to operate regularly after reaching zero subscribers", ^{
    RACDisposable *earlySubscriber = [lastLazily subscribeNext:^(id __unused x) {}];
    
    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject sendNext:@3];
    
    expect(lastLazily).to.beSubscribedTo(1);
    [earlySubscriber dispose];
    LLSignalTestRecorder *recorder = [lastLazily testRecorder];
    expect(recorder.values).to.equal(@[@3]);
  });
});

SpecEnd

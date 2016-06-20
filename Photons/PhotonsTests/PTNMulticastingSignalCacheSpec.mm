// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNMulticastingSignalCache.h"

SpecBegin(PTNMulticastingSignalCache)

__block PTNMulticastingSignalCache *cache;
__block NSURL *url;
__block RACSubject *subject;
__block RACSignal *signal;
__block BOOL wasDisposed;

context(@"RACReplaySubjectUnlimitedCapacity", ^{
  beforeEach(^{
    wasDisposed = NO;
    cache = [[PTNMulticastingSignalCache alloc] initWithReplayCapacity:RACReplaySubjectUnlimitedCapacity];
    url = [NSURL URLWithString:@"foo"];
    subject = [RACSubject subject];
    signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
      [subject subscribe:subscriber];

      return [RACDisposable disposableWithBlock:^{
        wasDisposed = YES;
      }];
    }] startCountingSubscriptions];
  });

  it(@"should store and retrieve multicasted signals", ^{
    [cache storeSignal:signal forURL:url];
    [subject sendNext:@"foo"];
    expect([cache signalForURL:url]).to.sendValues(@[@"foo"]);
    expect([cache signalForURL:url]).to.sendValues(@[@"foo"]);
    expect([cache signalForURL:url]).to.sendValues(@[@"foo"]);
    expect(signal.subscriptionCount).to.equal(1);
    expect(wasDisposed).to.beFalsy();
  });

  it(@"should store and remove signals", ^{
    [cache storeSignal:signal forURL:url];
    [cache removeSignalForURL:url];
    expect([cache signalForURL:url]).to.beNil();
  });

  it(@"should dispose signals when removing them", ^{
    [cache storeSignal:signal forURL:url];
    expect(wasDisposed).to.beFalsy();

    [subject sendNext:@"foo"];
    expect([cache signalForURL:url]).to.sendValues(@[@"foo"]);

    [cache removeSignalForURL:url];
    expect([cache signalForURL:url]).to.beNil();
    expect(wasDisposed).to.beTruthy();
  });

  it(@"should dispose signals when assigning new signals to their urls", ^{
    [cache storeSignal:signal forURL:url];
    expect(wasDisposed).to.beFalsy();

    [subject sendNext:@"foo"];
    expect([cache signalForURL:url]).to.sendValues(@[@"foo"]);

    [cache storeSignal:[RACSignal return:@"bar"] forURL:url];
    expect([cache signalForURL:url]).to.sendValues(@[@"bar"]);
    expect(wasDisposed).to.beTruthy();
  });

  it(@"should store and retrieve multicasted signals with subscript", ^{
    cache[url] = signal;
    [subject sendNext:@"foo"];
    expect(cache[url]).will.sendValues(@[@"foo"]);
  });

  it(@"should store and remove signals with subscript", ^{
    cache[url] = signal;
    cache[url] = nil;
    expect(cache[url]).to.beNil();
    expect(wasDisposed).to.beTruthy();
  });
});

SpecEnd

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNSignalCache.h"

SpecBegin(PTNSignalCacheSpec)

__block PTNSignalCache *cache;
__block NSURL *url;
__block RACSignal *signal;

beforeEach(^{
  cache = [[PTNSignalCache alloc] init];
  url = [NSURL URLWithString:@"foo"];
  signal = [RACSignal empty];
});

it(@"should store and retrieve signals", ^{
  [cache storeSignal:signal forURL:url];
  expect([cache signalForURL:url]).to.equal(signal);
});

it(@"should store and remove signals", ^{
  [cache storeSignal:signal forURL:url];
  [cache removeSignalForURL:url];
  expect([cache signalForURL:url]).to.beNil();
});

it(@"should store and retrieve signals with subscript", ^{
  cache[url] = signal;
  expect(cache[url]).to.equal(signal);
});

it(@"should store and remove signals with subscript", ^{
  cache[url] = signal;
  cache[url] = nil;
  expect(cache[url]).to.beNil();
});

SpecEnd

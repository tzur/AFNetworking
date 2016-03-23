// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+PTNCache.h"

SpecBegin(NSURL_PTNCache)

it(@"should append cache policy to URL without query", ^{
  NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];

  PTNCachePolicy *policy = [PTNCachePolicy enumWithValue:PTNCachePolicyReturnCacheDataElseLoad];
  NSURL *urlWithPolicy = [url ptn_cacheURLWithCachePolicy:policy];
  expect(urlWithPolicy.ptn_cacheCachePolicy.value).to.equal(PTNCachePolicyReturnCacheDataElseLoad);
});

it(@"should append cache policy to URL with query", ^{
  NSURL *url = [NSURL URLWithString:@"http://www.foo.com?baz=gaz&gaz=qux"];

  PTNCachePolicy *policy = [PTNCachePolicy enumWithValue:PTNCachePolicyReturnCacheDataElseLoad];
  NSURL *urlWithPolicy = [url ptn_cacheURLWithCachePolicy:policy];
  expect(urlWithPolicy.ptn_cacheCachePolicy.value).to.equal(PTNCachePolicyReturnCacheDataElseLoad);
});

it(@"should overwrite cache policy of URL with existing cache policy query", ^{
  NSURL *url = [NSURL URLWithString:@"http://www.foo.com?baz=gaz&gaz=qux"];

  PTNCachePolicy *policy = [PTNCachePolicy enumWithValue:PTNCachePolicyReturnCacheDataElseLoad];
  NSURL *urlWithPolicy = [url ptn_cacheURLWithCachePolicy:policy];

  PTNCachePolicy *newPolicy =
      [PTNCachePolicy enumWithValue:PTNCachePolicyReloadIgnoringLocalCacheData];
  NSURL *urlWithOtherPolicy = [urlWithPolicy ptn_cacheURLWithCachePolicy:newPolicy];
  expect(urlWithOtherPolicy.ptn_cacheCachePolicy.value)
      .to.equal(PTNCachePolicyReloadIgnoringLocalCacheData);
});

it(@"should return default cache policy to an unaltered URL", ^{
  NSURL *url = [NSURL URLWithString:@"http://www.foo.com?baz=gaz&gaz=qux"];

  expect(url.ptn_cacheCachePolicy.value).to.equal(PTNCachePolicyDefault);
});

SpecEnd

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+PTNCache.h"

#import <LTKit/NSURL+Query.h>

SpecBegin(NSURL_PTNCache)

__block NSURL *url;
__block NSURL *urlWithQuery;

beforeEach(^{
  url = [NSURL URLWithString:@"http://www.foo.com"];
  urlWithQuery = [NSURL URLWithString:@"http://www.foo.com?baz=gaz&gaz=qux"];
});

it(@"should append cache policy to URL without query", ^{
  PTNCachePolicy *policy = [PTNCachePolicy enumWithValue:PTNCachePolicyReturnCacheDataElseLoad];
  NSURL *urlWithPolicy = [url ptn_cacheURLWithCachePolicy:policy];

  expect(urlWithPolicy.ptn_cacheCachePolicy.value).to.equal(PTNCachePolicyReturnCacheDataElseLoad);
});

it(@"should append cache policy to URL with query", ^{
  PTNCachePolicy *policy = [PTNCachePolicy enumWithValue:PTNCachePolicyReturnCacheDataElseLoad];
  NSURL *urlWithPolicy = [urlWithQuery ptn_cacheURLWithCachePolicy:policy];

  expect(urlWithPolicy.ptn_cacheCachePolicy.value).to.equal(PTNCachePolicyReturnCacheDataElseLoad);
});

it(@"should overwrite cache policy of URL with existing cache policy query", ^{
  PTNCachePolicy *policy = [PTNCachePolicy enumWithValue:PTNCachePolicyReturnCacheDataElseLoad];
  NSURL *urlWithPolicy = [urlWithQuery ptn_cacheURLWithCachePolicy:policy];
  PTNCachePolicy *newPolicy =
      [PTNCachePolicy enumWithValue:PTNCachePolicyReloadIgnoringLocalCacheData];
  NSURL *urlWithOtherPolicy = [urlWithPolicy ptn_cacheURLWithCachePolicy:newPolicy];

  expect(urlWithOtherPolicy.ptn_cacheCachePolicy.value)
      .to.equal(PTNCachePolicyReloadIgnoringLocalCacheData);
});

it(@"should return default cache policy to an unaltered URL", ^{
  expect(urlWithQuery.ptn_cacheCachePolicy.value).to.equal(PTNCachePolicyDefault);
});

it(@"should strip cache policy from URL", ^{
  PTNCachePolicy *policy = [PTNCachePolicy enumWithValue:PTNCachePolicyReturnCacheDataElseLoad];
  NSURL *urlWithPolicy = [url ptn_cacheURLWithCachePolicy:policy];

  expect([urlWithPolicy ptn_cacheURLByStrippingCachePolicy]).to.equal(url);
});

it(@"should strip cache policy from URL with query", ^{
  PTNCachePolicy *policy = [PTNCachePolicy enumWithValue:PTNCachePolicyReturnCacheDataElseLoad];
  NSURL *urlWithPolicy = [urlWithQuery ptn_cacheURLWithCachePolicy:policy];

  expect([urlWithPolicy ptn_cacheURLByStrippingCachePolicy]).to.equal(urlWithQuery);
});

it(@"should not alter a URL without cache policy query when stripping cache policy", ^{
  expect([url ptn_cacheURLByStrippingCachePolicy]).to.equal(url);
  expect([urlWithQuery ptn_cacheURLByStrippingCachePolicy]).to.equal(urlWithQuery);
});

SpecEnd

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURLCache+Photons.h"

#import "PTNCacheFakeNSURLCache.h"
#import "PTNCacheResponse.h"

SpecBegin(NSURLCache_Photons)

__block PTNCacheFakeNSURLCache *cache;
__block NSData *data;
__block NSURL *url;
__block NSDictionary *info;
__block PTNCacheResponse *cacheResponse;

beforeEach(^{
  cache = [[PTNCacheFakeNSURLCache alloc] init];
  data = [[NSData alloc] init];
  url = [NSURL URLWithString:@"http://www.foo.com"];
  info = @{@"foo": @"bar"};
  cacheResponse = [[PTNCacheResponse alloc] initWithData:data info:info];
});

it(@"should store and retrieve data and info", ^{
  [cache storeData:data withInfo:info forURL:url];
  expect([cache cachedDataForURL:url]).to.sendValues(@[cacheResponse]);
});

it(@"should store and retrieve info without data", ^{
  [cache storeInfo:info forURL:url];

  PTNCacheResponse *nilDataResponse = [[PTNCacheResponse alloc] initWithData:[NSData data]
                                                                        info:info];
  expect([cache cachedDataForURL:url]).to.sendValues(@[nilDataResponse]);
});

it(@"should clear data from cache", ^{
  [cache storeData:data withInfo:info forURL:url];
  expect([cache cachedDataForURL:url]).to.sendValues(@[cacheResponse]);
  expect(cache.storage.count).toNot.equal(0);

  [cache clearCache];
  expect([cache cachedDataForURL:url]).to.sendValues(@[[NSNull null]]);
  expect(cache.storage.count).to.equal(0);
});

it(@"should allow disk storage when storing data and info", ^{
  [cache storeData:data withInfo:info forURL:url];
  expect(cache.storage.allValues.firstObject.storagePolicy).to.equal(NSURLCacheStorageAllowed);
});

it(@"shouldn not allow disk storage when storing just info", ^{
  [cache storeInfo:info forURL:url];
  expect(cache.storage.allValues.firstObject.storagePolicy)
      .to.equal(NSURLCacheStorageAllowedInMemoryOnly);
});

SpecEnd

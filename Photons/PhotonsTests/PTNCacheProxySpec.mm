// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheProxy.h"

#import <LTKit/LTRandomAccessCollection.h>

#import "PTNAlbum.h"
#import "PTNCacheInfo.h"
#import "PTNTestUtils.h"

SpecBegin(PTNCacheProxy)

__block PTNCacheProxy *proxy;
__block NSURL *url;
__block NSArray *subalbums;
__block NSArray *assets;
__block id<PTNAlbum> underlyingObject;
__block PTNCacheInfo *cacheInfo;

beforeEach(^{
  url = [NSURL URLWithString:@"http://www.foo.com"];
  subalbums = @[@"foo", @"bar"];
  assets = @[@"baz", @"gaz"];
  underlyingObject = PTNCreateAlbum(url, assets, subalbums);
  cacheInfo = OCMClassMock([PTNCacheInfo class]);

  proxy = [[PTNCacheProxy alloc] initWithUnderlyingObject:underlyingObject cacheInfo:cacheInfo];
});

it(@"should initialize with underlying object and cache info", ^{
  expect(proxy.underlyingObject).to.equal(underlyingObject);
  expect(proxy.cacheInfo).to.equal(cacheInfo);
});

it(@"should proxy underlying object methods to underlying object", ^{
  expect(((id<PTNAlbum>)proxy).url).to.equal(url);
  expect(((id<PTNAlbum>)proxy).subalbums).to.equal(subalbums);
  expect(((id<PTNAlbum>)proxy).assets).to.equal(assets);
});

it(@"should conform to protocols conformed by the underlying object", ^{
  expect(proxy).to.conformTo(@protocol(PTNAlbum));
});

it(@"should respond to selectors supported by underlying object", ^{
  expect(proxy).to.respondTo(@selector(url));
  expect(proxy).to.respondTo(@selector(subalbums));
  expect(proxy).to.respondTo(@selector(assets));
});

it(@"should not respond to selectors not supported by underlying object or the proxy", ^{
  expect(proxy).toNot.respondTo(@selector(stringWithFormat:));
  expect(proxy).toNot.respondTo(@selector(count));
  expect(proxy).toNot.respondTo(@selector(readFromURL:options:error:));
});

it(@"should handle methods not implemented by forwarding to super", ^{
  expect(^{
    [(NSString *)proxy stringByAppendingString:@"foo"];
  }).to.raise(NSInvalidArgumentException);
});

context(@"equality", ^{
  __block PTNCacheProxy *firstProxy;
  __block PTNCacheProxy *secondProxy;
  __block PTNCacheProxy *otherProxy;

  beforeEach(^{
    firstProxy = [[PTNCacheProxy alloc] initWithUnderlyingObject:underlyingObject
                                                       cacheInfo:cacheInfo];
    secondProxy = [[PTNCacheProxy alloc] initWithUnderlyingObject:underlyingObject
                                                        cacheInfo:cacheInfo];
    otherProxy = [[PTNCacheProxy alloc] initWithUnderlyingObject:underlyingObject
        cacheInfo:OCMClassMock([PTNCacheInfo class])];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstProxy).to.equal(secondProxy);
    expect(secondProxy).to.equal(firstProxy);
    expect(firstProxy).toNot.equal(otherProxy);
    expect(secondProxy).toNot.equal(otherProxy);
  });

  it(@"should create proper hash", ^{
    expect(firstProxy.hash).to.equal(secondProxy.hash);
  });
});

SpecEnd

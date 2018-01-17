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

context(@"proxy", ^{
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

  it(@"should proxy the underlying object class and superclass", ^{
    expect(proxy.class).to.equal(underlyingObject.class);
    expect(proxy.superclass).to.equal(underlyingObject.superclass);
  });

  it(@"should proxy class queries", ^{
    expect([proxy isKindOfClass:underlyingObject.class]).to.beTruthy();
    expect([proxy isMemberOfClass:underlyingObject.class]).to.beTruthy();
  });

  it(@"should be kind of PTNCacheProxy", ^{
    expect([proxy isKindOfClass:PTNCacheProxy.class]).to.beTruthy();
    expect([proxy isMemberOfClass:PTNCacheProxy.class]).to.beTruthy();
  });
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

  it(@"should be equal to proxies with same underlying object and cache info", ^{
    expect(firstProxy).to.equal(secondProxy);
    expect(secondProxy).to.equal(firstProxy);
    expect(firstProxy).toNot.equal(otherProxy);
    expect(secondProxy).toNot.equal(otherProxy);
  });

  it(@"should be equal to objects that are equal to its underlying object", ^{
    id<PTNAlbum> secondUnderlyingObject = PTNCreateAlbum(url, @[@"foo"], subalbums);

    expect(firstProxy).to.equal(underlyingObject);
    expect(underlyingObject).to.equal(firstProxy);
    expect(secondUnderlyingObject).toNot.equal(firstProxy);
    expect(firstProxy).toNot.equal(secondUnderlyingObject);
    expect(@"foo").toNot.equal(firstProxy);
    expect(firstProxy).toNot.equal(@"foo");
  });

  it(@"should proxy hash", ^{
    expect(firstProxy.hash).to.equal(underlyingObject.hash);

    id<PTNAlbum> otherObject = PTNCreateAlbum([NSURL URLWithString:@"http://www.bar.com"], assets,
                                              subalbums);
    PTNCacheProxy *otherHash = [[PTNCacheProxy alloc] initWithUnderlyingObject:otherObject
                                cacheInfo:OCMClassMock([PTNCacheInfo class])];

    expect(firstProxy.hash).toNot.equal(otherHash.hash);
  });
});

SpecEnd

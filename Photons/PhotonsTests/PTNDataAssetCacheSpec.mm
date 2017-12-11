// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDataAssetCache.h"

#import <LTKit/LTRandomAccessCollection.h>

#import "PTNAlbum.h"
#import "PTNCacheInfo.h"
#import "PTNDataAsset.h"
#import "PTNDataBackedImageAsset.h"
#import "PTNDescriptor.h"
#import "PTNFakeDataCache.h"
#import "PTNResizingStrategy.h"
#import "PTNTestUtils.h"

SpecBegin(PTNDataAssetCache)

__block PTNFakeDataCache *underlyingCache;
__block PTNDataAssetCache *cache;
__block NSURL *url;
__block PTNCacheInfo *cacheInfo;
__block NSError *defaultError;

beforeEach(^{
  underlyingCache = [[PTNFakeDataCache alloc] init];
  cache = [[PTNDataAssetCache alloc] initWithCache:underlyingCache];
  url = [NSURL URLWithString:@"http://www.foo.com"];
  cacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:1337 entityTag:@"foo"];
  defaultError = [NSError lt_errorWithCode:1337];
});

context(@"albums", ^{
  __block id<PTNAlbum> album;

  beforeEach(^{
    NSArray *assets = @[@"foo", @"bar"];
    NSArray *subalbums = @[@"baz", @"qux"];
    album = PTNCreateAlbum(url, assets, subalbums);
  });

  it(@"should store and fetch albums", ^{
    [cache storeAlbum:album withCacheInfo:cacheInfo forURL:url];

    PTNCacheResponse *response = [[PTNCacheResponse alloc] initWithData:album info:cacheInfo];
    expect([cache cachedAlbumForURL:url]).will.sendValues(@[response]);
  });

  it(@"should return nil for uncached albums", ^{
    expect([cache cachedAlbumForURL:url]).will.sendValues(@[[NSNull null]]);
  });

  it(@"should forward errors from underlying cache", ^{
    [underlyingCache registerError:defaultError forURL:url];

    expect([cache cachedAlbumForURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == 1337;
    });
  });
});

context(@"descriptors", ^{
  __block id<PTNDescriptor> descriptor;

  beforeEach(^{
    descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
  });

  it(@"should store and fetch descriptors", ^{
    [cache storeDescriptor:descriptor withCacheInfo:cacheInfo forURL:url];

    PTNCacheResponse *response = [[PTNCacheResponse alloc] initWithData:descriptor info:cacheInfo];
    expect([cache cachedDescriptorForURL:url]).will.sendValues(@[response]);
  });

  it(@"should return nil for uncached albums", ^{
    expect([cache cachedAlbumForURL:url]).will.sendValues(@[[NSNull null]]);
  });

  it(@"should forward errors from underlying cache", ^{
    [underlyingCache registerError:defaultError forURL:url];

    expect([cache cachedDescriptorForURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == 1337;
    });
  });
});

context(@"image assets", ^{
  __block id<PTNDataAsset> imageAsset;
  __block NSData *data;
  __block id<PTNResizingStrategy> resizingStrategy;

  beforeEach(^{
    uint8_t buffer[] = { 0x1, 0x2, 0x3, 0x4 };
    data = [NSData dataWithBytes:buffer length:sizeof(buffer)];
    imageAsset = OCMProtocolMock(@protocol(PTNDataAsset));
    OCMStub([imageAsset fetchData]).andReturn([RACSignal return:data]);
    resizingStrategy = OCMProtocolMock(@protocol(PTNResizingStrategy));
  });

  it(@"should store and fetch image assets", ^{
    [cache storeImageAsset:imageAsset withCacheInfo:cacheInfo forURL:url];

    PTNDataBackedImageAsset *responseAsset = [[PTNDataBackedImageAsset alloc] initWithData:data
        resizingStrategy:resizingStrategy];
    PTNCacheResponse *response = [[PTNCacheResponse alloc] initWithData:responseAsset
                                                                   info:cacheInfo];

    expect([cache cachedImageAssetForURL:url resizingStrategy:resizingStrategy])
        .will.sendValues(@[response]);
  });

  it(@"should store and fetch image assets resized with resizing strategy", ^{
    [cache storeImageAsset:imageAsset withCacheInfo:cacheInfo forURL:url];

    id<PTNResizingStrategy> otherResizingStrategy = OCMProtocolMock(@protocol(PTNResizingStrategy));

    PTNDataBackedImageAsset *responseAsset = [[PTNDataBackedImageAsset alloc] initWithData:data
        resizingStrategy:otherResizingStrategy];
    PTNCacheResponse *response = [[PTNCacheResponse alloc] initWithData:responseAsset
                                                                   info:cacheInfo];

    expect([cache cachedImageAssetForURL:url resizingStrategy:otherResizingStrategy])
        .will.sendValues(@[response]);
  });

  it(@"should return nil for uncached image assets", ^{
    expect([cache cachedImageAssetForURL:url resizingStrategy:resizingStrategy])
        .will.sendValues(@[[NSNull null]]);
  });

  it(@"should forward errors from underlying cache", ^{
    [underlyingCache registerError:defaultError forURL:url];

    expect([cache cachedImageAssetForURL:url resizingStrategy:resizingStrategy])
        .will.matchError(^BOOL(NSError *error) {
          return error.code == 1337;
    });
  });

  context(@"mixed assets", ^{
    __block id<PTNResizingStrategy> resizingStrategy;
    __block id<PTNDescriptor> descriptor;
    __block id<PTNAlbum> album;
    __block id<PTNDataAsset> imageAsset;
    __block NSData *data;

    beforeEach(^{
      resizingStrategy = OCMProtocolMock(@protocol(PTNResizingStrategy));
      descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
      NSArray *assets = @[@"foo", @"bar"];
      NSArray *subalbums = @[@"baz", @"qux"];
      album = PTNCreateAlbum(url, assets, subalbums);
      uint8_t buffer[] = { 0x1, 0x2, 0x3, 0x4 };
      data = [NSData dataWithBytes:buffer length:sizeof(buffer)];
      imageAsset = OCMProtocolMock(@protocol(PTNDataAsset));
      OCMStub([imageAsset fetchData]).andReturn([RACSignal return:data]);
      resizingStrategy = OCMProtocolMock(@protocol(PTNResizingStrategy));
    });

    it(@"should not crash when image is fetched on the same URL descriptor is cached", ^{
      [cache storeDescriptor:descriptor withCacheInfo:cacheInfo forURL:url];

      expect([cache cachedImageAssetForURL:url resizingStrategy:resizingStrategy])
          .will.complete();
    });

    it(@"should not crash when image is fetched on the same URL album is cached", ^{
      [cache storeAlbum:album withCacheInfo:cacheInfo forURL:url];

      expect([cache cachedImageAssetForURL:url resizingStrategy:resizingStrategy])
          .will.complete();
    });

    it(@"should not crash when album is fetched on the same URL descriptor is cached", ^{
      [cache storeDescriptor:descriptor withCacheInfo:cacheInfo forURL:url];

      expect([cache cachedAlbumForURL:url]).will.complete();
    });

    it(@"should not crash when album is fetched on the same URL image is cached", ^{
      [cache storeImageAsset:imageAsset withCacheInfo:cacheInfo forURL:url];

      expect([cache cachedAlbumForURL:url]).will.complete();
    });

    it(@"should not crash when descriptor is fetched on the same URL image is cached", ^{
      [cache storeImageAsset:imageAsset withCacheInfo:cacheInfo forURL:url];

      expect([cache cachedDescriptorForURL:url]).will.complete();
    });

    it(@"should not crash when descriptor is fetched on the same URL album is cached", ^{
      [cache storeAlbum:album withCacheInfo:cacheInfo forURL:url];

      expect([cache cachedDescriptorForURL:url]).will.complete();
    });
  });
});

SpecEnd

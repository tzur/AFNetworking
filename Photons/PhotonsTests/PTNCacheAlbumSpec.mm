// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheAlbum.h"

#import "PTNCacheInfo.h"
#import "PTNCollection.h"
#import "PTNTestUtils.h"

SpecBegin(PTNCacheAlbum)

__block NSURL *url;
__block NSArray *subalbums;
__block NSArray *assets;
__block id<PTNAlbum> underlyingAlbum;
__block PTNCacheInfo *cacheInfo;

beforeEach(^{
  url = [NSURL URLWithString:@"http://www.foo.com"];
  subalbums = @[@"foo", @"bar"];
  assets = @[@"baz", @"gaz"];
  underlyingAlbum = PTNCreateAlbum(url, assets, subalbums);
  cacheInfo = OCMClassMock([PTNCacheInfo class]);
});

it(@"should initialize with underlying album and cache info", ^{
  PTNCacheAlbum *album = [PTNCacheAlbum cacheAlbumWithUnderlyingAlbum:underlyingAlbum
                                                            cacheInfo:cacheInfo];

  expect(album.underlyingAlbum).to.equal(underlyingAlbum);
  expect(album.cacheInfo).to.equal(cacheInfo);
});

it(@"should proxy album methods to underlying album", ^{
  PTNCacheAlbum *album = [PTNCacheAlbum cacheAlbumWithUnderlyingAlbum:underlyingAlbum
                                                            cacheInfo:cacheInfo];

  expect(album.url).to.equal(url);
  expect(album.subalbums).to.equal(subalbums);
  expect(album.assets).to.equal(assets);
});

context(@"equality", ^{
  __block PTNCacheAlbum *firstAlbum;
  __block PTNCacheAlbum *secondAlbum;

  beforeEach(^{
    firstAlbum = [PTNCacheAlbum cacheAlbumWithUnderlyingAlbum:underlyingAlbum
                                                    cacheInfo:cacheInfo];
    secondAlbum = [PTNCacheAlbum cacheAlbumWithUnderlyingAlbum:underlyingAlbum
                                                     cacheInfo:cacheInfo];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstAlbum).to.equal(secondAlbum);
    expect(secondAlbum).to.equal(firstAlbum);
  });

  it(@"should create proper hash", ^{
    expect(firstAlbum.hash).to.equal(secondAlbum.hash);
  });
});

SpecEnd

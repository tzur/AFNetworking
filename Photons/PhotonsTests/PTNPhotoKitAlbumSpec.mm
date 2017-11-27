// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAlbum.h"

#import <LTKit/LTRandomAccessCollection.h>
#import <Photos/Photos.h>

#import "NSURL+PhotoKit.h"

SpecBegin(PTNPhotoKitAlbum)

it(@"should initialize with url and assets fetch result", ^{
  id assetCollection = OCMClassMock([PHAssetCollection class]);
  OCMStub([assetCollection localIdentifier]).andReturn(@"foo");
  NSURL *url = [NSURL ptn_photoKitAlbumURLWithCollection:assetCollection];

  id fetchResult = OCMClassMock([PHFetchResult class]);

  PTNPhotoKitAlbum *album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:fetchResult];

  expect(album.url).to.equal(url);
  expect(album.assets).to.equal(fetchResult);
  expect(album.subalbums.count).to.equal(0);
  expect(album.subalbums).notTo.equal(fetchResult);
  expect(album.nextAlbumURL).to.beNil();
});

it(@"should initialize with url and subalbums fetch result", ^{
  NSURL *url = [NSURL ptn_photoKitSmartAlbums];

  id fetchResult = OCMClassMock([PHFetchResult class]);

  PTNPhotoKitAlbum *album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:fetchResult];

  expect(album.url).to.equal(url);
  expect(album.assets.count).to.equal(0);
  expect(album.assets).notTo.equal(fetchResult);
  expect(album.subalbums).to.equal(fetchResult);
  expect(album.nextAlbumURL).to.beNil();
});

SpecEnd

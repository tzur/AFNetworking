// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSURL+PhotoKit.h"

#import <Photos/Photos.h>

SpecBegin(NSURL_PhotoKit)

it(@"should return valid asset URL", ^{
  id asset = OCMClassMock([PHAsset class]);
  OCMStub([asset localIdentifier]).andReturn(@"foo");

  NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
  expect(url.ptn_photoKitURLType).to.equal(PTNPhotoKitURLTypeAsset);
  expect(url.ptn_photoKitAssetIdentifier).to.equal(@"foo");
});

it(@"should return valid album URL", ^{
  id collection = OCMClassMock([PHCollection class]);
  OCMStub([collection localIdentifier]).andReturn(@"foo");

  NSURL *url = [NSURL ptn_photoKitAlbumURLWithCollection:collection];
  expect(url.ptn_photoKitURLType).to.equal(PTNPhotoKitURLTypeAlbum);
  expect(url.ptn_photoKitAlbumIdentifier).to.equal(@"foo");
});

it(@"should return valid album type URL", ^{
  NSURL *url = [NSURL ptn_photoKitAlbumWithType:PTNPhotoKitAlbumTypeCameraRoll];
  expect(url.ptn_photoKitURLType).to.equal(PTNPhotoKitURLTypeAlbumType);
  expect(url.ptn_photoKitAlbumType).to.equal(PTNPhotoKitAlbumTypeCameraRoll);
  expect(url.ptn_photoKitAlbumOfAlbumsType).to.equal(PTNPhotoKitAlbumOfAlbumsTypeInvalid);
});

it(@"should return valid album of albums type URL", ^{
  NSURL *url = [NSURL ptn_photoKitAlbumOfAlbumsWithType:PTNPhotoKitAlbumOfAlbumsTypeSmartAlbums];
  expect(url.ptn_photoKitURLType).to.equal(PTNPhotoKitURLTypeAlbumOfAlbumsType);
  expect(url.ptn_photoKitAlbumType).to.equal(PTNPhotoKitAlbumTypeInvalid);
  expect(url.ptn_photoKitAlbumOfAlbumsType).to.equal(PTNPhotoKitAlbumOfAlbumsTypeSmartAlbums);
});

SpecEnd

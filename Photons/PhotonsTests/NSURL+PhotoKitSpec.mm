// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSURL+PhotoKit.h"

#import <Photos/Photos.h>

SpecBegin(NSURL_PhotoKit)

it(@"should return valid asset URL", ^{
  id asset = OCMClassMock([PHAsset class]);
  OCMStub([asset localIdentifier]).andReturn(@"foo");

  NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
  expect(url.ptn_photoKitURLType.value).to.equal(PTNPhotoKitURLTypeAsset);
  expect(url.ptn_photoKitAssetIdentifier).to.equal(@"foo");
});

it(@"should return valid album URL", ^{
  id collection = OCMClassMock([PHCollection class]);
  OCMStub([collection localIdentifier]).andReturn(@"foo");

  NSURL *url = [NSURL ptn_photoKitAlbumURLWithCollection:collection];
  expect(url.ptn_photoKitURLType.value).to.equal(PTNPhotoKitURLTypeAlbum);
  expect(url.ptn_photoKitAlbumIdentifier).to.equal(@"foo");
});

it(@"should return valid album type URL", ^{
  PTNPhotoKitAlbumType *type = $(PTNPhotoKitAlbumTypeCameraRoll);
  NSURL *url = [NSURL ptn_photoKitAlbumWithType:type];
  expect(url.ptn_photoKitURLType.value).to.equal(PTNPhotoKitURLTypeAlbumType);
  expect(url.ptn_photoKitAlbumType.value).to.equal(PTNPhotoKitAlbumTypeCameraRoll);
  expect(url.ptn_photoKitMetaAlbumType).to.beNil();
});

it(@"should return valid meta album type URL", ^{
  PTNPhotoKitMetaAlbumType *type = $(PTNPhotoKitMetaAlbumTypeSmartAlbums);
  NSURL *url = [NSURL ptn_photoKitMetaAlbumWithType:type];
  expect(url.ptn_photoKitURLType.value).to.equal(PTNPhotoKitURLTypeMetaAlbumType);
  expect(url.ptn_photoKitAlbumType).to.beNil();
  expect(url.ptn_photoKitMetaAlbumType.value).to.equal(PTNPhotoKitMetaAlbumTypeSmartAlbums);
});

SpecEnd

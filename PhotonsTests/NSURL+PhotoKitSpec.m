// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSURL+PhotoKit.h"

#import "PTNPhotoKitAlbumType.h"

@import Photos;

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
  PTNPhotoKitAlbumType *type = [PTNPhotoKitAlbumType
                                albumTypeWithType:PHAssetCollectionTypeAlbum
                                subtype:PHAssetCollectionSubtypeSmartAlbumVideos];

  NSURL *url = [NSURL ptn_photoKitAlbumsWithType:type];
  expect(url.ptn_photoKitURLType).to.equal(PTNPhotoKitURLTypeAlbumType);
  expect(url.ptn_photoKitAlbumType).to.equal(type);
});

SpecEnd

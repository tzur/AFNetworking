// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSURL+PhotoKit.h"

#import <Photos/Photos.h>

SpecBegin(NSURL_PhotoKit)

it(@"should return valid object placeholder URL", ^{
  id objectPlaceholder = OCMClassMock([PHObjectPlaceholder class]);
  OCMStub([objectPlaceholder localIdentifier]).andReturn(@"foo");

  NSURL *url = [NSURL ptn_photoKitAssetURLWithObjectPlaceholder:objectPlaceholder];
  expect(url.ptn_photoKitURLType.value).to.equal(PTNPhotoKitURLTypeAsset);
  expect(url.ptn_photoKitAssetIdentifier).to.equal(@"foo");
  expect(url.ptn_photoKitAlbumType).to.beNil();
  expect(url.ptn_photoKitAlbumSubtype).to.beNil();
  expect(url.ptn_photoKitAlbumSubalbums).to.beNil();
  expect(url.ptn_photoKitAlbumFetchOptions).to.beNil();
});

it(@"should return valid asset URL", ^{
  id asset = OCMClassMock([PHAsset class]);
  OCMStub([asset localIdentifier]).andReturn(@"foo");

  NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
  expect(url.ptn_photoKitURLType.value).to.equal(PTNPhotoKitURLTypeAsset);
  expect(url.ptn_photoKitAssetIdentifier).to.equal(@"foo");
  expect(url.ptn_photoKitAlbumType).to.beNil();
  expect(url.ptn_photoKitAlbumSubtype).to.beNil();
  expect(url.ptn_photoKitAlbumSubalbums).to.beNil();
  expect(url.ptn_photoKitAlbumFetchOptions).to.beNil();
});

it(@"should return valid album URL", ^{
  id collection = OCMClassMock([PHCollection class]);
  OCMStub([collection localIdentifier]).andReturn(@"foo");

  NSURL *url = [NSURL ptn_photoKitAlbumURLWithCollection:collection];
  expect(url.ptn_photoKitURLType.value).to.equal(PTNPhotoKitURLTypeAlbum);
  expect(url.ptn_photoKitAlbumIdentifier).to.equal(@"foo");
  expect(url.ptn_photoKitAlbumType).to.beNil();
  expect(url.ptn_photoKitAlbumSubtype).to.beNil();
  expect(url.ptn_photoKitAlbumSubalbums).to.beNil();
  expect(url.ptn_photoKitAlbumFetchOptions).to.beNil();
});

it(@"should return valid album type URL", ^{
  NSURL *url = [NSURL ptn_photoKitAlbumWithType:PHAssetCollectionTypeSmartAlbum
                                        subtype:PHAssetCollectionSubtypeSmartAlbumSlomoVideos];
  expect(url.ptn_photoKitURLType.value).to.equal(PTNPhotoKitURLTypeAlbumType);
  expect(url.ptn_photoKitAlbumType).to.equal(@(PHAssetCollectionTypeSmartAlbum));
  expect(url.ptn_photoKitAlbumSubtype).to.equal(@(PHAssetCollectionSubtypeSmartAlbumSlomoVideos));
  expect(url.ptn_photoKitAlbumSubalbums).to.beNil();
  expect(url.ptn_photoKitAlbumIdentifier).to.beNil();
  expect(url.ptn_photoKitAssetIdentifier).to.beNil();
  expect(url.ptn_photoKitAlbumFetchOptions).to.beNil();
});

it(@"should return valid meta album type URL", ^{
  NSArray<NSNumber *> *subalbums = @[
    @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos),
    @(PHAssetCollectionSubtypeAlbumCloudShared)
  ];
  std::vector<PHAssetCollectionSubtype> subalbumVector = {
    PHAssetCollectionSubtypeSmartAlbumSlomoVideos,
    PHAssetCollectionSubtypeAlbumCloudShared
  };
  NSURL *url = [NSURL ptn_photoKitMetaAlbumWithType:PHAssetCollectionTypeSmartAlbum
                                      subalbums:subalbumVector];
  expect(url.ptn_photoKitURLType.value).to.equal(PTNPhotoKitURLTypeMetaAlbumType);
  expect(url.ptn_photoKitAlbumType).to.equal(@(PHAssetCollectionTypeSmartAlbum));
  expect(url.ptn_photoKitAlbumSubtype).to.equal(@(PHAssetCollectionSubtypeAny));
  expect(url.ptn_photoKitAlbumSubalbums).to.equal(subalbums);
  expect(url.ptn_photoKitAlbumIdentifier).to.beNil();
  expect(url.ptn_photoKitAssetIdentifier).to.beNil();
  expect(url.ptn_photoKitAlbumFetchOptions).to.beNil();
});

it(@"should filter subalbums even if subalbums set is empty", ^{
  NSURL *url = [NSURL ptn_photoKitMetaAlbumWithType:PHAssetCollectionTypeSmartAlbum
                                          subalbums:{}];
  expect(url.ptn_photoKitURLType.value).to.equal(PTNPhotoKitURLTypeMetaAlbumType);
  expect(url.ptn_photoKitAlbumType).to.equal(@(PHAssetCollectionTypeSmartAlbum));
  expect(url.ptn_photoKitAlbumSubtype).to.equal(@(PHAssetCollectionSubtypeAny));
  expect(url.ptn_photoKitAlbumSubalbums).to.equal(@[]);
  expect(url.ptn_photoKitAlbumIdentifier).to.beNil();
  expect(url.ptn_photoKitAssetIdentifier).to.beNil();
  expect(url.ptn_photoKitAlbumFetchOptions).to.beNil();
});

it(@"should return correct predicate for user albums with title filter", ^{
  NSURL *url = [NSURL ptn_photoKitUserAlbumsWithTitle:@"foo"];
  expect(url.ptn_photoKitURLType.value).to.equal(PTNPhotoKitURLTypeMetaAlbumType);
  expect(url.ptn_photoKitAlbumType).to.equal(@(PHAssetCollectionTypeAlbum));
  expect(url.ptn_photoKitAlbumSubtype).to.equal(@(PHAssetCollectionSubtypeAny));
  expect(url.ptn_photoKitAlbumSubalbums).to.beNil();
  expect(url.ptn_photoKitAlbumIdentifier).to.beNil();
  expect(url.ptn_photoKitAssetIdentifier).to.beNil();

  PHFetchOptions *options = url.ptn_photoKitAlbumFetchOptions;
  expect(options.predicate).to.equal([NSPredicate predicateWithFormat:@"title=%@", @"foo"]);
});

it(@"should handle query invalid predicates", ^{
  NSURL *url = [NSURL ptn_photoKitUserAlbumsWithTitle:@"foo? bar, &baz"];
  expect(url.ptn_photoKitURLType.value).to.equal(PTNPhotoKitURLTypeMetaAlbumType);
  expect(url.ptn_photoKitAlbumType).to.equal(@(PHAssetCollectionTypeAlbum));
  expect(url.ptn_photoKitAlbumSubtype).to.equal(@(PHAssetCollectionSubtypeAny));
  expect(url.ptn_photoKitAlbumSubalbums).to.beNil();
  expect(url.ptn_photoKitAlbumIdentifier).to.beNil();
  expect(url.ptn_photoKitAssetIdentifier).to.beNil();

  PHFetchOptions *options = url.ptn_photoKitAlbumFetchOptions;
  expect(options.predicate).to.equal([NSPredicate predicateWithFormat:@"title=%@",
                                      @"foo? bar, &baz"]);
});

SpecEnd

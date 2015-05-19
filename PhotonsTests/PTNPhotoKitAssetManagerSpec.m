// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAssetManager.h"

@import Photos;

#import "NSError+Photons.h"
#import "NSURL+PhotoKit.h"
#import "PTNPhotoKitAlbum.h"
#import "PTNPhotoKitAlbumType.h"
#import "PTNPhotoKitFetcher.h"
#import "PTNPhotoKitObserver.h"

SpecBegin(PTNPhotoKitAssetManager)

__block PTNPhotoKitAssetManager *manager;

__block id fetcher;
__block id observer;

beforeEach(^{
  fetcher = OCMClassMock([PTNPhotoKitFetcher class]);
  observer = OCMClassMock([PTNPhotoKitObserver class]);

  manager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher observer:observer];
});

context(@"fetching album by identifier", ^{
  __block id assets;
  __block NSURL *url;

  beforeEach(^{
    id assetCollection = OCMClassMock([PHAssetCollection class]);
    OCMStub([assetCollection localIdentifier]).andReturn(@"foo");

    NSArray *identifiers = @[@"foo"];
    NSArray *assetCollections = @[assetCollection];
    OCMStub([fetcher fetchAssetCollectionsWithLocalIdentifiers:identifiers options:nil]).
        andReturn(assetCollections);

    id firstAsset = OCMClassMock([PHAsset class]);
    id secondAsset = OCMClassMock([PHAsset class]);
    assets = @[firstAsset, secondAsset];
    OCMStub([fetcher fetchAssetsInAssetCollection:assetCollection options:nil]).andReturn(assets);

    url = [NSURL ptn_photoKitAlbumURLWithCollection:assetCollection];
  });

  context(@"initial value", ^{
    it(@"should fetch initial results of an album", ^{
      OCMStub([observer photoLibraryChanged]).andReturn([RACSignal empty]);

      RACSignal *albumSignal = [manager fetchAlbumWithURL:url];

      id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithAssets:assets];
      expect(albumSignal).will.sendValues(@[album]);
    });
  });

  context(@"updates", ^{
    __block id<PTNAlbum> firstAlbum;
    __block id<PTNAlbum> secondAlbum;

    beforeEach(^{
      id asset = OCMClassMock([PHAsset class]);
      id newAssets = @[asset];

      id changeDetails = OCMClassMock([PHFetchResultChangeDetails class]);
      OCMStub([changeDetails fetchResultAfterChanges]).andReturn(newAssets);

      id change = OCMClassMock([PHChange class]);
      OCMStub([change changeDetailsForFetchResult:OCMOCK_ANY]).andReturn(changeDetails);
      OCMStub([observer photoLibraryChanged]).andReturn([RACSignal return:change]);

      firstAlbum = [[PTNPhotoKitAlbum alloc] initWithAssets:assets];
      secondAlbum = [[PTNPhotoKitAlbum alloc] initWithAssets:newAssets];
    });

    it(@"should send new album upon update", ^{
      expect([manager fetchAlbumWithURL:url]).will.sendValues(@[firstAlbum, secondAlbum]);
    });

    it(@"should send latest album when album observation is already in place", ^{
      RACSignal *albumSignal = [manager fetchAlbumWithURL:url];

      // Trigger first fetch and wait until two values are returned.
      expect(albumSignal).will.sendValues(@[firstAlbum, secondAlbum]);

      expect([manager fetchAlbumWithURL:url]).will.sendValues(@[secondAlbum]);
    });

    it(@"should send latest album after all signals have been destroyed", ^{
      @autoreleasepool {
        RACSignal *albumSignal = [manager fetchAlbumWithURL:url];

        // Trigger first fetch and wait until two values are returned.
        expect(albumSignal).will.sendValues(@[firstAlbum, secondAlbum]);
      }

      expect([manager fetchAlbumWithURL:url]).will.sendValues(@[secondAlbum]);
    });
  });
});

context(@"fetching album by type", ^{
  __block id albums;
  __block NSURL *url;

  beforeEach(^{
    id firstCollection = OCMClassMock([PHAssetCollection class]);
    id secondCollection = OCMClassMock([PHAssetCollection class]);
    albums = @[firstCollection, secondCollection];

    OCMStub([fetcher fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                           subtype:PHAssetCollectionSubtypeAny
                                           options:nil]).
        andReturn(albums);

    PTNPhotoKitAlbumType *type = [PTNPhotoKitAlbumType
                                  albumTypeWithType:PHAssetCollectionTypeAlbum
                                  subtype:PHAssetCollectionSubtypeAny];
    url = [NSURL ptn_photoKitAlbumsWithType:type];
  });

  context(@"initial value", ^{
    it(@"should fetch initial results of an album", ^{
      OCMStub([observer photoLibraryChanged]).andReturn([RACSignal empty]);

      RACSignal *albumSignal = [manager fetchAlbumWithURL:url];

      id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithAlbums:albums];
      expect(albumSignal).will.sendValues(@[album]);
    });
  });

  context(@"updates", ^{
    __block id<PTNAlbum> firstAlbum;
    __block id<PTNAlbum> secondAlbum;

    beforeEach(^{
      id firstCollection = OCMClassMock([PHAssetCollection class]);
      id secondCollection = OCMClassMock([PHAssetCollection class]);
      id newAlbums = @[firstCollection, secondCollection];

      id changeDetails = OCMClassMock([PHFetchResultChangeDetails class]);
      OCMStub([changeDetails fetchResultAfterChanges]).andReturn(newAlbums);

      id change = OCMClassMock([PHChange class]);
      OCMStub([change changeDetailsForFetchResult:OCMOCK_ANY]).andReturn(changeDetails);
      OCMStub([observer photoLibraryChanged]).andReturn([RACSignal return:change]);

      firstAlbum = [[PTNPhotoKitAlbum alloc] initWithAlbums:albums];
      secondAlbum = [[PTNPhotoKitAlbum alloc] initWithAlbums:newAlbums];
    });

    it(@"should send new album upon update", ^{
      expect([manager fetchAlbumWithURL:url]).will.sendValues(@[firstAlbum, secondAlbum]);
    });
  });
});

context(@"fetching errors", ^{
  beforeEach(^{
    OCMStub([observer photoLibraryChanged]).andReturn([RACSignal empty]);
  });

  it(@"should error on invalid URL", ^{
    NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];
    
    expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  it(@"should error on non existing album", ^{
    id assetCollection = OCMClassMock([PHAssetCollection class]);
    OCMStub([assetCollection localIdentifier]).andReturn(@"foo");

    NSURL *url = [NSURL ptn_photoKitAlbumURLWithCollection:assetCollection];

    expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAlbumNotFound;
    });
  });
});

SpecEnd

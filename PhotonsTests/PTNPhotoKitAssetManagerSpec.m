// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAssetManager.h"

#import <Photos/Photos.h>

#import "NSError+Photons.h"
#import "NSURL+PhotoKit.h"
#import "PTNAlbumChangeset+PhotoKit.h"
#import "PTNPhotoKitAlbum.h"
#import "PTNPhotoKitAlbumType.h"
#import "PTNPhotoKitFakeImageManager.h"
#import "PTNPhotoKitImageManager.h"
#import "PTNPhotoKitFetcher.h"
#import "PTNPhotoKitObserver.h"

SpecBegin(PTNPhotoKitAssetManager)

__block PTNPhotoKitAssetManager *manager;

__block id fetcher;
__block id observer;
__block id imageManager;

beforeEach(^{
  fetcher = OCMClassMock([PTNPhotoKitFetcher class]);
  observer = OCMClassMock([PTNPhotoKitObserver class]);
  imageManager = [[PTNPhotoKitFakeImageManager alloc] init];

  manager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher observer:observer
                                                imageManager:imageManager];
});

context(@"album fetching", ^{
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
      beforeEach(^{
        OCMStub([observer photoLibraryChanged]).andReturn([RACSignal empty]);
      });

      it(@"should fetch initial results of an album", ^{
        RACSignal *albumSignal = [manager fetchAlbumWithURL:url];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:assets];
        expect(albumSignal).will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:album]]);
      });

      it(@"should fetch initial value again if there was an error on the first fetch", ^{
        id otherAssetCollection = OCMClassMock([PHAssetCollection class]);
        OCMStub([otherAssetCollection localIdentifier]).andReturn(@"bar");

        NSURL *otherURL = [NSURL ptn_photoKitAlbumURLWithCollection:otherAssetCollection];
        expect([manager fetchAlbumWithURL:otherURL]).will.error();

        NSArray *identifiers = @[@"bar"];
        NSArray *assetCollections = @[otherAssetCollection];
        OCMStub([fetcher fetchAssetCollectionsWithLocalIdentifiers:identifiers options:nil]).
            andReturn(assetCollections);
        OCMStub([fetcher fetchAssetsInAssetCollection:otherAssetCollection options:nil]).
            andReturn(assets);

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:otherURL fetchResult:assets];
        expect([manager fetchAlbumWithURL:otherURL]).will.sendValues(@[
          [PTNAlbumChangeset changesetWithAfterAlbum:album]
        ]);
      });
    });

    context(@"updates", ^{
      __block id<PTNAlbum> firstAlbum;
      __block id<PTNAlbum> secondAlbum;

      __block id change;
      __block id changeDetails;
      __block RACSubject *changeSignal;

      beforeEach(^{
        id asset = OCMClassMock([PHAsset class]);
        id newAssets = @[asset];

        changeDetails = OCMClassMock([PHFetchResultChangeDetails class]);
        OCMStub([changeDetails fetchResultAfterChanges]).andReturn(newAssets);

        change = OCMClassMock([PHChange class]);
        OCMStub([change changeDetailsForFetchResult:OCMOCK_ANY]).andReturn(changeDetails);

        changeSignal = [RACReplaySubject subject];
        OCMStub([observer photoLibraryChanged]).andReturn(changeSignal);

        firstAlbum = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:assets];
        secondAlbum = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:newAssets];
      });

      it(@"should send new album upon update", ^{
        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [changeSignal sendNext:change];

        expect(recorder.values).will.equal(@[
          [PTNAlbumChangeset changesetWithAfterAlbum:firstAlbum],
          [PTNAlbumChangeset changesetWithURL:url photoKitChangeDetails:changeDetails]
        ]);
      });

      it(@"should send latest album when album observation is already in place", ^{
        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [changeSignal sendNext:change];

        // Trigger first fetch and wait until two values are returned.
        expect(recorder.values).will.equal(@[
          [PTNAlbumChangeset changesetWithAfterAlbum:firstAlbum],
          [PTNAlbumChangeset changesetWithURL:url photoKitChangeDetails:changeDetails]
        ]);

        expect([manager fetchAlbumWithURL:url]).will.sendValues(@[
          [PTNAlbumChangeset changesetWithAfterAlbum:secondAlbum],
        ]);
      });

      it(@"should send latest album after all signals have been destroyed", ^{
        @autoreleasepool {
          LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
          [changeSignal sendNext:change];

          // Trigger first fetch and wait until two values are returned.
          expect(recorder.values).will.equal(@[
            [PTNAlbumChangeset changesetWithAfterAlbum:firstAlbum],
            [PTNAlbumChangeset changesetWithURL:url photoKitChangeDetails:changeDetails]
          ]);
        }

        expect([manager fetchAlbumWithURL:url]).will.sendValues(@[
          [PTNAlbumChangeset changesetWithAfterAlbum:secondAlbum]
        ]);
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

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:albums];
        expect(albumSignal).will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:album]]);
      });
    });

    context(@"updates", ^{
      __block id<PTNAlbum> firstAlbum;
      __block id<PTNAlbum> secondAlbum;

      __block id change;
      __block id changeDetails;
      __block RACSubject *changeSignal;

      beforeEach(^{
        id firstCollection = OCMClassMock([PHAssetCollection class]);
        id secondCollection = OCMClassMock([PHAssetCollection class]);
        id newAlbums = @[firstCollection, secondCollection];

        changeDetails = OCMClassMock([PHFetchResultChangeDetails class]);
        OCMStub([changeDetails fetchResultAfterChanges]).andReturn(newAlbums);

        change = OCMClassMock([PHChange class]);
        OCMStub([change changeDetailsForFetchResult:OCMOCK_ANY]).andReturn(changeDetails);

        changeSignal = [RACReplaySubject subject];
        OCMStub([observer photoLibraryChanged]).andReturn(changeSignal);

        firstAlbum = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:albums];
        secondAlbum = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:newAlbums];
      });

      it(@"should send new album upon update", ^{
        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [changeSignal sendNext:change];

        expect(recorder.values).will.equal(@[
          [PTNAlbumChangeset changesetWithAfterAlbum:firstAlbum],
          [PTNAlbumChangeset changesetWithURL:url photoKitChangeDetails:changeDetails]
        ]);
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
});

context(@"asset fetching", ^{
  __block id asset;

  beforeEach(^{
    asset = OCMClassMock([PHAsset class]);
    OCMStub([asset localIdentifier]).andReturn(@"foo");

    OCMStub([fetcher fetchAssetsWithLocalIdentifiers:@[@"foo"] options:nil]).andReturn(@[asset]);
  });

  it(@"should fetch asset with URL", ^{
    OCMStub([observer photoLibraryChanged]).andReturn([RACSignal empty]);

    NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
    expect([manager fetchAssetWithURL:url]).will.sendValues(@[asset]);
  });

  it(@"should send new asset upon update", ^{
    id newAsset = OCMClassMock([PHAsset class]);

    id changeDetails = OCMClassMock([PHObjectChangeDetails class]);
    OCMStub([changeDetails objectAfterChanges]).andReturn(newAsset);

    id change = OCMClassMock([PHChange class]);
    OCMStub([change changeDetailsForObject:OCMOCK_ANY]).andReturn(changeDetails);

    RACSubject *changeSignal = [RACReplaySubject subject];
    OCMStub([observer photoLibraryChanged]).andReturn(changeSignal);

    NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
    LLSignalTestRecorder *recorder = [[manager fetchAssetWithURL:url] testRecorder];

    [changeSignal sendNext:change];

    expect(recorder).will.sendValues(@[asset, newAsset]);
  });

  it(@"should error on non-existing asset", ^{
    id newAsset = OCMClassMock([PHAsset class]);
    OCMStub([newAsset localIdentifier]).andReturn(@"bar");

    OCMStub([fetcher fetchAssetsWithLocalIdentifiers:@[@"bar"] options:nil]).andReturn(@[]);
    OCMStub([observer photoLibraryChanged]).andReturn([RACSignal empty]);

    NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:newAsset];
    expect([manager fetchAssetWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetNotFound;
    });
  });

  it(@"should error on non-asset URL", ^{
    PTNPhotoKitAlbumType *type = [PTNPhotoKitAlbumType
                                  albumTypeWithType:PHAssetCollectionTypeAlbum
                                  subtype:PHAssetCollectionSubtypeAny];
    NSURL *url = [NSURL ptn_photoKitAlbumsWithType:type];

    expect([manager fetchAssetWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  it(@"should error on invalid URL", ^{
    NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];

    expect([manager fetchAssetWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });
});

context(@"image fetching", ^{
  __block id asset;

  __block CGSize size;
  __block PTNImageFetchOptions *options;

  __block UIImage *image;

  __block NSError *defaultError;

  beforeEach(^{
    asset = OCMClassMock([PHAsset class]);
    OCMStub([asset localIdentifier]).andReturn(@"foo");
    OCMStub([fetcher fetchAssetsWithLocalIdentifiers:@[@"foo"] options:nil]).andReturn(@[asset]);

    size = CGSizeMake(64, 64);
    options = [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeFast
                                                 resizeMode:PTNImageResizeModeFast];

    image = [[UIImage alloc] init];

    defaultError = [NSError errorWithDomain:@"foo" code:1337 userInfo:nil];
  });

  context(@"fetch image of asset with URL", ^{
    __block NSURL *url;

    beforeEach(^{
      url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
    });

    it(@"should fetch image with URL", ^{
      [imageManager serveAsset:asset withProgress:@[] image:image];

      expect([manager fetchImageWithURL:url targetSize:size
                            contentMode:PTNImageContentModeAspectFill
                                options:options]).will.sendValues(@[
        [[PTNProgress alloc] initWithResult:image]
      ]);
    });

    it(@"should fetch downloaded image with URL", ^{
      [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] image:image];

      expect([manager fetchImageWithURL:url targetSize:size
                            contentMode:PTNImageContentModeAspectFill
                                options:options]).will.sendValues(@[
        [[PTNProgress alloc] initWithProgress:@0.25],
        [[PTNProgress alloc] initWithProgress:@0.5],
        [[PTNProgress alloc] initWithProgress:@1],
        [[PTNProgress alloc] initWithResult:image]
      ]);
    });

    it(@"should cancel request upon disposal", ^{
      RACSignal *values = [manager fetchImageWithURL:url targetSize:size
                                         contentMode:PTNImageContentModeAspectFill
                                             options:options];

      [[values subscribeNext:^(id __unused x) {}] dispose];

      expect([imageManager isRequestCancelledForAsset:asset]).to.beTruthy();
    });

    it(@"should error on download error", ^{
      [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] finallyError:defaultError];

      RACSignal *values = [manager fetchImageWithURL:url targetSize:size
                                         contentMode:PTNImageContentModeAspectFill
                                             options:options];

      expect(values).will.sendValues(@[
        [[PTNProgress alloc] initWithProgress:@0.25],
        [[PTNProgress alloc] initWithProgress:@0.5],
        [[PTNProgress alloc] initWithProgress:@1],
      ]);

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetLoadingFailed &&
            [error.userInfo[NSUnderlyingErrorKey] isEqual:defaultError];
      });
    });

    it(@"should error on progress download error", ^{
      [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] errorInProgress:defaultError];

      RACSignal *values = [manager fetchImageWithURL:url targetSize:size
                                         contentMode:PTNImageContentModeAspectFill
                                             options:options];

      expect(values).will.sendValues(@[
        [[PTNProgress alloc] initWithProgress:@0.25],
        [[PTNProgress alloc] initWithProgress:@0.5]
      ]);

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetLoadingFailed &&
            [error.userInfo[NSUnderlyingErrorKey] isEqual:defaultError];
      });
    });

    it(@"should error on non-existing asset", ^{
      id unknownAsset = OCMClassMock([PHAsset class]);
      OCMStub([unknownAsset localIdentifier]).andReturn(@"bar");

      url = [NSURL ptn_photoKitAssetURLWithAsset:unknownAsset];

      [imageManager serveAsset:unknownAsset withProgress:@[@0.25, @0.5, @1]
               errorInProgress:defaultError];

      RACSignal *values = [manager fetchImageWithURL:url targetSize:size
                                         contentMode:PTNImageContentModeAspectFill
                                             options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetNotFound;
      });
    });
  });

  context(@"fetch image of asset collection with URL", ^{
    __block id assetCollection;
    __block NSURL *url;

    beforeEach(^{
      assetCollection = OCMClassMock([PHAssetCollection class]);
      OCMStub([assetCollection localIdentifier]).andReturn(@"foo");

      url = [NSURL ptn_photoKitAlbumURLWithCollection:assetCollection];

      OCMStub([fetcher fetchAssetCollectionsWithLocalIdentifiers:@[@"foo"] options:nil]).
          andReturn(@[assetCollection]);
    });

    it(@"should fetch asset collection representative image", ^{
      OCMStub([fetcher fetchKeyAssetsInAssetCollection:assetCollection options:nil]).
          andReturn(@[asset]);

      [imageManager serveAsset:asset withProgress:@[] image:image];

      expect([manager fetchImageWithURL:url targetSize:size
                            contentMode:PTNImageContentModeAspectFill
                                options:options]).will.sendValues(@[
        [[PTNProgress alloc] initWithResult:image]
      ]);
    });

    it(@"should error on non-existing asset collection", ^{
      id assetCollection = OCMClassMock([PHAssetCollection class]);
      OCMStub([assetCollection localIdentifier]).andReturn(@"bar");

      url = [NSURL ptn_photoKitAlbumURLWithCollection:assetCollection];

      RACSignal *values = [manager fetchImageWithURL:url targetSize:size
                                         contentMode:PTNImageContentModeAspectFill
                                             options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAlbumNotFound;
      });
    });

    it(@"should error on non-existing key assets", ^{
      RACSignal *values = [manager fetchImageWithURL:url targetSize:size
                                         contentMode:PTNImageContentModeAspectFill
                                             options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeKeyAssetsNotFound;
      });
    });

    it(@"should error on non-existing key asset", ^{
      OCMStub([fetcher fetchKeyAssetsInAssetCollection:assetCollection options:nil]).
          andReturn(@[asset]);

      RACSignal *values = [manager fetchImageWithURL:url targetSize:size
                                         contentMode:PTNImageContentModeAspectFill
                                             options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetLoadingFailed;
      });
    });
  });

  it(@"should error on bad URL type", ^{
    PTNPhotoKitAlbumType *type = [PTNPhotoKitAlbumType
                                  albumTypeWithType:PHAssetCollectionTypeAlbum
                                  subtype:PHAssetCollectionSubtypeAny];
    NSURL *url = [NSURL ptn_photoKitAlbumsWithType:type];

    expect([manager fetchImageWithURL:url targetSize:size
                          contentMode:PTNImageContentModeAspectFill
                              options:options]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  it(@"should error on invalid URL", ^{
    NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];

    expect([manager fetchImageWithURL:url targetSize:size
                          contentMode:PTNImageContentModeAspectFill
                              options:options]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });
});

SpecEnd

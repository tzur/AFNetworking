// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAssetManager.h"

#import <Photos/Photos.h>

#import "NSError+Photons.h"
#import "NSURL+PhotoKit.h"
#import "PTNAlbumChangeset+PhotoKit.h"
#import "PTNPhotoKitAlbum.h"
#import "PTNPhotoKitAlbumType.h"
#import "PTNPhotoKitFakeFetcher.h"
#import "PTNPhotoKitFakeImageManager.h"
#import "PTNPhotoKitFakeObserver.h"
#import "PTNPhotoKitImageManager.h"
#import "PTNPhotoKitTestUtils.h"

SpecBegin(PTNPhotoKitAssetManager)

__block PTNPhotoKitAssetManager *manager;

__block PTNPhotoKitFakeFetcher *fetcher;
__block PTNPhotoKitFakeObserver *observer;
__block PTNPhotoKitFakeImageManager *imageManager;

beforeEach(^{
  fetcher = [[PTNPhotoKitFakeFetcher alloc] init];
  observer = [[PTNPhotoKitFakeObserver alloc] init];
  imageManager = [[PTNPhotoKitFakeImageManager alloc] init];

  manager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher observer:observer
                                                imageManager:imageManager];
});

context(@"album fetching", ^{
  context(@"fetching album by identifier", ^{
    __block id assets;
    __block NSURL *url;

    beforeEach(^{
      id assetCollection = PTNPhotoKitCreateAssetCollection(@"foo");

      [fetcher registerAssetCollection:assetCollection];

      assets = @[PTNPhotoKitCreateAsset(nil), PTNPhotoKitCreateAsset(nil)];
      [fetcher registerAssets:assets withAssetCollection:assetCollection];

      url = [NSURL ptn_photoKitAlbumURLWithCollection:assetCollection];
    });

    context(@"initial value", ^{
      it(@"should fetch initial results of an album", ^{
        RACSignal *albumSignal = [manager fetchAlbumWithURL:url];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:assets];
        expect(albumSignal).will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:album]]);
      });

      it(@"should fetch initial value again if there was an error on the first fetch", ^{
        id otherAssetCollection = PTNPhotoKitCreateAssetCollection(@"bar");

        NSURL *otherURL = [NSURL ptn_photoKitAlbumURLWithCollection:otherAssetCollection];
        expect([manager fetchAlbumWithURL:otherURL]).will.error();

        [fetcher registerAssetCollection:otherAssetCollection];
        [fetcher registerAssets:assets withAssetCollection:otherAssetCollection];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:otherURL fetchResult:assets];
        expect([manager fetchAlbumWithURL:otherURL]).will.sendValues(@[
          [PTNAlbumChangeset changesetWithAfterAlbum:album]
        ]);
      });
    });

    context(@"updates", ^{
      __block id<PTNAlbum> firstAlbum;
      __block id<PTNAlbum> secondAlbum;

      __block id changeDetails;
      __block id change;

      beforeEach(^{
        id asset = PTNPhotoKitCreateAsset(nil);
        id newAssets = @[asset];

        changeDetails = PTNPhotoKitCreateChangeDetailsForAssets(newAssets);
        change = PTNPhotoKitCreateChangeForFetchDetails(changeDetails);

        firstAlbum = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:assets];
        secondAlbum = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:newAssets];
      });

      it(@"should send new album upon update", ^{
        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [observer sendChange:change];

        expect(recorder.values).will.equal(@[
          [PTNAlbumChangeset changesetWithAfterAlbum:firstAlbum],
          [PTNAlbumChangeset changesetWithURL:url photoKitChangeDetails:changeDetails]
        ]);
      });

      it(@"should send latest album when album observation is already in place", ^{
        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [observer sendChange:change];

        // Trigger first fetch and wait until two values are returned.
        expect(recorder.values).will.equal(@[
          [PTNAlbumChangeset changesetWithAfterAlbum:firstAlbum],
          [PTNAlbumChangeset changesetWithURL:url photoKitChangeDetails:changeDetails]
        ]);

        expect([manager fetchAlbumWithURL:url]).will.sendValues(@[
          [PTNAlbumChangeset changesetWithAfterAlbum:secondAlbum]
        ]);
      });

      it(@"should send latest album after all signals have been destroyed", ^{
        @autoreleasepool {
          LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [observer sendChange:change];

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
      albums = @[
        PTNPhotoKitCreateAssetCollection(@"foo"), PTNPhotoKitCreateAssetCollection(@"bar")
      ];

      [fetcher registerAssetCollections:albums withType:PHAssetCollectionTypeAlbum
                             andSubtype:PHAssetCollectionSubtypeAny];

      PTNPhotoKitAlbumType *type = [PTNPhotoKitAlbumType
                                    albumTypeWithType:PHAssetCollectionTypeAlbum
                                    subtype:PHAssetCollectionSubtypeAny];
      url = [NSURL ptn_photoKitAlbumsWithType:type];
    });

    context(@"initial value", ^{
      it(@"should fetch initial results of an album", ^{
        RACSignal *albumSignal = [manager fetchAlbumWithURL:url];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:albums];
        expect(albumSignal).will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:album]]);
      });
    });

    context(@"regular updates", ^{
      __block id<PTNAlbum> initialAlbum;

      __block id change;
      __block id changeDetails;

      beforeEach(^{
        id newAlbums = @[
          PTNPhotoKitCreateAssetCollection(nil), PTNPhotoKitCreateAssetCollection(nil)
        ];
        changeDetails = PTNPhotoKitCreateChangeDetailsForAssets(newAlbums);
        change = PTNPhotoKitCreateChangeForFetchDetails(changeDetails);

        initialAlbum = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:albums];
      });

      it(@"should send new album upon update", ^{
        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [observer sendChange:change];

        expect(recorder.values).will.equal(@[
          [PTNAlbumChangeset changesetWithAfterAlbum:initialAlbum],
          [PTNAlbumChangeset changesetWithURL:url photoKitChangeDetails:changeDetails]
        ]);
      });
    });

    context(@"smart album collection updates", ^{
      __block id albums;
      __block NSURL *url;

      beforeEach(^{
        id firstCollection = PTNPhotoKitCreateAssetCollection(@"foo");
        id secondCollection = PTNPhotoKitCreateAssetCollection(@"bar");

        albums = @[firstCollection, secondCollection];
        [fetcher registerAssetCollections:albums withType:PHAssetCollectionTypeSmartAlbum
                               andSubtype:PHAssetCollectionSubtypeAny];

        [fetcher registerAssetCollection:firstCollection];
        [fetcher registerAssetCollection:secondCollection];
        
        [fetcher registerAssets:@[PTNPhotoKitCreateAsset(nil)]
            withAssetCollection:firstCollection];
        [fetcher registerAssets:@[PTNPhotoKitCreateAsset(nil)]
            withAssetCollection:secondCollection];

        PTNPhotoKitAlbumType *type = [PTNPhotoKitAlbumType
                                      albumTypeWithType:PHAssetCollectionTypeSmartAlbum
                                      subtype:PHAssetCollectionSubtypeAny];
        url = [NSURL ptn_photoKitAlbumsWithType:type];
      });

      it(@"should update smart album collection on subalbum change", ^{
        id asset = PTNPhotoKitCreateAsset(nil);

        id changeDetails = PTNPhotoKitCreateChangeDetailsForAssets(@[asset]);
        id change = PTNPhotoKitCreateChangeForFetchDetails(changeDetails);

        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [observer sendChange:change];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:albums];
        NSIndexSet *emptySet = [NSIndexSet indexSet];
        expect([NSSet setWithArray:recorder.values]).will.equal([NSSet setWithArray:@[
          [PTNAlbumChangeset changesetWithAfterAlbum:album],
          [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                           afterAlbum:album
                                       removedIndexes:emptySet
                                      insertedIndexes:emptySet
                                       updatedIndexes:[NSIndexSet indexSetWithIndex:0]
                                                moves:@[]],
          [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                           afterAlbum:album
                                       removedIndexes:emptySet
                                      insertedIndexes:emptySet
                                       updatedIndexes:[NSIndexSet indexSetWithIndex:1]
                                                moves:@[]]
        ]]);
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
      id assetCollection = PTNPhotoKitCreateAssetCollection(@"foo");

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
    asset = PTNPhotoKitCreateAsset(@"foo");
    [fetcher registerAsset:asset];
  });

  it(@"should fetch asset with URL", ^{
    NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
    expect([manager fetchAssetWithURL:url]).will.sendValues(@[asset]);
  });

  it(@"should send new asset upon update", ^{
    id newAsset = PTNPhotoKitCreateAsset(nil);

    id changeDetails = PTNPhotoKitCreateChangeDetailsForAsset(newAsset);
    id change = PTNPhotoKitCreateChangeForObjectDetails(changeDetails);

    NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
    LLSignalTestRecorder *recorder = [[manager fetchAssetWithURL:url] testRecorder];

    [observer sendChange:change];

    expect(recorder).will.sendValues(@[asset, newAsset]);
  });

  it(@"should error on non-existing asset", ^{
    id newAsset = PTNPhotoKitCreateAsset(@"bar");
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
    asset = PTNPhotoKitCreateAsset(@"foo");
    [fetcher registerAsset:asset];

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
      id unknownAsset = PTNPhotoKitCreateAsset(@"bar");

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
      assetCollection = PTNPhotoKitCreateAssetCollection(@"foo");
      [fetcher registerAssetCollection:assetCollection];

      url = [NSURL ptn_photoKitAlbumURLWithCollection:assetCollection];
    });

    it(@"should fetch asset collection representative image", ^{
      [fetcher registerAsset:asset asKeyAssetOfAssetCollection:assetCollection];

      [imageManager serveAsset:asset withProgress:@[] image:image];

      expect([manager fetchImageWithURL:url targetSize:size
                            contentMode:PTNImageContentModeAspectFill
                                options:options]).will.sendValues(@[
        [[PTNProgress alloc] initWithResult:image]
      ]);
    });

    it(@"should error on non-existing asset collection", ^{
      id assetCollection = PTNPhotoKitCreateAssetCollection(@"bar");

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
      [fetcher registerAsset:asset asKeyAssetOfAssetCollection:assetCollection];

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

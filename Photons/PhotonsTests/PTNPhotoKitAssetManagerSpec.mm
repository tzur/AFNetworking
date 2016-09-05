// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAssetManager.h"

#import <Photos/Photos.h>

#import "NSError+Photons.h"
#import "NSURL+PhotoKit.h"
#import "PTNAlbumChangeset+PhotoKit.h"
#import "PTNAuthorizationStatus.h"
#import "PTNDescriptor.h"
#import "PTNImageAsset.h"
#import "PTNImageFetchOptions+PhotoKit.h"
#import "PTNIncrementalChanges.h"
#import "PTNPhotoKitAlbum.h"
#import "PTNPhotoKitFakeAuthorizationManager.h"
#import "PTNPhotoKitFakeChangeManager.h"
#import "PTNPhotoKitFakeFetcher.h"
#import "PTNPhotoKitFakeImageManager.h"
#import "PTNPhotoKitFakeObserver.h"
#import "PTNPhotoKitImageManager.h"
#import "PTNPhotoKitTestUtils.h"
#import "PTNPhotoKitImageAsset.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"
#import "PhotoKit+Photons.h"

SpecBegin(PTNPhotoKitAssetManager)

__block PTNPhotoKitAssetManager *manager;

__block PTNPhotoKitFakeFetcher *fetcher;
__block PTNPhotoKitFakeObserver *observer;
__block PTNPhotoKitFakeImageManager *imageManager;
__block PTNPhotoKitFakeAuthorizationManager *authorizationManager;
__block PTNPhotoKitFakeChangeManager *changeManager;

beforeEach(^{
  fetcher = [[PTNPhotoKitFakeFetcher alloc] init];
  observer = [[PTNPhotoKitFakeObserver alloc] init];
  imageManager = [[PTNPhotoKitFakeImageManager alloc] init];
  authorizationManager = [[PTNPhotoKitFakeAuthorizationManager alloc] init];
  changeManager = [[PTNPhotoKitFakeChangeManager alloc] init];

  manager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher observer:observer
                                                imageManager:imageManager
                                        authorizationManager:authorizationManager
                                               changeManager:changeManager];
});

context(@"convenience initializers", ^{
  it(@"should correctly initialize with authorization manager initializer", ^{
    PTNPhotoKitAssetManager *manager =
        [[PTNPhotoKitAssetManager alloc] initWithAuthorizationManager:authorizationManager];
    expect(manager).toNot.beNil();
  });
  
  it(@"should correctly initialize with default initializer", ^{
    PTNPhotoKitAssetManager *manager = [[PTNPhotoKitAssetManager alloc] init];
    expect(manager).toNot.beNil();
  });
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

      it(@"should fetch results of an empty User Albums meta album", ^{
        id assetCollection = PTNPhotoKitCreateCollectionList(@"baz");
        NSURL *url = [NSURL ptn_photoKitMetaAlbumWithType:$(PTNPhotoKitMetaAlbumTypeUserAlbums)];
        [fetcher registerAssetCollection:assetCollection];
        [fetcher registerAssets:@[] withAssetCollection:assetCollection];

        id noAssets = @[];
        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:noAssets];

        expect([manager fetchAlbumWithURL:url]).will.
            sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:album]]);
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

    context(@"thread transitions", ^{
      it(@"should not operate on the main thread", ^{
        RACSignal *values = [manager fetchAlbumWithURL:url];
        
        expect(values).will.sendValuesWithCount(1);
        expect(fetcher.operatingThreads).notTo.contain([NSThread mainThread]);
      });
    });

    it(@"should error when not authorized", ^{
      authorizationManager.authorizationStatus = $(PTNAuthorizationStatusNotDetermined);

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeNotAuthorized;
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

      url = [NSURL ptn_photoKitMetaAlbumWithType:$(PTNPhotoKitMetaAlbumTypeUserAlbums)];
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

    context(@"sorted smart album types", ^{
      __block id albums;
      __block id albumsSubset;
      __block NSURL *url;
      __block PHCollectionList *transientList;

      beforeEach(^{
        PHAssetCollectionSubtype userLibrary = PHAssetCollectionSubtypeSmartAlbumUserLibrary;
        PHAssetCollectionSubtype favorites = PHAssetCollectionSubtypeSmartAlbumFavorites;
        id firstCollection = PTNPhotoKitCreateAssetCollection(@"foo", favorites);
        id secondCollection = PTNPhotoKitCreateAssetCollection(@"bar", userLibrary);
        id thirdCollection = PTNPhotoKitCreateAssetCollection(@"baz");

        albums = @[firstCollection, secondCollection, thirdCollection];
        albumsSubset = @[secondCollection, firstCollection];

        [fetcher registerAssetCollections:albums withType:PHAssetCollectionTypeSmartAlbum
                               andSubtype:PHAssetCollectionSubtypeAny];

        transientList = OCMClassMock([PHCollectionList class]);
        OCMStub(transientList.localIdentifier).andReturn(@[@"foo"]);

        [fetcher registerCollectionList:transientList withAssetCollections:albumsSubset];
        [fetcher registerAssetCollections:albumsSubset withCollectionList:transientList];

        [fetcher registerAssetCollection:firstCollection];
        [fetcher registerAssetCollection:secondCollection];

        PTNPhotoKitMetaAlbumType *type = $(PTNPhotoKitMetaAlbumTypePhotosAppSmartAlbums);
        url = [NSURL ptn_photoKitMetaAlbumWithType:type];
      });

      it(@"should update transient album collection on subalbum change", ^{
        id asset = PTNPhotoKitCreateAsset(nil);

        id changeDetails = PTNPhotoKitCreateChangeDetailsForAssets(@[asset]);
        id change = PTNPhotoKitCreateChangeForFetchDetails(changeDetails);

        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [observer sendChange:change];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:albumsSubset];
        NSIndexSet *emptySet = [NSIndexSet indexSet];

        PTNIncrementalChanges *firstChanges =
            [PTNIncrementalChanges changesWithRemovedIndexes:emptySet insertedIndexes:emptySet
                                              updatedIndexes:[NSIndexSet indexSetWithIndex:0]
                                                       moves:@[]];

        PTNIncrementalChanges *secondChanges =
            [PTNIncrementalChanges changesWithRemovedIndexes:emptySet insertedIndexes:emptySet
                                              updatedIndexes:[NSIndexSet indexSetWithIndex:1]
                                                       moves:@[]];

        expect([NSSet setWithArray:recorder.values]).will.equal([NSSet setWithArray:@[
          [PTNAlbumChangeset changesetWithAfterAlbum:album],
          [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                           afterAlbum:album
                                      subalbumChanges:firstChanges
                                         assetChanges:nil],
          [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                           afterAlbum:album
                                      subalbumChanges:secondChanges
                                         assetChanges:nil]]
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

        PTNPhotoKitMetaAlbumType *type = $(PTNPhotoKitMetaAlbumTypeSmartAlbums);
        url = [NSURL ptn_photoKitMetaAlbumWithType:type];
      });

      it(@"should update smart album collection on subalbum change", ^{
        id asset = PTNPhotoKitCreateAsset(nil);

        id changeDetails = PTNPhotoKitCreateChangeDetailsForAssets(@[asset]);
        id change = PTNPhotoKitCreateChangeForFetchDetails(changeDetails);

        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [observer sendChange:change];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:albums];
        NSIndexSet *emptySet = [NSIndexSet indexSet];

        PTNIncrementalChanges *firstChanges =
            [PTNIncrementalChanges changesWithRemovedIndexes:emptySet insertedIndexes:emptySet
                                              updatedIndexes:[NSIndexSet indexSetWithIndex:0]
                                                       moves:@[]];

        PTNIncrementalChanges *secondChanges =
            [PTNIncrementalChanges changesWithRemovedIndexes:emptySet insertedIndexes:emptySet
                                              updatedIndexes:[NSIndexSet indexSetWithIndex:1]
                                                       moves:@[]];

        expect([NSSet setWithArray:recorder.values]).will.equal([NSSet setWithArray:@[
          [PTNAlbumChangeset changesetWithAfterAlbum:album],
          [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                           afterAlbum:album
                                      subalbumChanges:firstChanges
                                         assetChanges:nil],
          [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                           afterAlbum:album
                                      subalbumChanges:secondChanges
                                         assetChanges:nil]
        ]]);
      });
    });

    context(@"thread transitions", ^{
      it(@"should not operate on the main thread", ^{
        RACSignal *values = [manager fetchAlbumWithURL:url];
        
        expect(values).will.sendValuesWithCount(1);
        expect(fetcher.operatingThreads).notTo.contain([NSThread mainThread]);
      });
    });

    it(@"should error when not authorized", ^{
      authorizationManager.authorizationStatus = $(PTNAuthorizationStatusNotDetermined);

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeNotAuthorized;
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
  __block id albumAsset;

  beforeEach(^{
    asset = PTNPhotoKitCreateAsset(@"foo");
    albumAsset = PTNPhotoKitCreateAssetCollection(@"bar");
    [fetcher registerAsset:asset];
    [fetcher registerAssetCollection:albumAsset];
  });

  it(@"should fetch asset with URL", ^{
    NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
    expect([manager fetchDescriptorWithURL:url]).will.sendValues(@[asset]);
  });

  it(@"should send new asset upon update", ^{
    id newAsset = PTNPhotoKitCreateAsset(nil);

    id changeDetails = PTNPhotoKitCreateChangeDetailsForAsset(newAsset);
    id change = PTNPhotoKitCreateChangeForObjectDetails(changeDetails);

    NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
    LLSignalTestRecorder *recorder = [[manager fetchDescriptorWithURL:url] testRecorder];

    [observer sendChange:change];

    expect(recorder).will.sendValues(@[asset, newAsset]);
  });

  it(@"should not cache assets", ^{
    NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
    RACSignal *sharedSignal = [manager fetchDescriptorWithURL:url];

    expect(sharedSignal).will.sendValues(@[asset]);

    id otherAsset = PTNPhotoKitCreateAsset(@"foo");
    [fetcher registerAsset:otherAsset];

    expect(sharedSignal).will.sendValues(@[otherAsset]);
  });

  it(@"should fetch album asset with URL", ^{
    NSURL *url = [NSURL ptn_photoKitAlbumURLWithCollection:albumAsset];
    expect([manager fetchDescriptorWithURL:url]).will.sendValues(@[albumAsset]);
  });

  it(@"should send new album asset upon update", ^{
    id newAlbumAsset = PTNPhotoKitCreateAssetCollection(nil);

    id changeDetails = PTNPhotoKitCreateChangeDetailsForAsset(newAlbumAsset);
    id change = PTNPhotoKitCreateChangeForObjectDetails(changeDetails);

    NSURL *url = [NSURL ptn_photoKitAlbumURLWithCollection:albumAsset];
    LLSignalTestRecorder *recorder = [[manager fetchDescriptorWithURL:url] testRecorder];

    [observer sendChange:change];

    expect(recorder).will.sendValues(@[albumAsset, newAlbumAsset]);
  });

  it(@"should not cache album assets", ^{
    NSURL *url = [NSURL ptn_photoKitAlbumURLWithCollection:albumAsset];
    RACSignal *sharedSignal = [manager fetchDescriptorWithURL:url];

    expect(sharedSignal).will.sendValues(@[albumAsset]);

    id otherAlbumAsset = PTNPhotoKitCreateAssetCollection(@"bar");
    [fetcher registerAssetCollection:otherAlbumAsset];

    expect(sharedSignal).will.sendValues(@[otherAlbumAsset]);
  });

  it(@"should error on non-existing asset", ^{
    id newAsset = PTNPhotoKitCreateAsset(@"bar");
    NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:newAsset];
    expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetNotFound;
    });
  });

  it(@"should error on meta album URL", ^{
    NSURL *url = [NSURL ptn_photoKitMetaAlbumWithType:$(PTNPhotoKitMetaAlbumTypeSmartAlbums)];

    expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  it(@"should error on invalid URL", ^{
    NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];

    expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  it(@"should error when not authorized", ^{
    NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];

    authorizationManager.authorizationStatus = $(PTNAuthorizationStatusNotDetermined);

    expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeNotAuthorized;
    });
  });

  context(@"thread transitions", ^{
    it(@"should not operate on the main thread", ^{
      NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
      
      RACSignal *values = [manager fetchDescriptorWithURL:url];
      
      expect(values).will.sendValuesWithCount(1);
      expect(fetcher.operatingThreads).notTo.contain([NSThread mainThread]);
    });
  });
});

context(@"image fetching", ^{
  __block id asset;
  __block CGSize size;
  __block PTNImageFetchOptions *options;
  __block id<PTNResizingStrategy> resizingStrategy;
  __block id<PTNImageAsset> imageAsset;
  __block UIImage *image;

  __block NSError *defaultError;

  beforeEach(^{
    asset = PTNPhotoKitCreateAsset(@"foo");
    [fetcher registerAsset:asset];

    size = CGSizeMake(64, 64);
    resizingStrategy = [PTNResizingStrategy aspectFill:size];
    options = [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeFast
                                                 resizeMode:PTNImageResizeModeFast];

    image = [[UIImage alloc] init];
    imageAsset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:asset];

    defaultError = [NSError errorWithDomain:@"foo" code:1337 userInfo:nil];
  });

  context(@"fetch image of asset", ^{
    it(@"should fetch image", ^{
      [imageManager serveAsset:asset withProgress:@[] image:image];

      RACSignal *values = [manager fetchImageWithDescriptor:asset
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValues(@[[[PTNProgress alloc] initWithResult:imageAsset]]);
    });

    it(@"should complete after fetching an image", ^{
      [imageManager serveAsset:asset withProgress:@[] image:image];

      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValuesWithCount(1);
      expect(values).will.complete();
    });

    it(@"should fetch downloaded image", ^{
      [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] image:image];

      expect([manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                       options:options]).will.sendValues(@[
        [[PTNProgress alloc] initWithProgress:@0.25],
        [[PTNProgress alloc] initWithProgress:@0.5],
        [[PTNProgress alloc] initWithProgress:@1],
        [[PTNProgress alloc] initWithResult:imageAsset]
      ]);
    });

    it(@"should cancel request upon disposal", ^{
      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:options];

      RACDisposable *subscriber = [values subscribeNext:^(id __unused x) {}];
      expect([imageManager isRequestIssuedForAsset:asset]).will.beTruthy();

      [subscriber dispose];
      expect([imageManager isRequestCancelledForAsset:asset]).will.beTruthy();
    });

    it(@"should error on download error", ^{
      [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] finallyError:defaultError];

      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValues(@[
        [[PTNProgress alloc] initWithProgress:@0.25],
        [[PTNProgress alloc] initWithProgress:@0.5],
        [[PTNProgress alloc] initWithProgress:@1],
      ]);

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
      });
    });

    context(@"thread transitions", ^{
      it(@"should not operate on the main thread", ^{
        [imageManager serveAsset:asset withProgress:@[] image:image];
        
        RACSignal *values = [manager fetchImageWithDescriptor:asset
                                             resizingStrategy:resizingStrategy
                                                      options:options];

        expect(values).will.sendValuesWithCount(1);
        expect(fetcher.operatingThreads).notTo.contain([NSThread mainThread]);
      });
    });

    it(@"should error on progress download error", ^{
      [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] errorInProgress:defaultError];

      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValues(@[
        [[PTNProgress alloc] initWithProgress:@0.25],
        [[PTNProgress alloc] initWithProgress:@0.5]
      ]);

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
      });
    });
  });

  context(@"fetch image of asset collection", ^{
    __block id assetCollection;

    beforeEach(^{
      assetCollection = PTNPhotoKitCreateAssetCollection(@"foo");
      [fetcher registerAssetCollection:assetCollection];
    });

    it(@"should fetch asset collection representative image", ^{
      [fetcher registerAsset:asset asKeyAssetOfAssetCollection:assetCollection];
      [imageManager serveAsset:asset withProgress:@[] image:image];

      RACSignal *values = [manager fetchImageWithDescriptor:assetCollection
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValues(@[[[PTNProgress alloc] initWithResult:imageAsset]]);
    });

    it(@"should error on non-existing key assets", ^{
      RACSignal *values = [manager fetchImageWithDescriptor:assetCollection
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeKeyAssetsNotFound;
      });
    });

    it(@"should error on non-existing key asset", ^{
      [fetcher registerAsset:asset asKeyAssetOfAssetCollection:assetCollection];

      RACSignal *values = [manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetLoadingFailed;
      });
    });
  });
  
  it(@"should error on non-PhotoKit asset", ^{
    id invalidAsset = OCMProtocolMock(@protocol(PTNDescriptor));

    RACSignal *values = [manager fetchImageWithDescriptor:invalidAsset
                                         resizingStrategy:resizingStrategy
                                                  options:options];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidDescriptor;
    });
  });

  it(@"should error when not authorized", ^{
    authorizationManager.authorizationStatus = $(PTNAuthorizationStatusNotDetermined);

    RACSignal *values = [manager fetchImageWithDescriptor:asset
                                        resizingStrategy:resizingStrategy
                                                 options:options];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeNotAuthorized;
    });
  });

  context(@"resizing strategy", ^{
    __block id imageManagerMock;
    __block id<PTNResizingStrategy> resizingStrategy;

    beforeEach(^{
      asset = PTNPhotoKitCreateAsset(@"baz", size);
      imageManagerMock = OCMProtocolMock(@protocol(PTNPhotoKitImageManager));
      manager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher observer:observer
                                                    imageManager:imageManagerMock
                                            authorizationManager:authorizationManager
                                                   changeManager:changeManager];
      resizingStrategy = OCMProtocolMock(@protocol(PTNResizingStrategy));
    });

    context(@"image size", ^{
      it(@"should request image size from strategy and use it to fetch image", ^{
        OCMStub([resizingStrategy sizeForInputSize:size]).andReturn(CGSizeMake(1337, 1337));
        OCMExpect([imageManagerMock requestImageForAsset:asset
                                              targetSize:CGSizeMake(1337, 1337)
                                             contentMode:PHImageContentModeDefault
                                                 options:OCMOCK_ANY
                                           resultHandler:OCMOCK_ANY]);

        [[manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy options:options]
         subscribeNext:^(id __unused x) {}];

        OCMVerifyAllWithDelay(imageManagerMock, 1);
      });

      it(@"should fetch image with maximum size if strategy returns original image size", ^{
        OCMStub([resizingStrategy sizeForInputSize:size]).andReturn(size);
        OCMExpect([imageManagerMock requestImageForAsset:asset
                                              targetSize:PHImageManagerMaximumSize
                                             contentMode:PHImageContentModeDefault
                                                 options:OCMOCK_ANY
                                           resultHandler:OCMOCK_ANY]);

        [[manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy options:options]
         subscribeNext:^(id __unused x) {}];
        
        OCMVerifyAllWithDelay(imageManagerMock, 1);
      });
    });

    context(@"content mode", ^{
      it(@"should request content mode from strategy and use it to fetch image when its fill", ^{
        OCMStub(resizingStrategy.contentMode).andReturn(PTNImageContentModeAspectFill);
        OCMExpect([imageManagerMock requestImageForAsset:asset
                                              targetSize:CGSizeZero
                                             contentMode:PHImageContentModeAspectFill
                                                 options:OCMOCK_ANY
                                           resultHandler:OCMOCK_ANY]);

        [[manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy options:options]
         subscribeNext:^(id __unused x) {}];

        OCMVerifyAllWithDelay(imageManagerMock, 1);
      });

      it(@"should request content mode from strategy and use it to fetch image when its fit", ^{
        OCMStub(resizingStrategy.contentMode).andReturn(PTNImageContentModeAspectFit);
        OCMExpect([imageManagerMock requestImageForAsset:asset
                                              targetSize:CGSizeZero
                                             contentMode:PHImageContentModeAspectFit
                                                 options:OCMOCK_ANY
                                           resultHandler:OCMOCK_ANY]);

        [[manager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy options:options]
         subscribeNext:^(id __unused x) {}];
        
        OCMVerifyAllWithDelay(imageManagerMock, 1);
      });
    });
  });
});

context(@"asset changes", ^{
  __block NSArray *assets;
  __block NSArray *assetCollections;
  __block NSArray *collectionLists;
  __block NSError *error;

  beforeEach(^{
    assets = @[
      PTNPhotoKitCreateAsset(@"foo"),
      PTNPhotoKitCreateAsset(@"bar")
    ];
    assetCollections = @[
      PTNPhotoKitCreateAssetCollection(@"foo of foos"),
      PTNPhotoKitCreateAssetCollection(@"bar of bars")
    ];
    collectionLists = @[
      PTNPhotoKitCreateCollectionList(@"foo of foos of foos"),
      PTNPhotoKitCreateCollectionList(@"bar of bars of bars")
    ];
    error = [NSError lt_errorWithCode:1337];
  });

  context(@"deletion", ^{
    it(@"should delete assets", ^{
      expect([manager deleteDescriptors:assets]).will.complete();
      expect((changeManager.assetDeleteRequests)).to.equal(assets);
    });

    it(@"should delete asset collections", ^{
      expect([manager deleteDescriptors:assetCollections]).will.complete();
      expect((changeManager.assetCollectionDeleteRequests)).to.equal(assetCollections);
    });

    it(@"should delete collection lists", ^{
      expect([manager deleteDescriptors:collectionLists]).will.complete();
      expect((changeManager.collectionListDeleteRequests)).to.equal(collectionLists);
    });

    it(@"should delete a mixture of descriptor types", ^{
      NSArray *descriptors = [[assets arrayByAddingObjectsFromArray:assetCollections]
        arrayByAddingObjectsFromArray:collectionLists];

      expect([manager deleteDescriptors:descriptors]).will.complete();
      expect((changeManager.assetDeleteRequests)).to.equal(assets);
      expect((changeManager.assetCollectionDeleteRequests)).to.equal(assetCollections);
      expect((changeManager.collectionListDeleteRequests)).to.equal(collectionLists);
    });

    it(@"should propogate error when failing to delete descritpors", ^{
      changeManager.success = NO;
      changeManager.error = error;

      expect([manager deleteDescriptors:assets]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetDeletionFailed;
      });
    });

    it(@"should err when invalid descritpors are given", ^{
      id<PTNDescriptor> invalidAsset = OCMProtocolMock(@protocol(PTNDescriptor));
      expect([manager deleteDescriptors:@[invalidAsset]]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeInvalidDescriptor;
      });
    });
  });

  context(@"removal of assets from album", ^{
    it(@"should remove assets from asset collections", ^{
      PHAssetCollection *collection = assetCollections.firstObject;
      expect([manager removeDescriptors:assets fromAlbum:collection]).will.complete();
      expect(changeManager.assetsRemovedFromAlbumRequests[collection.localIdentifier])
          .to.equal(assets);
    });

    it(@"should remove assets collections from collection lists", ^{
      PHCollectionList *collectionList = collectionLists.firstObject;
      expect([manager removeDescriptors:assetCollections fromAlbum:collectionList]).will.complete();
      expect(changeManager.assetCollectionsRemovedFromAlbumRequests[collectionList.localIdentifier])
          .to.equal(assetCollections);
    });

    it(@"should err when removing assets from collection lists", ^{
      PHCollectionList *collectionList = collectionLists.firstObject;
      expect([manager removeDescriptors:assets fromAlbum:collectionList])
          .will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetRemovalFromAlbumFailed;
      });
    });

    it(@"should err when removing asset collections from asset collection", ^{
      PHAssetCollection *collection = assetCollections.firstObject;
      expect([manager removeDescriptors:assetCollections fromAlbum:collection])
          .will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetRemovalFromAlbumFailed;
      });
    });

    it(@"should err when removing collection lists", ^{
      PHCollectionList *collectionList = collectionLists.firstObject;
      expect([manager removeDescriptors:collectionLists fromAlbum:collectionList])
          .will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetRemovalFromAlbumFailed;
      });
    });

    it(@"should err when removing assets from an invalid album descriptor", ^{
      id<PTNAlbumDescriptor> invalidDescriptor = OCMProtocolMock(@protocol(PTNAlbumDescriptor));
      expect([manager removeDescriptors:assets fromAlbum:invalidDescriptor])
          .will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeInvalidDescriptor;
      });
    });

    it(@"should err when removing assets from an album descriptor that does not support removal", ^{
      id<PTNAlbumDescriptor> invalidDescriptor = OCMClassMock([PHAssetCollection class]);
      expect([manager removeDescriptors:assets fromAlbum:invalidDescriptor])
          .will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeInvalidDescriptor;
      });
    });
  });

  context(@"favorite", ^{
    __block id<PTNAssetDescriptor> firstAsset;
    __block id<PTNAssetDescriptor> secondAsset;

    beforeEach(^{
      firstAsset = PTNPhotoKitCreateAsset(@"foo");
      OCMStub([firstAsset assetDescriptorCapabilities])
          .andReturn(PTNAssetDescriptorCapabilityFavorite);
      secondAsset = PTNPhotoKitCreateAsset(@"bar");
      OCMStub([secondAsset assetDescriptorCapabilities])
          .andReturn(PTNAssetDescriptorCapabilityFavorite);
    });

    it(@"should favorite and unfavorite assets", ^{
      expect([manager favoriteDescriptors:@[firstAsset, secondAsset] favorite:YES]).will.complete();
      expect([changeManager favoriteAssets]).to.contain(firstAsset);
      expect([changeManager favoriteAssets]).to.contain(secondAsset);
      expect([manager favoriteDescriptors:@[firstAsset] favorite:NO]).will.complete();
      expect([changeManager favoriteAssets]).toNot.contain(firstAsset);
      expect([changeManager favoriteAssets]).to.contain(secondAsset);
    });

    it(@"should err when failing to change favorite status", ^{
      changeManager.success = NO;
      changeManager.error = error;

      expect([manager favoriteDescriptors:@[firstAsset, secondAsset] favorite:YES])
          .will.sendError(error);
      expect([manager favoriteDescriptors:@[firstAsset] favorite:NO]).will.sendError(error);
    });

    it(@"should err when favoring non-asset descriptors", ^{
      id<PTNDescriptor> albumDescriptor = PTNPhotoKitCreateAssetCollection(@"foo");

      expect([manager favoriteDescriptors:@[firstAsset, albumDescriptor] favorite:YES])
          .will.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == PTNErrorCodeInvalidDescriptor &&
            error.ptn_associatedDescriptor == albumDescriptor;
      });
    });

    it(@"should err when favoring non-PhotoKit descriptors", ^{
      id<PTNAssetDescriptor> invalidDescriptor = OCMProtocolMock(@protocol(PTNAssetDescriptor));
      OCMStub([invalidDescriptor assetDescriptorCapabilities])
          .andReturn(PTNAssetDescriptorCapabilityFavorite);

      expect([manager favoriteDescriptors:@[firstAsset, invalidDescriptor] favorite:YES])
          .will.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == PTNErrorCodeInvalidDescriptor &&
            error.ptn_associatedDescriptor == invalidDescriptor;
      });
    });
  });
});

SpecEnd

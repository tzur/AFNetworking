// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAssetManager.h"

#import <LTKit/LTProgress.h>
#import <Photos/Photos.h>

#import "NSError+Photons.h"
#import "NSURL+PhotoKit.h"
#import "PTNAVAssetFetchOptions.h"
#import "PTNAlbumChangeset+PhotoKit.h"
#import "PTNAudiovisualAsset.h"
#import "PTNAuthorizationStatus.h"
#import "PTNDescriptor.h"
#import "PTNImageAsset.h"
#import "PTNImageDataAsset.h"
#import "PTNImageFetchOptions+PhotoKit.h"
#import "PTNImageMetadata.h"
#import "PTNImageResizer.h"
#import "PTNIncrementalChanges.h"
#import "PTNPhotoKitAlbum.h"
#import "PTNPhotoKitFakeAssetResourceManager.h"
#import "PTNPhotoKitFakeAuthorizationManager.h"
#import "PTNPhotoKitFakeChangeManager.h"
#import "PTNPhotoKitFakeFetchResultChangeDetails.h"
#import "PTNPhotoKitFakeFetcher.h"
#import "PTNPhotoKitFakeImageManager.h"
#import "PTNPhotoKitFakeObserver.h"
#import "PTNPhotoKitImageAsset.h"
#import "PTNPhotoKitImageManager.h"
#import "PTNPhotoKitTestUtils.h"
#import "PTNResizingStrategy.h"
#import "PTNStaticImageAsset.h"
#import "PhotoKit+Photons.h"

static BOOL PTNNSPredicateEquals(NSPredicate *lhs, NSPredicate *rhs) {
  return [lhs.predicateFormat isEqual:rhs.predicateFormat];
}

static BOOL PTNNSSortDescriptorEquals(NSSortDescriptor *lhs, NSSortDescriptor *rhs) {
  return [lhs.key isEqual:rhs.key] && lhs.ascending == rhs.ascending &&
          lhs.selector == rhs.selector;
}

static BOOL PTNPHFetchOptionsEquals(PHFetchOptions *lhs, PHFetchOptions *rhs) {
  if (lhs == rhs) {
    return YES;
  }

  if (!PTNNSPredicateEquals(lhs.predicate, rhs.predicate)) {
    return NO;
  }

  if (lhs.sortDescriptors.count != rhs.sortDescriptors.count) {
    return NO;
  }

  for (NSUInteger i = 0; i < lhs.sortDescriptors.count; i++) {
    if (!PTNNSSortDescriptorEquals(lhs.sortDescriptors[i], rhs.sortDescriptors[i])) {
      return NO;
    }
  }

  return lhs.includeHiddenAssets == rhs.includeHiddenAssets &&
         lhs.includeAllBurstAssets == rhs.includeAllBurstAssets &&
         lhs.includeAssetSourceTypes == rhs.includeAssetSourceTypes &&
         lhs.fetchLimit == rhs.fetchLimit &&
         lhs.wantsIncrementalChangeDetails == rhs.wantsIncrementalChangeDetails;
}

SpecBegin(PTNPhotoKitAssetManager)

__block PTNPhotoKitAssetManager *manager;
__block PTNPhotoKitFakeFetcher *fetcher;
__block PTNPhotoKitFakeObserver *observer;
__block PTNPhotoKitFakeImageManager *imageManager;
__block PTNPhotoKitFakeAssetResourceManager *assetResourceManager;
__block PTNPhotoKitFakeAuthorizationManager *authorizationManager;
__block PTNPhotoKitFakeChangeManager *changeManager;
__block PTNImageResizer *imageResizer;

beforeEach(^{
  fetcher = [[PTNPhotoKitFakeFetcher alloc] init];
  observer = [[PTNPhotoKitFakeObserver alloc] init];
  imageManager = [[PTNPhotoKitFakeImageManager alloc] init];
  assetResourceManager = [[PTNPhotoKitFakeAssetResourceManager alloc] init];
  authorizationManager = [[PTNPhotoKitFakeAuthorizationManager alloc] init];
  changeManager = [[PTNPhotoKitFakeChangeManager alloc] init];
  imageResizer = OCMClassMock([PTNImageResizer class]);

  manager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher observer:observer
                                                imageManager:imageManager
                                        assetResourceManager:assetResourceManager
                                        authorizationManager:authorizationManager
                                               changeManager:changeManager
                                                imageResizer:imageResizer];
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
        NSURL *url = [NSURL ptn_photoKitUserAlbums];
        [fetcher registerAssetCollections:@[] withType:PHAssetCollectionTypeAlbum
                               andSubtype:PHAssetCollectionSubtypeAny];

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

    it(@"should deallocate while subscribed to a fetched album signal", ^{
      __weak PTNPhotoKitAssetManager *weakManager;
      LLSignalTestRecorder *recorder;

      @autoreleasepool {
        PTNPhotoKitAssetManager *manager = [[PTNPhotoKitAssetManager alloc]
                                            initWithFetcher:fetcher observer:observer
                                            imageManager:imageManager
                                            assetResourceManager:assetResourceManager
                                            authorizationManager:authorizationManager
                                            changeManager:changeManager
                                            imageResizer:imageResizer];
        weakManager = manager;

        recorder = [[manager fetchAlbumWithURL:url] testRecorder];
      }

      expect(weakManager).to.beNil();

      // This expectation is required to keep the recorder alive until we verify that the manager
      // deallocated.
      expect(recorder).notTo.beNil();
    });
  });

  context(@"fetching album by type", ^{
    __block id album;
    __block id assets;
    __block NSURL *url;

    beforeEach(^{
      album = PTNPhotoKitCreateAssetCollection(@"foo");
      assets = @[PTNPhotoKitCreateAsset(@"bar")];

      [fetcher registerAssets:assets withAssetCollection:album];
      [fetcher registerAssetCollections:@[album] withType:PHAssetCollectionTypeAlbum
                             andSubtype:PHAssetCollectionSubtypeSmartAlbumSelfPortraits];

      url = [NSURL ptn_photoKitAlbumWithType:PHAssetCollectionTypeAlbum
                                     subtype:PHAssetCollectionSubtypeSmartAlbumSelfPortraits];
    });

    context(@"initial value", ^{
      it(@"should fetch initial results of an album", ^{
        RACSignal *albumSignal = [manager fetchAlbumWithURL:url];

        id<PTNAlbum> expectedAlbum = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:assets];
        expect(albumSignal)
            .will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:expectedAlbum]]);
      });
    });

    context(@"regular updates", ^{
      __block id<PTNAlbum> initialAlbum;

      __block id change;
      __block id changeDetails;

      beforeEach(^{
        id newAlbum = PTNPhotoKitCreateAssetCollection(@"baz");
        [fetcher registerAssets:assets withAssetCollection:newAlbum];

        changeDetails = PTNPhotoKitCreateChangeDetailsForAssets(assets);
        change = PTNPhotoKitCreateChangeForFetchDetails(changeDetails);

        initialAlbum = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:assets];
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

    it(@"should err when failing to fetch album", ^{
      url = [NSURL ptn_photoKitAlbumWithType:PHAssetCollectionTypeAlbum
                                     subtype:PHAssetCollectionSubtypeSmartAlbumPanoramas];
      [fetcher registerAssetCollections:@[] withType:PHAssetCollectionTypeAlbum
                             andSubtype:PHAssetCollectionSubtypeSmartAlbumPanoramas];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAlbumNotFound;
      });
    });
  });

  context(@"fetching album by media type", ^{
    static const PHAssetMediaType kMediaType = PHAssetMediaTypeVideo;

    __block id album;
    __block id assets;
    __block NSURL *url;

    beforeEach(^{
      album = PTNPhotoKitCreateAssetCollection(@"foo");
      assets = @[PTNPhotoKitCreateAsset(@"bar")];

      [fetcher registerAssets:assets withMediaType:kMediaType];
      [fetcher registerAssetCollection:album withFetchResult:assets];
      [fetcher registerAssets:assets withAssetCollection:album];

      url = [NSURL ptn_photoKitAlbumWithMediaType:kMediaType];
    });

    context(@"initial value", ^{
      it(@"should fetch initial results of an album", ^{
        RACSignal *albumSignal = [manager fetchAlbumWithURL:url];

        id<PTNAlbum> expectedAlbum = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:assets];
        expect(albumSignal)
            .will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:expectedAlbum]]);
      });
    });

    context(@"updates", ^{
      __block id<PTNAlbum> initialAlbum;

      __block id change;
      __block id changeDetails;

      beforeEach(^{
        id newAlbum = PTNPhotoKitCreateAssetCollection(@"baz");
        [fetcher registerAssets:assets withAssetCollection:newAlbum];

        changeDetails = PTNPhotoKitCreateChangeDetailsForAssets(assets);
        change = PTNPhotoKitCreateChangeForFetchDetails(changeDetails);

        initialAlbum = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:assets];
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

    it(@"should err when failing to fetch album", ^{
      url = [NSURL ptn_photoKitAlbumWithType:PHAssetCollectionTypeAlbum
                                     subtype:PHAssetCollectionSubtypeSmartAlbumPanoramas];
      [fetcher registerAssetCollections:@[] withType:PHAssetCollectionTypeAlbum
                             andSubtype:PHAssetCollectionSubtypeSmartAlbumPanoramas];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAlbumNotFound;
      });
    });
  });

  context(@"fetching meta album by type", ^{
    __block id albums;
    __block NSURL *url;

    beforeEach(^{
      albums = @[
        PTNPhotoKitCreateAssetCollection(@"foo"), PTNPhotoKitCreateAssetCollection(@"bar")
      ];

      [fetcher registerAssetCollections:albums withType:PHAssetCollectionTypeAlbum
                             andSubtype:PHAssetCollectionSubtypeAny];

      url = [NSURL ptn_photoKitUserAlbums];
    });

    context(@"initial value", ^{
      it(@"should fetch initial results of an album", ^{
        RACSignal *albumSignal = [manager fetchAlbumWithURL:url];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:albums];
        expect(albumSignal).will.matchValue(0, ^BOOL(PTNAlbumChangeset *sentChangeset) {
          return [sentChangeset isEqual:[PTNAlbumChangeset changesetWithAfterAlbum:album]];
        });
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

      __block id favoritesCollection;
      __block id cameraRollCollection;
      __block id userCollection;

      beforeEach(^{
        PHAssetCollectionSubtype userLibrary = PHAssetCollectionSubtypeSmartAlbumUserLibrary;
        PHAssetCollectionSubtype favorites = PHAssetCollectionSubtypeSmartAlbumFavorites;
        favoritesCollection = PTNPhotoKitCreateAssetCollection(@"foo", favorites);
        cameraRollCollection = PTNPhotoKitCreateAssetCollection(@"bar", userLibrary);
        userCollection = PTNPhotoKitCreateAssetCollection(@"baz");
        albums = @[favoritesCollection, cameraRollCollection, userCollection];
        albumsSubset = @[cameraRollCollection, favoritesCollection];

        [fetcher registerAssetCollections:albums withType:PHAssetCollectionTypeSmartAlbum
                               andSubtype:PHAssetCollectionSubtypeAny];

        transientList = OCMClassMock([PHCollectionList class]);
        OCMStub(transientList.localIdentifier).andReturn(@[@"foo"]);

        [fetcher registerCollectionList:transientList withAssetCollections:albumsSubset];
        [fetcher registerAssetCollections:albumsSubset withCollectionList:transientList];
        [fetcher registerAssets:@[] withAssetCollection:userCollection];

        [fetcher registerAssetCollection:favoritesCollection];
        [fetcher registerAssetCollection:cameraRollCollection];
        [fetcher registerAssetCollection:userCollection];

        url = [NSURL ptn_photoKitMetaAlbumWithType:PHAssetCollectionTypeSmartAlbum subalbums:{
          PHAssetCollectionSubtypeSmartAlbumUserLibrary,
          PHAssetCollectionSubtypeSmartAlbumFavorites
        }];
      });

      it(@"should fetch smart album subset", ^{
        id asset = PTNPhotoKitCreateAsset(nil);
        NSArray *assets = @[asset];
        [fetcher registerAssets:assets withAssetCollection:favoritesCollection];
        [fetcher registerAssets:assets withAssetCollection:cameraRollCollection];

        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:albumsSubset];

        expect(recorder).will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:album]]);
      });

      it(@"should hide empty albums", ^{
        id asset = PTNPhotoKitCreateAsset(nil);
        NSArray *assets = @[asset];
        [fetcher registerAssets:assets withAssetCollection:favoritesCollection];
        [fetcher registerAssets:@[] withAssetCollection:cameraRollCollection];

        PHCollectionList *transientList = OCMClassMock([PHCollectionList class]);
        OCMStub(transientList.localIdentifier).andReturn(@[@"bar"]);

        [fetcher registerAssetCollections:@[favoritesCollection] withCollectionList:transientList];
        [fetcher registerCollectionList:transientList withAssetCollections:@[favoritesCollection]];

        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url
            fetchResult:(PHFetchResult *)@[favoritesCollection]];

        expect(recorder).will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:album]]);
      });

      it(@"should update transient album collection on subalbum change", ^{
        id asset = PTNPhotoKitCreateAsset(nil);
        NSArray *assets = @[asset];
        [fetcher registerAssets:assets withAssetCollection:favoritesCollection];
        [fetcher registerAssets:assets withAssetCollection:cameraRollCollection];

        NSIndexSet *emptySet = [NSIndexSet indexSet];
        NSIndexSet *updatedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];

        PTNPhotoKitFakeFetchResultChangeDetails *changeDetails =
            [[PTNPhotoKitFakeFetchResultChangeDetails alloc] initWithBeforeChanges:albumsSubset
            afterChanges:albumsSubset hasIncrementalChanges:YES removedIndexes:emptySet
            removedObjects:@[] insertedIndexes:emptySet insertedObjects:@[]
            changedIndexes:updatedIndexes changedObjects:albumsSubset hasMoves:NO];

        [fetcher registerChangeDetails:changeDetails forFromFetchResult:albumsSubset
                         toFetchResult:albumsSubset changedObjects:nil];

        id change = PTNPhotoKitCreateChangeForFetchDetails(changeDetails);

        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [observer sendChange:change];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:albumsSubset];

        PTNIncrementalChanges *changes =
        [PTNIncrementalChanges changesWithRemovedIndexes:emptySet insertedIndexes:emptySet
                                          updatedIndexes:updatedIndexes
                                                   moves:@[]];

        expect([NSSet setWithArray:recorder.values]).will.equal([NSSet setWithArray:@[
          [PTNAlbumChangeset changesetWithAfterAlbum:album],
          [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                           afterAlbum:album
                                      subalbumChanges:changes
                                         assetChanges:nil]]
        ]);
      });

      it(@"should not update transient album collection on irrelevant subalbum change", ^{
        id asset = PTNPhotoKitCreateAsset(nil);
        NSArray *assets = @[asset];
        [fetcher registerAssets:assets withAssetCollection:favoritesCollection];
        [fetcher registerAssets:assets withAssetCollection:cameraRollCollection];

        NSArray *otherAssets = @[PTNPhotoKitCreateAsset(nil)];
        [fetcher registerAssets:otherAssets withAssetCollection:userCollection];

        id changeDetails = PTNPhotoKitCreateChangeDetailsForAssets(otherAssets);
        id change = OCMClassMock(PHChange.class);
        OCMStub([change changeDetailsForFetchResult:(id)otherAssets]).andReturn(changeDetails);

        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [observer sendChange:change];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:albumsSubset];

        expect(recorder).will.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:album]]);
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

        url = [NSURL ptn_photoKitMetaAlbumWithType:PHAssetCollectionTypeSmartAlbum];
      });

      it(@"should update smart album collection on subalbum change", ^{
        NSIndexSet *updatedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
        NSIndexSet *emptySet = [NSIndexSet indexSet];

        PTNPhotoKitFakeFetchResultChangeDetails *changeDetails =
            [[PTNPhotoKitFakeFetchResultChangeDetails alloc] initWithBeforeChanges:albums
            afterChanges:albums hasIncrementalChanges:YES removedIndexes:emptySet
            removedObjects:@[] insertedIndexes:emptySet insertedObjects:@[]
            changedIndexes:updatedIndexes
            changedObjects:albums hasMoves:NO];

        [fetcher registerChangeDetails:changeDetails forFromFetchResult:albums
                         toFetchResult:albums changedObjects:nil];

        id change = PTNPhotoKitCreateChangeForFetchDetails(changeDetails);

        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [observer sendChange:change];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:albums];

        PTNIncrementalChanges *changes =
            [PTNIncrementalChanges changesWithRemovedIndexes:emptySet insertedIndexes:emptySet
                                              updatedIndexes:updatedIndexes
                                                       moves:@[]];

        expect([NSSet setWithArray:recorder.values]).will.equal([NSSet setWithArray:@[
          [PTNAlbumChangeset changesetWithAfterAlbum:album],
          [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                           afterAlbum:album
                                      subalbumChanges:changes
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

    it(@"should deallocate while subscribed to the smart album signal", ^{
      __weak PTNPhotoKitAssetManager *weakManager;
      LLSignalTestRecorder *recorder;

      NSURL *url = [NSURL ptn_photoKitMetaAlbumWithType:PHAssetCollectionTypeSmartAlbum];

      @autoreleasepool {
        PTNPhotoKitAssetManager *manager = [[PTNPhotoKitAssetManager alloc]
                                            initWithFetcher:fetcher
                                            observer:observer
                                            imageManager:imageManager
                                            assetResourceManager:assetResourceManager
                                            authorizationManager:authorizationManager
                                            changeManager:changeManager
                                            imageResizer:imageResizer];
        weakManager = manager;

        recorder = [[manager fetchAlbumWithURL:url] testRecorder];
      }

      expect(weakManager).to.beNil();

      // This expectation is required to keep the recorder alive until we verify that the manager
      // deallocated.
      expect(recorder).notTo.beNil();
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

    context(@"empty fetchResult", ^{
      it(@"should err when fetching smart albums", ^{
        [fetcher registerAssetCollections:@[] withType:PHAssetCollectionTypeSmartAlbum
                               andSubtype:PHAssetCollectionSubtypeAny];
        NSURL *url = [NSURL ptn_photoKitMetaAlbumWithType:PHAssetCollectionTypeSmartAlbum];

        expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
          return error.code == PTNErrorCodeAlbumNotFound;
        });
      });

      it(@"should not err when fetching user albums", ^{
        [fetcher registerAssetCollections:@[] withType:PHAssetCollectionTypeAlbum
                               andSubtype:PHAssetCollectionSubtypeAny];
        NSURL *url = [NSURL ptn_photoKitMetaAlbumWithType:PHAssetCollectionTypeAlbum];

        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        expect(recorder).will.sendValuesWithCount(1);
        expect(recorder).notTo.error();
      });

      it(@"should not err fetching smart albums with a subalbum filter", ^{
        PHCollectionList *transientList = OCMClassMock([PHCollectionList class]);
        OCMStub(transientList.localIdentifier).andReturn(@[@"foo"]);

        [fetcher registerAssetCollections:@[] withType:PHAssetCollectionTypeSmartAlbum
                               andSubtype:PHAssetCollectionSubtypeAny];
        [fetcher registerCollectionList:transientList withAssetCollections:@[]];
        [fetcher registerAssetCollections:@[] withCollectionList:transientList];
        NSURL *url = [NSURL ptn_photoKitMetaAlbumWithType:PHAssetCollectionTypeSmartAlbum
                      subalbums:{PHAssetCollectionSubtypeSmartAlbumFavorites}];

        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        expect(recorder).will.sendValuesWithCount(1);
        expect(recorder).notTo.error();
      });
    });
  });

  context(@"fetch options", ^{
    __block id fetcherMock;
    __block PTNPhotoKitAssetManager *assetManager;

    beforeEach(^{
      fetcherMock = OCMProtocolMock(@protocol(PTNPhotoKitFetcher));
      assetManager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcherMock observer:observer
                                                         imageManager:imageManager
                                                 assetResourceManager:assetResourceManager
                                                 authorizationManager:authorizationManager
                                                        changeManager:changeManager
                                                         imageResizer:imageResizer];
    });

    it(@"should fetch album type with fetch options", ^{
      PHFetchOptions *options = OCMClassMock(PHFetchOptions.class);
      NSURL *url = OCMClassMock(NSURL.class);
      OCMStub([url ptn_photoKitURLType]).andReturn($(PTNPhotoKitURLTypeAlbumType));
      OCMStub([url ptn_photoKitAlbumType]).andReturn(@(PHAssetCollectionTypeSmartAlbum));
      OCMStub([url ptn_photoKitAlbumSubtype])
          .andReturn(@(PHAssetCollectionSubtypeSmartAlbumBursts));
      OCMStub([url ptn_photoKitAlbumFetchOptions]).andReturn(options);

      auto asset = PTNPhotoKitCreateAsset(nil);
      OCMExpect([fetcherMock
                 fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                 subtype:PHAssetCollectionSubtypeSmartAlbumBursts
                 options:options]).andReturn(@[asset]);
      OCMExpect([fetcherMock fetchAssetsInAssetCollection:OCMOCK_ANY options:OCMOCK_ANY])
          .andReturn(asset);

      [[assetManager fetchAlbumWithURL:url] subscribeNext:^(id) {}];

      OCMVerifyAllWithDelay(fetcherMock, 1);
    });

    it(@"should fetch meta album type with fetch options", ^{
      NSURL *url = [NSURL ptn_photoKitUserAlbumsWithTitle:@"bar"];

      OCMExpect([fetcherMock
                 fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                 subtype:PHAssetCollectionSubtypeAny
                 options:[OCMArg checkWithBlock:^BOOL(PHFetchOptions *options) {
                   return PTNPHFetchOptionsEquals(url.ptn_photoKitAlbumFetchOptions, options);
                 }]]).andReturn(@[PTNPhotoKitCreateAsset(@"foo")]);

      expect([assetManager fetchAlbumWithURL:url]).will.sendValuesWithCount(1);

      OCMVerifyAll(fetcherMock);
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

  it(@"should be able deallocate after fetching an asset", ^{
    __weak PTNPhotoKitAssetManager *weakAssetManager;
    @autoreleasepool {
      auto *assetManager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher
                                                                   observer:observer
                                                               imageManager:imageManager
                                                       assetResourceManager:assetResourceManager
                                                       authorizationManager:authorizationManager
                                                              changeManager:changeManager
                                                               imageResizer:imageResizer];
      weakAssetManager = assetManager;
      NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
      expect([manager fetchDescriptorWithURL:url]).will.sendValues(@[asset]);
    }
    expect(weakAssetManager).to.beNil();
  });

  it(@"should fetch asset when it exists only in Photo Stream album", ^{
    id photoStreamAlbum = PTNPhotoKitCreateAssetCollection(@"baz");
    id assetInPhotoStream = PTNPhotoKitCreateAsset(@"blip");
    [fetcher registerAssets:@[assetInPhotoStream] withAssetCollection:photoStreamAlbum];
    [fetcher registerAssetCollections:@[photoStreamAlbum] withType:PHAssetCollectionTypeAlbum
                           andSubtype:PHAssetCollectionSubtypeAlbumMyPhotoStream];

    NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:assetInPhotoStream];
    expect([manager fetchDescriptorWithURL:url]).will.sendValues(@[assetInPhotoStream]);
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
    [fetcher registerAssetCollections:@[] withType:PHAssetCollectionTypeAlbum
                           andSubtype:PHAssetCollectionSubtypeAlbumMyPhotoStream];
    id newAsset = PTNPhotoKitCreateAsset(@"bar");
    NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:newAsset];
    expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetNotFound;
    });
  });

  it(@"should error on meta album URL", ^{
    NSURL *url = [NSURL ptn_photoKitSmartAlbums];

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
                                                 resizeMode:PTNImageResizeModeFast
                                            includeMetadata:NO];

    image = [[UIImage alloc] init];
    imageAsset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:asset];

    defaultError = [NSError errorWithDomain:@"foo" code:1337 userInfo:nil];
  });

  it(@"should make requests with network access allowed", ^{
    id<PTNPhotoKitImageManager> imageManager = OCMProtocolMock(@protocol(PTNPhotoKitImageManager));
    auto assetManager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher observer:observer
                                                            imageManager:imageManager
                                                    assetResourceManager:assetResourceManager
                                                    authorizationManager:authorizationManager
                                                           changeManager:changeManager
                                                            imageResizer:imageResizer];
    OCMExpect([[(id)imageManager ignoringNonObjectArgs] requestImageForAsset:asset targetSize:size
        contentMode:PHImageContentModeDefault
        options:[OCMArg checkWithBlock:^BOOL(PHImageRequestOptions *options) {
          return options.isNetworkAccessAllowed;
        }] resultHandler:([OCMArg invokeBlockWithArgs:image, @{}, nil])]);

    expect([assetManager fetchImageWithDescriptor:asset resizingStrategy:resizingStrategy
                                          options:options]).will.complete();
    OCMVerifyAll(imageManager);
  });

  context(@"fetch image of asset", ^{
    it(@"should fetch image", ^{
      [imageManager serveAsset:asset withProgress:@[] image:image];

      RACSignal *values = [manager fetchImageWithDescriptor:asset
                                           resizingStrategy:resizingStrategy
                                                    options:options];

      expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:imageAsset]]);
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
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5],
        [[LTProgress alloc] initWithProgress:1],
        [[LTProgress alloc] initWithResult:imageAsset]
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
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5],
        [[LTProgress alloc] initWithProgress:1],
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
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5]
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

      expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:imageAsset]]);
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

    beforeEach(^{
      asset = PTNPhotoKitCreateAsset(@"baz", size);
      imageManagerMock = OCMProtocolMock(@protocol(PTNPhotoKitImageManager));
      manager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher observer:observer
                                                    imageManager:imageManagerMock
                                            assetResourceManager:assetResourceManager
                                            authorizationManager:authorizationManager
                                                   changeManager:changeManager
                                                    imageResizer:imageResizer];
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

context(@"fetch image with metadata", ^{
  __block PTNImageFetchOptions *options;
  __block id<PTNResizingStrategy> resizingStrategy;

  beforeEach(^{
    options = [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeOpportunistic
                                                 resizeMode:PTNImageResizeModeFast
                                            includeMetadata:YES];
    resizingStrategy = [PTNResizingStrategy identity];
  });

  it(@"should fetch asset", ^{
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"PTNImageMetadataImage"
                                                          withExtension:@"jpg"];
    PHContentEditingInput *contentEditingInput = PTNPhotoKitCreateImageContentEditingInput(url);
    id<PTNDescriptor> descriptor =
        PTNPhotoKitCreateAssetForContentEditing(@"foo", contentEditingInput, nil, 0);
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
    OCMStub([imageResizer resizeImageAtURL:url resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:image]);

    LLSignalTestRecorder *recorder = [[manager fetchImageWithDescriptor:descriptor
                                                       resizingStrategy:resizingStrategy
                                                                options:options] testRecorder];

    expect(recorder.valuesSentCount).will.equal(1);
    LTProgress<PTNStaticImageAsset *> *imageAsset = (LTProgress *)recorder.values[0];
    expect(imageAsset.result.image).to.equal(image);
    expect(imageAsset.result.imageMetadata).notTo.beNil();
  });

  it(@"should fetch key image for asset collections", ^{
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"PTNImageMetadataImage"
                                                          withExtension:@"jpg"];
    PHContentEditingInput *contentEditingInput = PTNPhotoKitCreateImageContentEditingInput(url);
    id<PTNDescriptor> descriptor =
        PTNPhotoKitCreateAssetForContentEditing(@"foo", contentEditingInput, nil, 0);
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
    PHAssetCollection *assetCollection = PTNPhotoKitCreateAssetCollection(@"foo");
    [fetcher registerAssetCollection:assetCollection];
    PHAsset *asset = PTNPhotoKitCreateAsset(@"bar");
    [fetcher registerAsset:asset asKeyAssetOfAssetCollection:assetCollection];
    OCMStub([imageResizer resizeImageAtURL:url resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:image]);

    LLSignalTestRecorder *recorder = [[manager fetchImageWithDescriptor:descriptor
                                                       resizingStrategy:resizingStrategy
                                                                options:options] testRecorder];

    expect(recorder.valuesSentCount).will.equal(1);
    LTProgress<PTNStaticImageAsset *> *imageAsset = (LTProgress *)recorder.values[0];
    expect(imageAsset.result.image).to.equal(image);
    expect(imageAsset.result.imageMetadata).notTo.beNil();
  });

  it(@"should use normal path for AV assets", ^{
    PHAsset *descriptor = PTNPhotoKitCreateAsset(@"foo", @[kPTNDescriptorTraitAudiovisualKey]);
    UIImage *image = [[UIImage alloc] init];
    PTNPhotoKitImageAsset *imageAsset = [[PTNPhotoKitImageAsset alloc] initWithImage:image
                                                                               asset:descriptor];
    [imageManager serveAsset:descriptor withProgress:@[] image:image];

    RACSignal *values = [manager fetchImageWithDescriptor:descriptor
                                         resizingStrategy:resizingStrategy
                                                  options:options];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:imageAsset]]);
  });

  it(@"should err when requesting metadata fails", ^{
    NSURL *url = [NSURL fileURLWithPath:@"/foo/bar/baz.jpg"];
    PHContentEditingInput *contentEditingInput = PTNPhotoKitCreateImageContentEditingInput(url);
    id<PTNDescriptor> descriptor =
        PTNPhotoKitCreateAssetForContentEditing(@"foo", contentEditingInput, nil, 0);
    RACSignal *values = [manager fetchImageWithDescriptor:descriptor
                                         resizingStrategy:resizingStrategy
                                                  options:options];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
    });
  });

  it(@"should err when content editing fullSizeImageURL key is nil", ^{
    PHContentEditingInput *contentEditingInput = PTNPhotoKitCreateImageContentEditingInput(nil);
    id<PTNDescriptor> descriptor =
        PTNPhotoKitCreateAssetForContentEditing(@"foo", contentEditingInput, nil, 0);
    RACSignal *values = [manager fetchImageWithDescriptor:descriptor
                                         resizingStrategy:resizingStrategy
                                                  options:options];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
    });
  });

  it(@"should err when empty content editing input is received", ^{
    id<PTNDescriptor> descriptor = PTNPhotoKitCreateAssetForContentEditing(@"foo", nil, nil, 0);

    RACSignal *values = [manager fetchImageWithDescriptor:descriptor
                                         resizingStrategy:resizingStrategy
                                                  options:options];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetLoadingFailed;
    });
  });

  it(@"should cancel metadata request upon disposal", ^{
    PHAsset *descriptor = PTNPhotoKitCreateAssetForContentEditing(@"foo", nil, nil, 1337);
    OCMExpect([descriptor cancelContentEditingInputRequest:1337]);

    [[[manager fetchImageWithDescriptor:descriptor
                       resizingStrategy:resizingStrategy
                                options:options] subscribeNext:^(id) {}] dispose];

    OCMVerifyAllWithDelay(descriptor, 1);
  });
});

context(@"AVAsset fetching", ^{
  __block id asset;
  __block PTNAVAssetFetchOptions *options;
  __block id<PTNAudiovisualAsset> videoAsset;
  __block AVURLAsset *avasset;
  __block AVAudioMix *audioMix;

  __block NSError *defaultError;

  beforeEach(^{
    asset = PTNPhotoKitCreateAsset(@"foo");
    [fetcher registerAsset:asset];

    options = [PTNAVAssetFetchOptions optionsWithDeliveryMode:PTNAVAssetDeliveryModeFastFormat];

    avasset = OCMClassMock([AVURLAsset class]);
    OCMStub([avasset URL]).andReturn(@"foo");
    audioMix = OCMClassMock([AVAudioMix class]);
    videoAsset = [[PTNAudiovisualAsset alloc] initWithAVAsset:avasset];

    defaultError = [NSError errorWithDomain:@"foo" code:1337 userInfo:nil];
  });

  it(@"should make requests with network access allowed", ^{
    id<PTNPhotoKitImageManager> imageManager = OCMProtocolMock(@protocol(PTNPhotoKitImageManager));
    auto assetManager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher observer:observer
                                                            imageManager:imageManager
                                                    assetResourceManager:assetResourceManager
                                                    authorizationManager:authorizationManager
                                                           changeManager:changeManager
                                                            imageResizer:imageResizer];
    OCMExpect([imageManager requestAVAssetForVideo:asset
        options:[OCMArg checkWithBlock:^BOOL(PHVideoRequestOptions *options) {
          return options.isNetworkAccessAllowed;
        }] resultHandler:([OCMArg invokeBlockWithArgs:avasset, audioMix, @{}, nil])]);

    expect([assetManager fetchAVAssetWithDescriptor:asset options:options]).will.complete();
    OCMVerifyAll(imageManager);
  });

  context(@"Live Photo asset", ^{
    __block PHLivePhoto *livePhoto;

    beforeEach(^{
      OCMStub([asset descriptorTraits])
          .andReturn([NSSet setWithObject:kPTNDescriptorTraitLivePhotoKey]);
      OCMStub([asset pixelWidth]).andReturn(13);
      OCMStub([asset pixelHeight]).andReturn(37);

      livePhoto = OCMClassMock([PHLivePhoto class]);
      OCMStub([livePhoto valueForKey:@"videoAsset"]).andReturn(avasset);
    });

    it(@"should make requests with network access allowed and high quality delivery mode", ^{
      id<PTNPhotoKitImageManager> imageManager =
          OCMProtocolMock(@protocol(PTNPhotoKitImageManager));
      auto assetManager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher
                                                                  observer:observer
                                                              imageManager:imageManager
                                                      assetResourceManager:assetResourceManager
                                                      authorizationManager:authorizationManager
                                                             changeManager:changeManager
                                                              imageResizer:imageResizer];
      OCMExpect([imageManager requestLivePhotoForAsset:asset targetSize:CGSizeMake(13, 37)
          contentMode:PHImageContentModeDefault
          options:[OCMArg checkWithBlock:^BOOL(PHLivePhotoRequestOptions *options) {
            return options.isNetworkAccessAllowed;
          }] resultHandler:([OCMArg invokeBlockWithArgs:livePhoto, @{}, nil])]);
      expect([assetManager fetchAVAssetWithDescriptor:asset options:options]).will.complete();
      OCMVerifyAll(imageManager);
    });

    context(@"fetch video of asset", ^{
      it(@"should fetch AVAsset", ^{
        [imageManager serveAsset:asset withProgress:@[] livePhoto:livePhoto];

        RACSignal *values = [manager fetchAVAssetWithDescriptor:asset options:options];

        expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:videoAsset]]);
      });

      it(@"should complete after fetching an AVAsset", ^{
        [imageManager serveAsset:asset withProgress:@[] livePhoto:livePhoto];

        RACSignal *values = [manager fetchAVAssetWithDescriptor:asset options:options];

        expect(values).will.sendValuesWithCount(1);
        expect(values).will.complete();
      });

      it(@"should fetch downloaded video with progress", ^{
        [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] livePhoto:livePhoto];

        expect([manager fetchAVAssetWithDescriptor:asset options:options]).will.sendValues(@[
          [[LTProgress alloc] initWithProgress:0.25],
          [[LTProgress alloc] initWithProgress:0.5],
          [[LTProgress alloc] initWithProgress:1],
          [[LTProgress alloc] initWithResult:videoAsset]
        ]);
      });

      it(@"should cancel request upon disposal", ^{
        RACSignal *values = [manager fetchAVAssetWithDescriptor:asset options:options];

        RACDisposable *subscriber = [values subscribeNext:^(id) {}];
        expect([imageManager isRequestIssuedForAsset:asset]).will.beTruthy();

        [subscriber dispose];
        expect([imageManager isRequestCancelledForAsset:asset]).will.beTruthy();
      });

      it(@"should err on error after progress finished", ^{
        [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] finallyError:defaultError];

        RACSignal *values = [manager fetchAVAssetWithDescriptor:asset options:options];

        expect(values).will.sendValues(@[
          [[LTProgress alloc] initWithProgress:0.25],
          [[LTProgress alloc] initWithProgress:0.5],
          [[LTProgress alloc] initWithProgress:1],
        ]);

        expect(values).will.matchError(^BOOL(NSError *error) {
          return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
        });
      });

      it(@"should err on progress download error", ^{
        [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1]
                 errorInProgress:defaultError];

        RACSignal *values = [manager fetchAVAssetWithDescriptor:asset options:options];

        expect(values).will.sendValues(@[
          [[LTProgress alloc] initWithProgress:0.25],
          [[LTProgress alloc] initWithProgress:0.5]
        ]);

        expect(values).will.matchError(^BOOL(NSError *error) {
          return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
        });
      });

      context(@"thread transitions", ^{
        it(@"should not operate on the main thread", ^{
          [imageManager serveAsset:asset withProgress:@[] livePhoto:livePhoto];

          RACSignal *values = [manager fetchAVAssetWithDescriptor:asset options:options];

          expect(values).will.sendValuesWithCount(1);
          expect(fetcher.operatingThreads).notTo.contain([NSThread mainThread]);
        });
      });
    });
  });

  context(@"fetch video of asset", ^{
    it(@"should fetch AVAsset", ^{
      [imageManager serveAsset:asset withProgress:@[] avasset:avasset audioMix:audioMix];

      RACSignal *values = [manager fetchAVAssetWithDescriptor:asset options:options];

      expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:videoAsset]]);
    });

    it(@"should complete after fetching an AVAsset", ^{
      [imageManager serveAsset:asset withProgress:@[] avasset:avasset audioMix:audioMix];

      RACSignal *values = [manager fetchAVAssetWithDescriptor:asset options:options];

      expect(values).will.sendValuesWithCount(1);
      expect(values).will.complete();
    });

    it(@"should fetch downloaded video with progress", ^{
      [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] avasset:avasset
                      audioMix:audioMix];

      expect([manager fetchAVAssetWithDescriptor:asset options:options]).will.sendValues(@[
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5],
        [[LTProgress alloc] initWithProgress:1],
        [[LTProgress alloc] initWithResult:videoAsset]
      ]);
    });

    it(@"should cancel request upon disposal", ^{
      RACSignal *values = [manager fetchAVAssetWithDescriptor:asset options:options];

      RACDisposable *subscriber = [values subscribeNext:^(id) {}];
      expect([imageManager isRequestIssuedForAsset:asset]).will.beTruthy();

      [subscriber dispose];
      expect([imageManager isRequestCancelledForAsset:asset]).will.beTruthy();
    });

    it(@"should err on error after progress finished", ^{
      [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] finallyError:defaultError];

      RACSignal *values = [manager fetchAVAssetWithDescriptor:asset options:options];

      expect(values).will.sendValues(@[
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5],
        [[LTProgress alloc] initWithProgress:1],
      ]);

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
      });
    });

    it(@"should err on progress download error", ^{
      [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] errorInProgress:defaultError];

      RACSignal *values = [manager fetchAVAssetWithDescriptor:asset options:options];

      expect(values).will.sendValues(@[
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5]
      ]);

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
      });
    });

    context(@"thread transitions", ^{
      it(@"should not operate on the main thread", ^{
        [imageManager serveAsset:asset withProgress:@[]  avasset:avasset audioMix:audioMix];

        RACSignal *values = [manager fetchAVAssetWithDescriptor:asset options:options];

        expect(values).will.sendValuesWithCount(1);
        expect(fetcher.operatingThreads).notTo.contain([NSThread mainThread]);
      });
    });
  });
});

context(@"image data fetching", ^{
  static auto const kUniformTypeIdentifier = @"public.cool.raw.format";
  static auto const kFullSizeUniformTypeIdentifier = @"com.foo.bar.baz";

  __block PHAsset *asset;
  __block NSArray<PHAssetResource *> *resources;
  __block id<PTNImageDataAsset> imageDataAsset;
  __block NSData *imageData;
  __block NSError *defaultError;

  beforeEach(^{
    uint8_t buffer[] = {0x1, 0x2, 0x3, 0x4};
    imageData = [NSData dataWithBytes:buffer length:sizeof(buffer)];
    imageDataAsset = [[PTNImageDataAsset alloc] initWithData:imageData
                                       uniformTypeIdentifier:kUniformTypeIdentifier];

    defaultError = [NSError errorWithDomain:@"foo" code:1337 userInfo:nil];

    asset = PTNPhotoKitCreateAsset(@"foo");
    OCMStub([asset descriptorTraits]).andReturn([NSSet setWithObject:kPTNDescriptorTraitRawKey]);
    [fetcher registerAsset:asset];

    resources = @[PTNPhotoKitCreateAssetResource(asset.localIdentifier, PHAssetResourceTypePhoto,
                                                 kUniformTypeIdentifier)];
    [fetcher registerAssetResources:resources withAsset:asset];
  });

  it(@"should make requests with network access allowed", ^{
    id<PTNPhotoKitAssetResourceManager> assetResourceManager =
        OCMProtocolMock(@protocol(PTNPhotoKitAssetResourceManager));
    auto assetManager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher observer:observer
                                                            imageManager:imageManager
                                                    assetResourceManager:assetResourceManager
                                                    authorizationManager:authorizationManager
                                                           changeManager:changeManager
                                                            imageResizer:imageResizer];
    OCMExpect([assetResourceManager requestDataForAssetResource:resources.firstObject
        options:[OCMArg checkWithBlock:^BOOL(PHAssetResourceRequestOptions *options) {
          return options.isNetworkAccessAllowed;
        }]
        dataReceivedHandler:([OCMArg invokeBlockWithArgs:imageData, nil])
        completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null], nil])]);

    expect([assetManager fetchImageDataWithDescriptor:asset]).will.complete();
    OCMVerifyAll(assetResourceManager);
  });

  context(@"fetch image data of asset", ^{
    it(@"should fetch image data", ^{
      [assetResourceManager serveResource:resources.firstObject withProgress:@[] data:imageData];

      RACSignal *values = [manager fetchImageDataWithDescriptor:asset];

      expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:imageDataAsset]]);
    });

    it(@"should complete after fetching image data", ^{
      [assetResourceManager serveResource:resources.firstObject withProgress:@[] data:imageData];

      RACSignal *values = [manager fetchImageDataWithDescriptor:asset];

      expect(values).will.sendValuesWithCount(1);
      expect(values).will.complete();
    });

    it(@"should fetch downloaded image data with progress", ^{
      [assetResourceManager serveResource:resources.firstObject withProgress:@[@0.25, @0.5, @1]
                                     data:imageData];

      expect([manager fetchImageDataWithDescriptor:asset]).will.sendValues(@[
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5],
        [[LTProgress alloc] initWithProgress:1],
        [[LTProgress alloc] initWithResult:imageDataAsset]
      ]);
    });

    it(@"should cancel request upon disposal", ^{
      RACSignal *values = [manager fetchImageDataWithDescriptor:asset];

      RACDisposable *subscriber = [values subscribeNext:^(id) {}];
      expect([assetResourceManager isRequestIssuedForResource:resources.firstObject])
          .will.beTruthy();

      [subscriber dispose];
      expect([assetResourceManager isRequestCancelledForResource:resources.firstObject])
          .will.beTruthy();
    });

    it(@"should err on error after progress finished", ^{
      [assetResourceManager serveResource:resources.firstObject withProgress:@[@0.25, @0.5, @1]
                             finallyError:defaultError];

      RACSignal *values = [manager fetchImageDataWithDescriptor:asset];

      expect(values).will.sendValues(@[
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5],
        [[LTProgress alloc] initWithProgress:1]
      ]);

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == PTNErrorCodeAssetLoadingFailed &&
            error.lt_underlyingError;
      });
    });

    it(@"should err on progress download error", ^{
      [assetResourceManager serveResource:resources.firstObject withProgress:@[@0.25, @0.5]
                             finallyError:defaultError];

      RACSignal *values = [manager fetchImageDataWithDescriptor:asset];

      expect(values).will.sendValues(@[
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5]
      ]);

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == PTNErrorCodeAssetLoadingFailed &&
            error.lt_underlyingError;
      });
    });

    it(@"should prefer full size photo resource over regular photo", ^{
      resources = @[
        PTNPhotoKitCreateAssetResource(asset.localIdentifier, PHAssetResourceTypePhoto,
                                       kUniformTypeIdentifier),
        PTNPhotoKitCreateAssetResource(asset.localIdentifier, PHAssetResourceTypeFullSizePhoto,
                                       kFullSizeUniformTypeIdentifier)
      ];
      [fetcher registerAssetResources:resources withAsset:asset];

      for (PHAssetResource *resource in resources) {
        [assetResourceManager serveResource:resource withProgress:@[] data:imageData];
      }

      RACSignal *values = [manager fetchImageDataWithDescriptor:asset];

      auto fullSizeImageDataAsset = [[PTNImageDataAsset alloc]
                                     initWithData:imageData
                                     uniformTypeIdentifier:kFullSizeUniformTypeIdentifier];
      expect(values).will.sendValues(@[[[LTProgress alloc]
                                        initWithResult:fullSizeImageDataAsset]]);
    });

    it(@"should err when requesting image data for video only asset", ^{
      resources = @[
        PTNPhotoKitCreateAssetResource(asset.localIdentifier, PHAssetResourceTypeVideo,
                                       kUniformTypeIdentifier)
      ];
      [fetcher registerAssetResources:resources withAsset:asset];

      for (PHAssetResource *resource in resources) {
        [assetResourceManager serveResource:resource withProgress:@[] data:imageData];
      }

      expect([manager fetchImageDataWithDescriptor:asset]).will.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == PTNErrorCodeInvalidAssetType;
      });
    });

    context(@"thread transitions", ^{
      it(@"should not operate on the main thread", ^{
        [assetResourceManager serveResource:resources.firstObject withProgress:@[] data:imageData];

        RACSignal *values = [manager fetchImageDataWithDescriptor:asset];

        expect(values).will.sendValuesWithCount(1);
        expect(fetcher.operatingThreads).notTo.contain([NSThread mainThread]);
      });
    });
  });
});

context(@"AV preview fetching", ^{
  __block id asset;
  __block PTNAVAssetFetchOptions *options;
  __block AVPlayerItem *playerItem;
  __block NSError *defaultError;

  beforeEach(^{
    asset = PTNPhotoKitCreateAsset(@"foo");
    [fetcher registerAsset:asset];

    options = [PTNAVAssetFetchOptions optionsWithDeliveryMode:PTNAVAssetDeliveryModeFastFormat];

    playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"foo://bar"]];
    defaultError = [NSError errorWithDomain:@"foo" code:1337 userInfo:nil];
  });

  it(@"should make requests with network access allowed", ^{
    id<PTNPhotoKitImageManager> imageManager = OCMProtocolMock(@protocol(PTNPhotoKitImageManager));
    auto assetManager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher observer:observer
                                                            imageManager:imageManager
                                                    assetResourceManager:assetResourceManager
                                                    authorizationManager:authorizationManager
                                                           changeManager:changeManager
                                                            imageResizer:imageResizer];
    OCMExpect([imageManager requestPlayerItemForVideo:asset
        options:[OCMArg checkWithBlock:^BOOL(PHVideoRequestOptions *options) {
          return options.isNetworkAccessAllowed;
        }] resultHandler:([OCMArg invokeBlockWithArgs:playerItem, @{}, nil])]);

    expect([assetManager fetchAVPreviewWithDescriptor:asset options:options]).will.complete();
    OCMVerifyAll(imageManager);
  });

  context(@"Live Photo asset", ^{
    __block PHLivePhoto *livePhoto;
    __block AVAsset *avasset;

    beforeEach(^{
      OCMStub([asset descriptorTraits])
          .andReturn([NSSet setWithObject:kPTNDescriptorTraitLivePhotoKey]);
      OCMStub([asset pixelWidth]).andReturn(13);
      OCMStub([asset pixelHeight]).andReturn(37);

      avasset = [AVAsset assetWithURL:[NSURL URLWithString:@"file://foo"]];
      livePhoto = OCMClassMock([PHLivePhoto class]);
      OCMStub([livePhoto valueForKey:@"videoAsset"]).andReturn(avasset);
    });

    it(@"should make requests with network access allowed and high quality delivery mode", ^{
      id<PTNPhotoKitImageManager> imageManager =
          OCMProtocolMock(@protocol(PTNPhotoKitImageManager));
      auto assetManager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher
                                                                  observer:observer
                                                              imageManager:imageManager
                                                      assetResourceManager:assetResourceManager
                                                      authorizationManager:authorizationManager
                                                             changeManager:changeManager
                                                              imageResizer:imageResizer];
      OCMExpect([imageManager requestLivePhotoForAsset:asset targetSize:CGSizeMake(13, 37)
          contentMode:PHImageContentModeDefault
          options:[OCMArg checkWithBlock:^BOOL(PHLivePhotoRequestOptions *options) {
            return options.isNetworkAccessAllowed;
          }] resultHandler:([OCMArg invokeBlockWithArgs:livePhoto, @{}, nil])]);
      expect([assetManager fetchAVPreviewWithDescriptor:asset options:options]).will.complete();
      OCMVerifyAll(imageManager);
    });

    context(@"fetch preview of asset", ^{
      it(@"should fetch player item", ^{
        [imageManager serveAsset:asset withProgress:@[] livePhoto:livePhoto];

        RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

        expect(values).will.matchValue(0, ^BOOL(LTProgress<AVPlayerItem *> *progress) {
          return [progress.result.asset isEqual:avasset];
        });
      });

      it(@"should complete after fetching player item", ^{
        [imageManager serveAsset:asset withProgress:@[] livePhoto:livePhoto];

        RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

        expect(values).will.sendValuesWithCount(1);
        expect(values).will.complete();
      });

      it(@"should fetch player item with progress", ^{
        [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] livePhoto:livePhoto];

        RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

        expect(values).will.sendValue(0, [[LTProgress alloc] initWithProgress:0.25]);
        expect(values).will.sendValue(1, [[LTProgress alloc] initWithProgress:0.5]);
        expect(values).will.sendValue(2, [[LTProgress alloc] initWithProgress:1]);
        expect(values).will.matchValue(3, ^BOOL(LTProgress<AVPlayerItem *> *progress) {
          return [progress.result.asset isEqual:avasset];
        });
      });

      it(@"should cancel request upon disposal", ^{
        RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

        RACDisposable *subscriber = [values subscribeNext:^(id) {}];
        expect([imageManager isRequestIssuedForAsset:asset]).will.beTruthy();

        [subscriber dispose];
        expect([imageManager isRequestCancelledForAsset:asset]).will.beTruthy();
      });

      it(@"should err on error after progress finished", ^{
        [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] finallyError:defaultError];

        RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

        expect(values).will.sendValues(@[
          [[LTProgress alloc] initWithProgress:0.25],
          [[LTProgress alloc] initWithProgress:0.5],
          [[LTProgress alloc] initWithProgress:1],
        ]);

        expect(values).will.matchError(^BOOL(NSError *error) {
          return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
        });
      });

      it(@"should err on progress download error", ^{
        [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1]
                 errorInProgress:defaultError];

        RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

        expect(values).will.sendValues(@[
          [[LTProgress alloc] initWithProgress:0.25],
          [[LTProgress alloc] initWithProgress:0.5]
        ]);

        expect(values).will.matchError(^BOOL(NSError *error) {
          return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
        });
      });

      context(@"thread transitions", ^{
        it(@"should not operate on the main thread", ^{
          [imageManager serveAsset:asset withProgress:@[] livePhoto:livePhoto];

          RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

          expect(values).will.sendValuesWithCount(1);
          expect(fetcher.operatingThreads).notTo.contain([NSThread mainThread]);
        });
      });
    });
  });

  context(@"fetch preview of asset", ^{
    it(@"should fetch player item", ^{
      [imageManager serveAsset:asset withProgress:@[] playerItem:playerItem];

      RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

      expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:playerItem]]);
    });

    it(@"should complete after fetching player item", ^{
      [imageManager serveAsset:asset withProgress:@[] playerItem:playerItem];

      RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

      expect(values).will.sendValuesWithCount(1);
      expect(values).will.complete();
    });

    it(@"should fetch player item with progress", ^{
      [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] playerItem:playerItem];

      expect([manager fetchAVPreviewWithDescriptor:asset options:options]).will.sendValues(@[
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5],
        [[LTProgress alloc] initWithProgress:1],
        [[LTProgress alloc] initWithResult:playerItem]
      ]);
    });

    it(@"should cancel request upon disposal", ^{
      RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

      RACDisposable *subscriber = [values subscribeNext:^(id) {}];
      expect([imageManager isRequestIssuedForAsset:asset]).will.beTruthy();

      [subscriber dispose];
      expect([imageManager isRequestCancelledForAsset:asset]).will.beTruthy();
    });

    it(@"should err on error after progress finished", ^{
      [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] finallyError:defaultError];

      RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

      expect(values).will.sendValues(@[
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5],
        [[LTProgress alloc] initWithProgress:1],
      ]);

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
      });
    });

    it(@"should err on progress download error", ^{
      [imageManager serveAsset:asset withProgress:@[@0.25, @0.5, @1] errorInProgress:defaultError];

      RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

      expect(values).will.sendValues(@[
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5]
      ]);

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetLoadingFailed && error.lt_underlyingError;
      });
    });

    context(@"thread transitions", ^{
      it(@"should not operate on the main thread", ^{
        [imageManager serveAsset:asset withProgress:@[] playerItem:playerItem];

        RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

        expect(values).will.sendValuesWithCount(1);
        expect(fetcher.operatingThreads).notTo.contain([NSThread mainThread]);
      });
    });

    it(@"should error when not authorized", ^{
      authorizationManager.authorizationStatus = $(PTNAuthorizationStatusNotDetermined);

      RACSignal *values = [manager fetchAVPreviewWithDescriptor:asset options:options];

      expect(values).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeNotAuthorized;
      });
    });
  });
});

it(@"should err when fetching AV data", ^{
  RACSignal *values = [manager fetchAVDataWithDescriptor:PTNPhotoKitCreateAsset(@"foo")];

  expect(values).will.matchError(^BOOL(NSError *error) {
    return error.code == PTNErrorCodeUnsupportedOperation;
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

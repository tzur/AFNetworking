// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAssetManager.h"

#import <Photos/Photos.h>

#import "NSError+Photons.h"
#import "NSURL+PhotoKit.h"
#import "PTNAlbumChangeset+PhotoKit.h"
#import "PTNDescriptor.h"
#import "PTNImageFetchOptions+PhotoKit.h"
#import "PTNImageAsset.h"
#import "PTNPhotoKitAlbum.h"
#import "PTNPhotoKitFakeFetcher.h"
#import "PTNPhotoKitFakeImageManager.h"
#import "PTNPhotoKitFakeObserver.h"
#import "PTNPhotoKitImageManager.h"
#import "PTNPhotoKitTestUtils.h"
#import "PTNPhotokitImageAsset.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"

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
    
    context(@"thread transitions", ^{
      it(@"should not operate on the main thread", ^{
        RACSignal *values = [manager fetchAlbumWithURL:url];
        
        expect(values).will.sendValuesWithCount(1);
        expect(values).willNot.deliverValuesOnMainThread();
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

      url = [NSURL ptn_photoKitAlbumOfAlbumsWithType:PTNPhotoKitAlbumOfAlbumsTypeUserAlbums];
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
        id firstCollection = PTNPhotoKitCreateAssetCollectionOfSubtype(@"foo", favorites);
        id secondCollection = PTNPhotoKitCreateAssetCollectionOfSubtype(@"bar", userLibrary);
        id thirdCollection = PTNPhotoKitCreateAssetCollection(@"baz");

        albums = @[firstCollection, secondCollection, thirdCollection];
        albumsSubset = @[secondCollection, firstCollection];

        [fetcher registerAssetCollections:albums withType:PHAssetCollectionTypeSmartAlbum
                               andSubtype:PHAssetCollectionSubtypeAny];

        transientList = OCMClassMock([PHCollectionList class]);
        OCMStub(transientList.localIdentifier).andReturn(@[@"foo"]);

        [fetcher registerCollectionList:transientList withAssetCollecitons:albumsSubset];
        [fetcher registerAssetCollections:albumsSubset withCollectionList:transientList];

        [fetcher registerAssetCollection:firstCollection];
        [fetcher registerAssetCollection:secondCollection];

        url = [NSURL
            ptn_photoKitAlbumOfAlbumsWithType:PTNPhotoKitAlbumOfAlbumsTypePhotosAppSmartAlbums];
      });

      it(@"should update transient album collection on subalbum change", ^{
        id asset = PTNPhotoKitCreateAsset(nil);

        id changeDetails = PTNPhotoKitCreateChangeDetailsForAssets(@[asset]);
        id change = PTNPhotoKitCreateChangeForFetchDetails(changeDetails);

        LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];
        [observer sendChange:change];

        id<PTNAlbum> album = [[PTNPhotoKitAlbum alloc] initWithURL:url fetchResult:albumsSubset];
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

        url = [NSURL ptn_photoKitAlbumOfAlbumsWithType:PTNPhotoKitAlbumOfAlbumsTypeSmartAlbums];
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
    
    context(@"thread transitions", ^{
      it(@"should not operate on the main thread", ^{
        RACSignal *values = [manager fetchAlbumWithURL:url];
        
        expect(values).will.sendValuesWithCount(1);
        expect(values).willNot.deliverValuesOnMainThread();
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
    NSURL *url = [NSURL ptn_photoKitAlbumWithType:PTNPhotoKitAlbumTypeCameraRoll];

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
  
  context(@"thread transitions", ^{
    it(@"should not operate on the main thread", ^{
      NSURL *url = [NSURL ptn_photoKitAssetURLWithAsset:asset];
      
      RACSignal *values = [manager fetchAssetWithURL:url];
      
      expect(values).will.sendValuesWithCount(1);
      expect(values).willNot.deliverValuesOnMainThread();
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
        expect(values).willNot.deliverValuesOnMainThread();
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

  context(@"resizing strategy", ^{
    __block id imageManagerMock;
    __block id<PTNResizingStrategy> resizingStrategy;

    beforeEach(^{
      asset = PTNPhotoKitCreateAssetWithSize(@"baz", size);
      imageManagerMock = OCMProtocolMock(@protocol(PTNPhotoKitImageManager));
      manager = [[PTNPhotoKitAssetManager alloc] initWithFetcher:fetcher observer:observer
                                                    imageManager:imageManagerMock];
      resizingStrategy = OCMProtocolMock(@protocol(PTNResizingStrategy));
    });

    context(@"image size", ^{
      it(@"should request image size from strategy and use it to fetch image", ^{
        OCMStub([resizingStrategy sizeForInputSize:size]).andReturn(CGSizeMake(1337, 1337));
        OCMExpect([imageManagerMock requestImageForAsset:asset
                                              targetSize:CGSizeMake(1337, 1337)
                                             contentMode:0
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
                                             contentMode:0
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

SpecEnd

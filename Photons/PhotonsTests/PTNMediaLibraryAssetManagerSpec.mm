// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNMediaLibraryAssetManager.h"

#import <LTKit/LTRandomAccessCollection.h>
#import <LTKit/NSArray+NSSet.h>
#import <MediaPlayer/MPMediaLibrary.h>

#import "MPMediaItem+Photons.h"
#import "NSError+Photons.h"
#import "NSURL+MediaLibrary.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNAuthorizationManager.h"
#import "PTNAuthorizationStatus.h"
#import "PTNFakeMediaQuery.h"
#import "PTNFakeMediaQueryProvider.h"
#import "PTNImageFetchOptions.h"
#import "PTNMediaLibraryAuthorizationManager.h"
#import "PTNMediaLibraryAuthorizer.h"
#import "PTNMediaLibraryCollectionDescriptor.h"
#import "PTNMediaQueryProvider.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"
#import "PTNStaticImageAsset.h"

static void PTNPostMediaLibraryNotification(NSString *senderName) {
  [[NSNotificationCenter defaultCenter] postNotificationName:MPMediaLibraryDidChangeNotification
                                                      object:senderName];
}

SpecBegin(PTNMediaLibraryAssetManager)

__block PTNMediaLibraryAssetManager *manager;
__block PTNFakeMediaQueryProvider *queryProvider;
__block PTNFakeMediaQuery *query;
__block id<PTNAuthorizationManager> authorizationManager;
__block MPMediaItem *item, *item2;
__block MPMediaItemCollection *collection, *collection2;

beforeEach(^{
  authorizationManager = OCMClassMock([PTNMediaLibraryAuthorizationManager class]);
  OCMStub(authorizationManager.authorizationStatus).andReturn($(PTNAuthorizationStatusAuthorized));

  item = OCMClassMock([MPMediaItem class]);
  OCMStub(item.persistentID).andReturn(123ULL);
  item2 = OCMClassMock([MPMediaItem class]);
  OCMStub(item2.persistentID).andReturn(1234ULL);

  collection = OCMClassMock([MPMediaItemCollection class]);
  OCMStub(collection.representativeItem).andReturn(item);
  collection2 = OCMClassMock([MPMediaItemCollection class]);
  OCMStub(collection2.representativeItem).andReturn(item2);
});

context(@"convenience initializers", ^{
  it(@"should correctly initialize with authorization manager initializer", ^{
    query = [[PTNFakeMediaQuery alloc] initWithItems:@[[[MPMediaItem alloc] init]]];
    queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
    manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider];
    expect(manager).toNot.beNil();
  });

  it(@"should correctly initialize with default initializer", ^{
    manager = [[PTNMediaLibraryAssetManager alloc] init];
    expect(manager).toNot.beNil();
  });
});

context(@"fetching", ^{
  context(@"asset", ^{
    beforeEach(^{
      query = [[PTNFakeMediaQuery alloc] initWithItemsSequence:@[@[item], @[item2]]];
      queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
      manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                                                      authorizationManager:authorizationManager];
    });

    it(@"should fetch asset with URL", ^{
      auto url = [NSURL ptn_mediaLibraryAssetWithItem:item];
      expect([manager fetchDescriptorWithURL:url]).will.sendValues(@[item]);
    });

    it(@"should send new asset upon update", ^{
      auto url = [NSURL ptn_mediaLibraryAssetWithItem:item];
      auto recorder = [[manager fetchDescriptorWithURL:url] testRecorder];
      expect(recorder).will.sendValues(@[item]);

      PTNPostMediaLibraryNotification(@"notification");
      expect(recorder).will.sendValues(@[item, item2]);
    });

    it(@"should not send update when assed did not change", ^{
      auto query = [[PTNFakeMediaQuery alloc] initWithItemsSequence:@[@[item]]];

      auto queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
      auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                      authorizationManager:authorizationManager];

      auto url = [NSURL ptn_mediaLibraryAssetWithItem:item];
      auto recorder = [[manager fetchDescriptorWithURL:url] testRecorder];
      expect(recorder).will.sendValues(@[item]);

      NSLog(@"sending update");
      PTNPostMediaLibraryNotification(@"notification");
      expect(recorder).will.sendValues(@[item]);
    });

    it(@"should not cache assets", ^{
      auto url = [NSURL ptn_mediaLibraryAssetWithItem:item];
      auto signal = [manager fetchDescriptorWithURL:url];

      expect(signal).will.sendValues(@[item]);
      expect(signal).will.sendValues(@[item2]);
    });

    it(@"should error on invalid URL", ^{
      auto url = [NSURL URLWithString:@"http://www.foo.bar"];
      expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeInvalidURL;
      });
    });

    it(@"should error when not authorized", ^{
      PTNMediaLibraryAuthorizationManager *authorizationManager =
          OCMClassMock([PTNMediaLibraryAuthorizationManager class]);
      OCMStub(authorizationManager.authorizationStatus).andReturn($(PTNAuthorizationStatusDenied));
      auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                      authorizationManager:authorizationManager];

      auto url = [NSURL ptn_mediaLibraryAssetWithItem:item];
      expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeNotAuthorized;
      });
    });

    it(@"should error on non-existing asset", ^{
      auto nilQuery = [[PTNFakeMediaQuery alloc] initWithItems:nil];
      auto nilQueryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:nilQuery];
      auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:nilQueryProvider
                      authorizationManager:authorizationManager];

      auto url = [NSURL ptn_mediaLibraryAssetWithItem:item];
      expect([manager fetchDescriptorWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeInvalidAssetType;
      });
    });
  });

  context(@"album", ^{
    __block NSURL *url;
    __block PTNAlbum *album;
    __block PTNAlbumChangeset *changeset;

    beforeEach(^{
      query = [[PTNFakeMediaQuery alloc] initWithItemsSequence:@[@[item], @[item2]]];
      queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
      manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                                                      authorizationManager:authorizationManager];

      url = [NSURL ptn_mediaLibraryAlbumSongs];
      album = [[PTNAlbum alloc] initWithURL:url subalbums:@[item] assets:@[]];
      changeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
    });

    it(@"should fetch album songs with URL", ^{
      auto recorder = [[manager fetchAlbumWithURL:url] testRecorder];
      expect(recorder).will.sendValues(@[changeset]);
    });

    context(@"URLs", ^{
      beforeEach(^{
        query = [[PTNFakeMediaQuery alloc] initWithCollectionsSequence:@[@[collection]]];
        queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
        manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                                                        authorizationManager:authorizationManager];
      });

      it(@"should fetch using URL of music album songs with item", ^{
        auto query = [[PTNFakeMediaQuery alloc] initWithItemsSequence:@[@[item]]];
        auto queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
        auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                        authorizationManager:authorizationManager];
        auto url = [NSURL ptn_mediaLibraryAlbumMusicAlbumSongsWithItem:item];
        auto album = [[PTNAlbum alloc] initWithURL:url subalbums:@[item] assets:@[]];
        auto changeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        auto recorder = [[manager fetchAlbumWithURL:url] testRecorder];

        expect(recorder).will.sendValues(@[changeset]);
      });

      it(@"should fetch using URL of artist music albums with item", ^{
        auto url = [NSURL ptn_mediaLibraryAlbumArtistMusicAlbumsWithItem:item];
        auto descriptorURL = [NSURL ptn_mediaLibraryAlbumMusicAlbumSongsWithItem:item];
        auto descriptor = [[PTNMediaLibraryCollectionDescriptor alloc] initWithCollection:collection
                            url:descriptorURL];
        auto album = [[PTNAlbum alloc] initWithURL:url subalbums:@[descriptor] assets:@[]];
        auto changeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        auto recorder = [[manager fetchAlbumWithURL:url] testRecorder];

        expect(recorder).will.sendValues(@[changeset]);
      });

      it(@"should fetch using URL of artist songs with item", ^{
        auto query = [[PTNFakeMediaQuery alloc] initWithItemsSequence:@[@[item]]];
        auto queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
        auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                        authorizationManager:authorizationManager];
        auto url = [NSURL ptn_mediaLibraryAlbumArtistSongsWithItem:item];
        auto album = [[PTNAlbum alloc] initWithURL:url subalbums:@[item] assets:@[]];
        auto changeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        auto recorder = [[manager fetchAlbumWithURL:url] testRecorder];

        expect(recorder).will.sendValues(@[changeset]);
      });

      it(@"should fetch using URL of songs by music album", ^{
        auto url = [NSURL ptn_mediaLibraryAlbumSongsByMusicAlbum];
        auto descriptorURL = [NSURL ptn_mediaLibraryAlbumMusicAlbumSongsWithItem:item];
        auto descriptor = [[PTNMediaLibraryCollectionDescriptor alloc] initWithCollection:collection
                            url:descriptorURL];
        auto album = [[PTNAlbum alloc] initWithURL:url subalbums:@[descriptor] assets:@[]];
        auto changeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        auto recorder = [[manager fetchAlbumWithURL:url] testRecorder];

        expect(recorder).will.sendValues(@[changeset]);
      });

      it(@"should fetch using URL of songs by artist", ^{
        auto url = [NSURL ptn_mediaLibraryAlbumSongsByAritst];
        auto descriptorURL = [NSURL ptn_mediaLibraryAlbumArtistSongsWithItem:item];
        auto descriptor = [[PTNMediaLibraryCollectionDescriptor alloc] initWithCollection:collection
                          url:descriptorURL];
        auto album = [[PTNAlbum alloc] initWithURL:url subalbums:@[descriptor] assets:@[]];
        auto changeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        auto recorder = [[manager fetchAlbumWithURL:url] testRecorder];

        expect(recorder).will.sendValues(@[changeset]);
      });
    });

    it(@"should send new album asset upon update", ^{
      auto recorder = [[manager fetchAlbumWithURL:url] testRecorder];

      expect(recorder).will.sendValues(@[changeset]);

      auto album2 = [[PTNAlbum alloc] initWithURL:url subalbums:@[item2] assets:@[]];
      auto changeset2 = [PTNAlbumChangeset changesetWithAfterAlbum:album2];
      PTNPostMediaLibraryNotification(@"notificaiton");

      expect(recorder).will.sendValues(@[changeset, changeset2]);
    });

    it(@"should not send update when album did not change", ^{
      auto query = [[PTNFakeMediaQuery alloc] initWithItemsSequence:@[@[item]]];
      auto queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
      auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                      authorizationManager:authorizationManager];
      auto recorder = [[manager fetchAlbumWithURL:url] testRecorder];
      expect(recorder).will.sendValues(@[changeset]);

      PTNPostMediaLibraryNotification(@"notificaiton");
      expect(recorder).will.sendValues(@[changeset]);
    });

    it(@"should not cache album assets", ^{
      auto album2 = [[PTNAlbum alloc] initWithURL:url subalbums:@[item2] assets:@[]];
      auto changeset2 = [PTNAlbumChangeset changesetWithAfterAlbum:album2];
      auto signal = [manager fetchAlbumWithURL:url];

      expect(signal).will.sendValues(@[changeset]);
      expect(signal).will.sendValues(@[changeset2]);
    });

    it(@"should error on invalid URL", ^{
      auto url = [NSURL URLWithString:@"http://www.foo.bar"];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeInvalidURL;
      });
    });

    it(@"should error when not authorized", ^{
      auto authorizationManager = (PTNMediaLibraryAuthorizationManager *)
          OCMClassMock([PTNMediaLibraryAuthorizationManager class]);
      OCMStub(authorizationManager.authorizationStatus).andReturn($(PTNAuthorizationStatusDenied));

      auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                      authorizationManager:authorizationManager];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeNotAuthorized;
      });
    });

    it(@"should error on non-existing collection", ^{
      auto nilQuery = [[PTNFakeMediaQuery alloc] initWithCollectionsSequence:nil];
      auto nilQueryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:nilQuery];
      auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:nilQueryProvider
                      authorizationManager:authorizationManager];
      auto url = [NSURL ptn_mediaLibraryAlbumSongs];

      expect([manager fetchAlbumWithURL:url]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeInvalidAssetType;
      });
    });
  });

  context(@"image", ^{
    __block id<PTNResizingStrategy> resizeStrategy;
    __block PTNImageFetchOptions *options;
    __block MPMediaItemArtwork *artwork;
    __block PTNStaticImageAsset *imageAsset;

    beforeEach(^{
      resizeStrategy = [PTNResizingStrategy identity];
      options = [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeFast
                                                   resizeMode:PTNImageResizeModeFast];
      auto image = [[UIImage alloc] init];
      imageAsset = [[PTNStaticImageAsset alloc] initWithImage:image];
      artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
    });

    it(@"should fetch an image", ^{
      OCMStub(item.artwork).andReturn(artwork);

      auto query = [[PTNFakeMediaQuery alloc] initWithItems:@[item]];
      auto queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
      auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                       authorizationManager:authorizationManager];
      auto signal = [manager fetchImageWithDescriptor:item resizingStrategy:resizeStrategy
                                              options:options];

      expect(signal).will.sendValues(@[[[PTNProgress alloc] initWithResult:imageAsset]]);
    });

    it(@"should err when fetching with invalid descriptor", ^{
      auto query = [[PTNFakeMediaQuery alloc] initWithItems:nil];
      auto queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
      auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                      authorizationManager:authorizationManager];
      auto signal = [manager fetchImageWithDescriptor:(id<PTNDescriptor>)@"foo"
                                     resizingStrategy:resizeStrategy options:options];

      expect(signal).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeInvalidDescriptor;
      });
    });

    it(@"should err when image can not be found", ^{
      auto query = [[PTNFakeMediaQuery alloc] initWithItemsSequence:@[@[item]]];
      auto queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
      auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                      authorizationManager:authorizationManager];
      auto signal = [manager fetchImageWithDescriptor:item resizingStrategy:resizeStrategy
                                              options:options];

      expect(signal).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeKeyAssetsNotFound;
      });
    });

    it(@"should err when descriptor do not have an image", ^{
      OCMStub(item.artwork);

      auto query = [[PTNFakeMediaQuery alloc] initWithItems:@[item]];
      auto queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
      auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                      authorizationManager:authorizationManager];
      auto signal = [manager fetchImageWithDescriptor:item resizingStrategy:resizeStrategy
                                              options:options];

      expect(signal).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeKeyAssetsNotFound;
      });
    });

    it(@"should error when not authorized", ^{
      auto authorizationManager = (PTNMediaLibraryAuthorizationManager *)
          OCMClassMock([PTNMediaLibraryAuthorizationManager class]);
      OCMStub(authorizationManager.authorizationStatus).andReturn($(PTNAuthorizationStatusDenied));

      auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                      authorizationManager:authorizationManager];
      auto signal = [manager fetchImageWithDescriptor:item resizingStrategy:resizeStrategy
                                              options:options];

      expect(signal).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeNotAuthorized;
      });
    });
  });
});

it(@"should err when fetching image data with descriptor", ^{
  auto query = [[PTNFakeMediaQuery alloc] initWithItems:nil];
  auto queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
  auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider
                                                       authorizationManager:authorizationManager];
  auto descriptor = [[MPMediaItem alloc] init];

  expect([manager fetchImageDataWithDescriptor:descriptor]).will.matchError(^BOOL(NSError *error) {
    return error.code == PTNErrorCodeUnsupportedOperation;
  });
});

it(@"should dealloc the manager after fetch signal is disposed", ^{
  __weak PTNMediaLibraryAssetManager *weakManager;
  @autoreleasepool {
    auto query = [[PTNFakeMediaQuery alloc] initWithItemsSequence:@[@[item]]];
    auto queryProvider = [[PTNFakeMediaQueryProvider alloc] initWithQuery:query];
    auto manager = [[PTNMediaLibraryAssetManager alloc] initWithQueryProvider:queryProvider];
    weakManager = manager;
    auto url = [NSURL ptn_mediaLibraryAssetWithItem:item];
    auto disposable = [[manager fetchDescriptorWithURL:url] subscribeNext:^(id) {}];
    [disposable dispose];
  }
  expect(weakManager).will.beNil();
});

SpecEnd

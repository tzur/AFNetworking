// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUAlbumChangesetProvider.h"

#import <Photons/PTNAlbum.h>
#import <Photons/PTNAlbumChangeset.h>
#import <Photons/PTNAlbumChangesetMove.h>
#import <Photons/PTNAssetManager.h>

#import "PTUChangeset.h"
#import "PTUChangesetMove.h"
#import "PhotonsUITestUtils.h"

SpecBegin(PTUAlbumDataSource)

__block id<PTNAssetManager> assetManager;
__block NSURL *url;
__block PTUAlbumChangesetProvider *provider;
__block id<PTNAlbum> album;
__block NSArray *subalbums;
__block NSArray *assets;

beforeEach(^{
  assetManager = OCMProtocolMock(@protocol(PTNAssetManager));
  url = [NSURL URLWithString:@"http://www.foo.com"];
  provider = [[PTUAlbumChangesetProvider alloc] initWithManager:assetManager albumURL:url];

  album = OCMProtocolMock(@protocol(PTNAlbum));
  subalbums = @[@"foo", @"bar"];
  assets = @[@"baz"];
  OCMStub([album subalbums]).andReturn(subalbums);
  OCMStub([album assets]).andReturn(assets);
});

it(@"should map changeset without incremental changes", ^{
  PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
  OCMStub([assetManager fetchAlbumWithURL:url]).andReturn([RACSignal return:changeset]);

  expect([provider fetchChangeset]).to.sendValues(@[
    [[PTUChangeset alloc] initWithAfterDataModel:@[subalbums, assets]]
  ]);
});

it(@"should map changeset with incremental changes", ^{
  id<PTNAlbum> afterAlbum = OCMProtocolMock(@protocol(PTNAlbum));
  id<PTNAlbum> beforeAlbum = OCMProtocolMock(@protocol(PTNAlbum));
  NSArray *subalbums = @[@"foo"];
  NSArray *assets = @[@"bar"];
  OCMStub([beforeAlbum subalbums]).andReturn(subalbums);
  OCMStub([beforeAlbum assets]).andReturn(assets);
  OCMStub([afterAlbum subalbums]).andReturn(subalbums);
  OCMStub([afterAlbum assets]).andReturn(assets);
  NSIndexSet *removed = [[NSIndexSet alloc] initWithIndex:0];
  NSIndexSet *inserted = [[NSIndexSet alloc] initWithIndex:1];
  NSIndexSet *updated = [[NSIndexSet alloc] initWithIndex:2];
  NSArray *moves = @[
    [PTNAlbumChangesetMove changesetMoveFrom:0 to:1],
    [PTNAlbumChangesetMove changesetMoveFrom:1 to:2]
  ];
  id changeset = [PTNAlbumChangeset changesetWithBeforeAlbum:beforeAlbum afterAlbum:afterAlbum
                                              removedIndexes:removed insertedIndexes:inserted
                                              updatedIndexes:updated moves:moves];

  OCMStub([assetManager fetchAlbumWithURL:url]).andReturn([RACSignal return:changeset]);

  NSArray *collectionRemoved = @[[NSIndexPath indexPathForItem:0 inSection:1]];
  NSArray *collectionInserted = @[[NSIndexPath indexPathForItem:1 inSection:1]];
  NSArray *collectionUpdated = @[[NSIndexPath indexPathForItem:2 inSection:1]];
  NSArray *collectionMoves = @[PTUCreateChangesetMove(0, 1, 1), PTUCreateChangesetMove(1, 2, 1)];
  PTUDataModel *beforeData = @[subalbums, assets];
  PTUDataModel *afterData = @[subalbums, assets];
  PTUChangeset *PhotonsUIChangeset = [[PTUChangeset alloc] initWithBeforeDataModel:beforeData
      afterDataModel:afterData deleted:collectionRemoved inserted:collectionInserted
      updated:collectionUpdated moved:collectionMoves];

  expect([provider fetchChangeset]).to.sendValues(@[PhotonsUIChangeset]);
});

it(@"should forward errors", ^{
  NSError *signalError = [NSError lt_errorWithCode:1337];
  OCMStub([assetManager fetchAlbumWithURL:url])
      .andReturn([RACSignal error:signalError]);
  expect([provider fetchChangeset]).to.matchError(^BOOL(NSError *error) {
    return error == signalError;
  });
});

SpecEnd

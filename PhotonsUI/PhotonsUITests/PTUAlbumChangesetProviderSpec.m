// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUAlbumChangesetProvider.h"

#import <Photons/PTNAlbum.h>
#import <Photons/PTNAlbumChangeset.h>
#import <Photons/PTNAlbumChangesetMove.h>
#import <Photons/PTNAssetManager.h>
#import <Photons/PTNCollection.h>
#import <Photons/PTNIncrementalChanges.h>

#import "PTUChangeset.h"
#import "PTUChangesetMove.h"
#import "PhotonsUITestUtils.h"

SpecBegin(PTUAlbumDataSource)

__block id<PTNAssetManager> assetManager;
__block NSURL *url;
__block PTUAlbumChangesetProvider *provider;
__block id<PTNAlbum> album;

beforeEach(^{
  assetManager = OCMProtocolMock(@protocol(PTNAssetManager));
  url = [NSURL URLWithString:@"http://www.foo.com"];
  provider = [[PTUAlbumChangesetProvider alloc] initWithManager:assetManager albumURL:url];

  album = PTNCreateAlbum(nil, @[@"bar"], @[@"foo", @"bar"]);
});

it(@"should map changeset without incremental changes", ^{
  PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
  
  OCMStub([assetManager fetchAlbumWithURL:url]).andReturn([RACSignal return:changeset]);

  expect([provider fetchChangeset]).to.sendValues(@[
    [[PTUChangeset alloc] initWithAfterDataModel:@[album.subalbums, album.assets]]
  ]);
});

context(@"incremental changes", ^{
  __block id<PTNAlbum> beforeAlbum;
  __block id<PTNAlbum> afterAlbum;
  __block PTNIncrementalChanges *changes;

  beforeEach(^{
    afterAlbum = PTNCreateAlbum(nil, @[@"bar"], @[@"foo", @"bar"]);
    beforeAlbum = PTNCreateAlbum(nil, @[@"bar", @"baz"], @[@"foo"]);

    NSIndexSet *removed = [[NSIndexSet alloc] initWithIndex:0];
    NSIndexSet *inserted = [[NSIndexSet alloc] initWithIndex:1];
    NSIndexSet *updated = [[NSIndexSet alloc] initWithIndex:2];
    NSArray *moves = @[
      [PTNAlbumChangesetMove changesetMoveFrom:0 to:1],
      [PTNAlbumChangesetMove changesetMoveFrom:1 to:2]
    ];

    changes = [PTNIncrementalChanges changesWithRemovedIndexes:removed
                                               insertedIndexes:inserted
                                                updatedIndexes:updated
                                                         moves:moves];

  });

  it(@"should map changeset with incremental changes in assets", ^{
    PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithBeforeAlbum:beforeAlbum
                                                                    afterAlbum:afterAlbum
                                                               subalbumChanges:nil
                                                                  assetChanges:changes];

    OCMStub([assetManager fetchAlbumWithURL:url]).andReturn([RACSignal return:changeset]);

    NSArray *collectionRemoved = @[[NSIndexPath indexPathForItem:0 inSection:1]];
    NSArray *collectionInserted = @[[NSIndexPath indexPathForItem:1 inSection:1]];
    NSArray *collectionUpdated = @[[NSIndexPath indexPathForItem:2 inSection:1]];
    NSArray *collectionMoves = @[PTUCreateChangesetMove(0, 1, 1), PTUCreateChangesetMove(1, 2, 1)];
    PTUDataModel *beforeData = @[beforeAlbum.subalbums, beforeAlbum.assets];
    PTUDataModel *afterData = @[afterAlbum.subalbums, afterAlbum.assets];
    PTUChangeset *mappedChangeset = [[PTUChangeset alloc]
                                     initWithBeforeDataModel:beforeData
                                     afterDataModel:afterData
                                     deleted:collectionRemoved
                                     inserted:collectionInserted
                                     updated:collectionUpdated
                                     moved:collectionMoves];

    expect([provider fetchChangeset]).to.sendValues(@[mappedChangeset]);
  });

  it(@"should map changeset with incremental changes in subalbums", ^{
    id changeset = [PTNAlbumChangeset changesetWithBeforeAlbum:beforeAlbum afterAlbum:afterAlbum
                                               subalbumChanges:changes assetChanges:nil];

    OCMStub([assetManager fetchAlbumWithURL:url]).andReturn([RACSignal return:changeset]);

    NSArray *collectionRemoved = @[[NSIndexPath indexPathForItem:0 inSection:0]];
    NSArray *collectionInserted = @[[NSIndexPath indexPathForItem:1 inSection:0]];
    NSArray *collectionUpdated = @[[NSIndexPath indexPathForItem:2 inSection:0]];
    NSArray *collectionMoves = @[PTUCreateChangesetMove(0, 1, 0), PTUCreateChangesetMove(1, 2, 0)];
    PTUDataModel *beforeData = @[beforeAlbum.subalbums, beforeAlbum.assets];
    PTUDataModel *afterData = @[afterAlbum.subalbums, afterAlbum.assets];
    PTUChangeset *photonsUIChangeset = [[PTUChangeset alloc] initWithBeforeDataModel:beforeData
        afterDataModel:afterData deleted:collectionRemoved inserted:collectionInserted
        updated:collectionUpdated moved:collectionMoves];

    expect([provider fetchChangeset]).to.sendValues(@[photonsUIChangeset]);
  });

  it(@"should map changeset with incremental changes in both subalbums and assets", ^{
    id changeset = [PTNAlbumChangeset changesetWithBeforeAlbum:beforeAlbum afterAlbum:afterAlbum
                                               subalbumChanges:changes assetChanges:changes];

    OCMStub([assetManager fetchAlbumWithURL:url]).andReturn([RACSignal return:changeset]);

    NSArray *collectionRemoved = @[
      [NSIndexPath indexPathForItem:0 inSection:0],
      [NSIndexPath indexPathForItem:0 inSection:1]
    ];
    NSArray *collectionInserted = @[
      [NSIndexPath indexPathForItem:1 inSection:0],
      [NSIndexPath indexPathForItem:1 inSection:1]
    ];
    NSArray *collectionUpdated = @[
      [NSIndexPath indexPathForItem:2 inSection:0],
      [NSIndexPath indexPathForItem:2 inSection:1]
    ];
    NSArray *collectionMoves = @[
      PTUCreateChangesetMove(0, 1, 0),
      PTUCreateChangesetMove(1, 2, 0),
      PTUCreateChangesetMove(0, 1, 1),
      PTUCreateChangesetMove(1, 2, 1)
    ];
    PTUDataModel *beforeData = @[beforeAlbum.subalbums, beforeAlbum.assets];
    PTUDataModel *afterData = @[afterAlbum.subalbums, afterAlbum.assets];
    PTUChangeset *PhotonsUIChangeset = [[PTUChangeset alloc] initWithBeforeDataModel:beforeData
        afterDataModel:afterData deleted:collectionRemoved inserted:collectionInserted
        updated:collectionUpdated moved:collectionMoves];

    expect([provider fetchChangeset]).to.sendValues(@[PhotonsUIChangeset]);
  });
});

it(@"should forward asset manager errors", ^{
  NSError *signalError = [NSError lt_errorWithCode:1337];
  OCMStub([assetManager fetchAlbumWithURL:url]).andReturn([RACSignal error:signalError]);
  expect([provider fetchChangeset]).to.matchError(^BOOL(NSError *error) {
    return [error isEqual:signalError];
  });
});

SpecEnd

// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAlbumChangeset+PhotoKit.h"

#import <Photos/Photos.h>

#import "NSURL+PhotoKit.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangesetMove.h"
#import "PTNPhotoKitAlbumType.h"

SpecBegin(PTNAlbumChangeset_PhotoKit)

__block NSURL *url;

beforeEach(^{
  PTNPhotoKitAlbumType *albumType = [PTNPhotoKitAlbumType
                                     albumTypeWithType:PHAssetCollectionTypeSmartAlbum
                                     subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary];
  url = [NSURL ptn_photoKitAlbumsWithType:albumType];
});

it(@"should construct changeset with fetch result", ^{
  PHFetchResult *fetchResult = OCMClassMock([PHFetchResult class]);

  PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithURL:url
                                                 photoKitFetchResult:fetchResult];

  expect(changeset.afterAlbum.url).to.equal(url);
});

it(@"should construct changeset with url and details", ^{
  id before = OCMClassMock([PHFetchResult class]);
  id after = OCMClassMock([PHFetchResult class]);
  NSIndexSet *removedIndexes = [NSIndexSet indexSetWithIndex:0];
  NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndex:1];
  NSIndexSet *updatedIndexes = [NSIndexSet indexSetWithIndex:2];

  id details = OCMClassMock([PHFetchResultChangeDetails class]);

  OCMStub([details fetchResultBeforeChanges]).andReturn(before);
  OCMStub([details fetchResultAfterChanges]).andReturn(after);
  OCMStub([details removedIndexes]).andReturn(removedIndexes);
  OCMStub([details insertedIndexes]).andReturn(insertedIndexes);
  OCMStub([details changedIndexes]).andReturn(updatedIndexes);
  OCMStub([details enumerateMovesWithBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained void(^handler)(NSUInteger fromIndex, NSUInteger toIndex);
    [invocation getArgument:&handler atIndex:2];
    handler(5, 7);
    handler(7, 5);
  });

  PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithURL:url
                                               photoKitChangeDetails:details];

  expect(changeset.beforeAlbum.url).to.equal(url);
  expect(changeset.afterAlbum.url).to.equal(url);
  expect(changeset.removedIndexes).to.equal(removedIndexes);
  expect(changeset.insertedIndexes).to.equal(insertedIndexes);
  expect(changeset.updatedIndexes).to.equal(updatedIndexes);
  expect(changeset.moves).to.equal(@[
    [PTNAlbumChangesetMove changesetMoveFrom:5 to:7],
    [PTNAlbumChangesetMove changesetMoveFrom:7 to:5]
  ]);
});

SpecEnd

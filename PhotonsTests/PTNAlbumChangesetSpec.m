// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAlbumChangeset.h"

#import "PTNAlbumChangesetMove.h"

SpecBegin(PTNAlbumChangeset)

context(@"construction", ^{
  it(@"should construct changeset with after album", ^{
    id after = OCMProtocolMock(@protocol(PTNAlbum));
    PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithAfterAlbum:after];

    expect(changeset.afterAlbum).to.equal(after);

    expect(changeset.beforeAlbum).to.beNil();
    expect(changeset.removedIndexes).to.beNil();
    expect(changeset.insertedIndexes).to.beNil();
    expect(changeset.updatedIndexes).to.beNil();
    expect(changeset.moves).to.beNil();
  });

  it(@"should construct changeset with changes", ^{
    id before = OCMProtocolMock(@protocol(PTNAlbum));
    id after = OCMProtocolMock(@protocol(PTNAlbum));
    NSIndexSet *removedIndexes = [NSIndexSet indexSetWithIndex:0];
    NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndex:1];
    NSIndexSet *updatedIndexes = [NSIndexSet indexSetWithIndex:2];
    PTNAlbumChangesetMoves *moves = @[[PTNAlbumChangesetMove changesetMoveFrom:0 to:1]];

    PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithBeforeAlbum:before
                                                                    afterAlbum:after
                                                                removedIndexes:removedIndexes
                                                               insertedIndexes:insertedIndexes
                                                                updatedIndexes:updatedIndexes
                                                                         moves:moves];

    expect(changeset.beforeAlbum).to.equal(before);
    expect(changeset.afterAlbum).to.equal(after);
    expect(changeset.removedIndexes).to.equal(removedIndexes);
    expect(changeset.insertedIndexes).to.equal(insertedIndexes);
    expect(changeset.updatedIndexes).to.equal(updatedIndexes);
    expect(changeset.moves).to.equal(moves);
  });
});

context(@"equality", ^{
  __block PTNAlbumChangeset *firstChangeset;
  __block PTNAlbumChangeset *secondChangeset;
  __block PTNAlbumChangeset *otherChangeset;

  beforeEach(^{
    id before = OCMProtocolMock(@protocol(PTNAlbum));
    id after = OCMProtocolMock(@protocol(PTNAlbum));
    NSIndexSet *removedIndexes = [NSIndexSet indexSetWithIndex:0];
    NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndex:1];
    NSIndexSet *updatedIndexes = [NSIndexSet indexSetWithIndex:2];
    PTNAlbumChangesetMoves *moves = @[[PTNAlbumChangesetMove changesetMoveFrom:0 to:1]];

    firstChangeset = [PTNAlbumChangeset changesetWithBeforeAlbum:before
                                                      afterAlbum:after
                                                  removedIndexes:removedIndexes
                                                 insertedIndexes:insertedIndexes
                                                  updatedIndexes:updatedIndexes
                                                           moves:moves];

    secondChangeset = [PTNAlbumChangeset changesetWithBeforeAlbum:before
                                                       afterAlbum:after
                                                   removedIndexes:removedIndexes
                                                  insertedIndexes:insertedIndexes
                                                   updatedIndexes:updatedIndexes
                                                            moves:moves];

    otherChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:after];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstChangeset).to.equal(secondChangeset);
    expect(secondChangeset).to.equal(firstChangeset);

    expect(firstChangeset).notTo.equal(otherChangeset);
    expect(secondChangeset).notTo.equal(otherChangeset);
  });

  it(@"should create proper hash", ^{
    expect(firstChangeset.hash).to.equal(secondChangeset.hash);
  });
});

SpecEnd

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNIncrementalChanges.h"

#import "PTNAlbumChangesetMove.h"

SpecBegin(PTNIncrementalChanges)

context(@"construction", ^{
  it(@"should construct incremental changes", ^{
    NSIndexSet *removedIndexes = [NSIndexSet indexSetWithIndex:0];
    NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndex:1];
    NSIndexSet *updatedIndexes = [NSIndexSet indexSetWithIndex:2];
    PTNAlbumChangesetMoves *moves = @[[PTNAlbumChangesetMove changesetMoveFrom:0 to:1]];

    PTNIncrementalChanges *changes = [PTNIncrementalChanges changesWithRemovedIndexes:removedIndexes
        insertedIndexes:insertedIndexes updatedIndexes:updatedIndexes moves:moves];

    expect(changes.removedIndexes).to.equal(removedIndexes);
    expect(changes.insertedIndexes).to.equal(insertedIndexes);
    expect(changes.updatedIndexes).to.equal(updatedIndexes);
    expect(changes.moves).to.equal(moves);
  });
});

context(@"equality", ^{
  __block PTNIncrementalChanges *firstChanges;
  __block PTNIncrementalChanges *secondChanges;
  __block PTNIncrementalChanges *otherChanges;

  beforeEach(^{
    NSIndexSet *removedIndexes = [NSIndexSet indexSetWithIndex:0];
    NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndex:1];
    NSIndexSet *updatedIndexes = [NSIndexSet indexSetWithIndex:2];
    PTNAlbumChangesetMoves *moves = @[[PTNAlbumChangesetMove changesetMoveFrom:0 to:1]];

    firstChanges = [PTNIncrementalChanges changesWithRemovedIndexes:removedIndexes
                                                    insertedIndexes:insertedIndexes
                                                     updatedIndexes:updatedIndexes
                                                              moves:moves];

    secondChanges = [PTNIncrementalChanges changesWithRemovedIndexes:removedIndexes
                                                     insertedIndexes:insertedIndexes
                                                      updatedIndexes:updatedIndexes
                                                               moves:moves];

    otherChanges = [PTNIncrementalChanges changesWithRemovedIndexes:nil
                                                    insertedIndexes:nil
                                                     updatedIndexes:nil
                                                              moves:nil];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstChanges).to.equal(secondChanges);
    expect(secondChanges).to.equal(firstChanges);

    expect(firstChanges).notTo.equal(otherChanges);
    expect(secondChanges).notTo.equal(otherChanges);
  });

  it(@"should create proper hash", ^{
    expect(firstChanges.hash).to.equal(secondChanges.hash);
  });
});

SpecEnd

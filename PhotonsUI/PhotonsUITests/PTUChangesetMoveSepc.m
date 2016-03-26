// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUChangesetMove.h"

SpecBegin(PTUChangesetMove)

it(@"should construct changeset move", ^{
  NSIndexPath *from = [NSIndexPath indexPathForItem:7 inSection:1];
  NSIndexPath *to = [NSIndexPath indexPathForItem:5 inSection:1];
  PTUChangesetMove *move = [PTUChangesetMove changesetMoveFrom:from to:to];

  expect(move.fromIndex).to.equal(from);
  expect(move.toIndex).to.equal(to);
});

context(@"equality", ^{
  __block PTUChangesetMove *firstMove;
  __block PTUChangesetMove *secondMove;
  __block PTUChangesetMove *otherMove;

  beforeEach(^{
    NSIndexPath *from = [NSIndexPath indexPathForItem:7 inSection:1];
    NSIndexPath *to = [NSIndexPath indexPathForItem:5 inSection:1];

    firstMove = [PTUChangesetMove changesetMoveFrom:from to:to];
    secondMove = [PTUChangesetMove changesetMoveFrom:from to:to];
    otherMove = [PTUChangesetMove changesetMoveFrom:[NSIndexPath indexPathForItem:2 inSection:1]
                                                 to:[NSIndexPath indexPathForItem:4 inSection:1]];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstMove).to.equal(secondMove);
    expect(secondMove).to.equal(firstMove);

    expect(firstMove).notTo.equal(otherMove);
    expect(secondMove).notTo.equal(otherMove);
  });

  it(@"should create proper hash", ^{
    expect(firstMove.hash).to.equal(secondMove.hash);
  });
});

SpecEnd

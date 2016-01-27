// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAlbumChangesetMove.h"

SpecBegin(PTNAlbumChangesetMove)

it(@"should construct changeset move", ^{
  PTNAlbumChangesetMove *move = [PTNAlbumChangesetMove changesetMoveFrom:7 to:5];

  expect(move.fromIndex).to.equal(7);
  expect(move.toIndex).to.equal(5);
});

SpecEnd

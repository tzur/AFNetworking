// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUChangeset.h"

#import "PTUChangesetMove.h"
#import "PhotonsUITestUtils.h"

SpecBegin(PTUChangeset)

__block NSArray *beforeDataModel;
__block NSArray *afterDataModel;

beforeEach(^{
  NSArray *sectionA = @[@"foo", @"bar"];
  NSArray *sectionB = @[@"baz"];
  beforeDataModel = @[sectionA, sectionB];
  afterDataModel = @[sectionA, sectionA, sectionB];
});

it(@"should initialize without incremental changes", ^{
  PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:afterDataModel];
  expect(changeset.beforeDataModel).to.beNil();
  expect(changeset.afterDataModel).to.equal(afterDataModel);
  expect(changeset.deletedIndexes).to.beNil();
  expect(changeset.insertedIndexes).to.beNil();
  expect(changeset.updatedIndexes).to.beNil();
  expect(changeset.movedIndexes).to.beNil();
  expect(changeset.hasIncrementalChanges).to.beFalsy();
});

it(@"should initialize with incremental changes", ^{
  NSArray *deleted = @[[NSIndexPath indexPathForItem:0 inSection:0]];
  NSArray *inserted = @[[NSIndexPath indexPathForItem:1 inSection:1]];
  NSArray *updated = @[[NSIndexPath indexPathForItem:2 inSection:2]];
  NSArray *moved = @[PTUCreateChangesetMove(0, 1, 1), PTUCreateChangesetMove(1, 2, 1)];

  PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:beforeDataModel
      afterDataModel:afterDataModel deleted:deleted inserted:inserted updated:updated moved:moved];
  expect(changeset.beforeDataModel).to.equal(beforeDataModel);
  expect(changeset.afterDataModel).to.equal(afterDataModel);
  expect(changeset.deletedIndexes).to.equal(deleted);
  expect(changeset.insertedIndexes).to.equal(inserted);
  expect(changeset.updatedIndexes).to.equal(updated);
  expect(changeset.movedIndexes).to.equal(moved);;
  expect(changeset.hasIncrementalChanges).to.beTruthy();
});

context(@"equality", ^{
  __block PTUChangeset *firstChangeset;
  __block PTUChangeset *secondChangeset;
  __block PTUChangeset *otherChangeset;

  beforeEach(^{
    NSArray *deleted = @[[NSIndexPath indexPathForItem:0 inSection:0]];
    NSArray *inserted = @[[NSIndexPath indexPathForItem:1 inSection:1]];
    NSArray *updated = @[[NSIndexPath indexPathForItem:2 inSection:2]];
    NSArray *moved = @[PTUCreateChangesetMove(0, 1, 1), PTUCreateChangesetMove(1, 2, 1)];

    firstChangeset = [[PTUChangeset alloc] initWithBeforeDataModel:beforeDataModel
        afterDataModel:afterDataModel deleted:deleted inserted:inserted updated:updated
        moved:moved];
    secondChangeset = [[PTUChangeset alloc] initWithBeforeDataModel:beforeDataModel
        afterDataModel:afterDataModel deleted:deleted inserted:inserted updated:updated
        moved:moved];
    otherChangeset = [[PTUChangeset alloc] initWithAfterDataModel:afterDataModel];
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

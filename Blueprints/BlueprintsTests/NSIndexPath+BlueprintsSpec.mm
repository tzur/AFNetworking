// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSIndexPath+Blueprints.h"

SpecBegin(NSIndexPath_Blueprints)

context(@"initialization with vector", ^{
  it(@"should initialize with vector", ^{
    NSIndexPath *indexPath = [NSIndexPath blu_indexPathWithIndexes:{1, 2, 3, 4}];

    expect(indexPath.length).to.equal(4);
    expect([indexPath indexAtPosition:0]).to.equal(1);
    expect([indexPath indexAtPosition:1]).to.equal(2);
    expect([indexPath indexAtPosition:2]).to.equal(3);
    expect([indexPath indexAtPosition:3]).to.equal(4);
  });

  it(@"should return an empty index path when passing an empty vector", ^{
    NSIndexPath *indexPath = [NSIndexPath blu_indexPathWithIndexes:{}];
    expect(indexPath).to.equal([NSIndexPath blu_empty]);
  });
});

it(@"should return valid empty index path", ^{
  NSIndexPath *indexPath = [NSIndexPath blu_empty];

  expect(indexPath.length).to.equal(0);
  expect([indexPath indexAtPosition:0]).to.equal(NSNotFound);
});

context(@"indexes vector", ^{
  it(@"should return empty vector for empty index path", ^{
    NSIndexPath *indexPath = [NSIndexPath blu_empty];
    const std::vector<NSUInteger> indexes = [indexPath blu_indexes];
    expect(indexes.size()).to.equal(0);
  });

  it(@"should return correct vector for index path", ^{
    const std::vector<NSUInteger> expectedIndexes = {1, 2, 3, 4};
    NSIndexPath *indexPath = [NSIndexPath blu_indexPathWithIndexes:expectedIndexes];
    const std::vector<NSUInteger> actualIndexes = [indexPath blu_indexes];
    expect(actualIndexes == expectedIndexes).to.beTruthy();
  });
});

context(@"adding index path", ^{
  it(@"should return empty index path when adding empty index path to empty index path", ^{
    NSIndexPath *original = [NSIndexPath blu_empty];
    NSIndexPath *addition = [NSIndexPath blu_empty];
    NSIndexPath *result = [original blu_indexPathByAddingIndexPath:addition];
    expect(result).to.equal([NSIndexPath blu_empty]);
  });

  it(@"should return correct index path when adding non empty index path to empty index path", ^{
    NSIndexPath *original = [NSIndexPath blu_empty];
    NSIndexPath *addition = [NSIndexPath blu_indexPathWithIndexes:{1, 2, 3}];
    NSIndexPath *result = [original blu_indexPathByAddingIndexPath:addition];
    expect(result).to.equal([NSIndexPath blu_indexPathWithIndexes:{1, 2, 3}]);
  });

  it(@"should return correct index path when adding empty index path to non empty index path", ^{
    NSIndexPath *original = [NSIndexPath blu_indexPathWithIndexes:{1, 2, 3}];
    NSIndexPath *addition = [NSIndexPath blu_empty];
    NSIndexPath *result = [original blu_indexPathByAddingIndexPath:addition];
    expect(result).to.equal([NSIndexPath blu_indexPathWithIndexes:{1, 2, 3}]);
  });

  it(@"should return correct index path when adding non empty index paths", ^{
    NSIndexPath *original = [NSIndexPath blu_indexPathWithIndexes:{1, 2, 3}];
    NSIndexPath *addition = [NSIndexPath blu_indexPathWithIndexes:{7, 8}];
    NSIndexPath *result = [original blu_indexPathByAddingIndexPath:addition];
    expect(result).to.equal([NSIndexPath blu_indexPathWithIndexes:{1, 2, 3, 7, 8}]);
  });
});

SpecEnd

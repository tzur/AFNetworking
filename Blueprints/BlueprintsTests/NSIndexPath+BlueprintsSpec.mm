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

SpecEnd

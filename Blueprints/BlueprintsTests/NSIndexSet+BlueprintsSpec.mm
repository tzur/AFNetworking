// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSIndexSet+Blueprints.h"

SpecBegin(NSIndexSet_Blueprints)

it(@"should create index set with given indexes", ^{
  std::set<NSUInteger> indexes = {2, 5, 6};
  NSIndexSet *indexSet = [NSIndexSet blu_indexSetWithIndexes:indexes];

  expect(indexSet.count).to.equal(indexes.size());

  for (NSUInteger index : indexes) {
    expect([indexSet containsIndex:index]).to.beTruthy();
  }
});

SpecEnd

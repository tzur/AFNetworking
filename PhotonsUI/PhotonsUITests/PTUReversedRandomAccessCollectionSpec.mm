// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUReversedRandomAccessCollection.h"

SpecBegin(PTUReversedRandomAccessCollection)

__block id<LTRandomAccessCollection> collection;
__block PTUReversedRandomAccessCollection *reversedCollection;

beforeEach(^{
  collection = @[@1, @2, @3, @4];
  reversedCollection = [[PTUReversedRandomAccessCollection alloc] initWithCollection:collection];
});

it(@"should correctly contain objects", ^{
  expect([reversedCollection containsObject:@1]).to.beTruthy();
  expect([reversedCollection containsObject:@5]).to.beFalsy();
});

it(@"should correctly reverse index of obejcts", ^{
  expect([reversedCollection indexOfObject:@1]).to.equal(3);
  expect([reversedCollection indexOfObject:@2]).to.equal(2);
  expect([reversedCollection indexOfObject:@3]).to.equal(1);
  expect([reversedCollection indexOfObject:@4]).to.equal(0);
});

it(@"should correctly reverse objects for index", ^{
  expect([reversedCollection objectAtIndex:0]).to.equal(@4);
  expect([reversedCollection objectAtIndex:1]).to.equal(@3);
  expect([reversedCollection objectAtIndex:2]).to.equal(@2);
  expect([reversedCollection objectAtIndex:3]).to.equal(@1);
});

it(@"should correctly reverse objects for index subscript", ^{
  expect(reversedCollection[0]).to.equal(@4);
  expect(reversedCollection[1]).to.equal(@3);
  expect(reversedCollection[2]).to.equal(@2);
  expect(reversedCollection[3]).to.equal(@1);
});

it(@"should correcly reverse first object", ^{
  expect(reversedCollection.firstObject).to.equal(@4);
});

it(@"should correcly reverse last object", ^{
  expect(reversedCollection.lastObject).to.equal(@1);
});

it(@"should correctly maintain count", ^{
  expect(reversedCollection.count).to.equal(4);
});

it(@"should continue to reverse changes in underlying collection", ^{
  NSMutableArray *mutableCollection = [@[@1, @2] mutableCopy];
  reversedCollection =
      [[PTUReversedRandomAccessCollection alloc] initWithCollection:mutableCollection];

  [mutableCollection addObject:@3];

  expect(reversedCollection.count).to.equal(3);
  expect(reversedCollection.firstObject).to.equal(@3);
  expect(reversedCollection.lastObject).to.equal(@1);
});

it(@"should correctly handle copying", ^{
  NSMutableArray *mutableCollection = [@[@1, @2] mutableCopy];
  id<LTRandomAccessCollection> copiedReversedCollection =
      [[[PTUReversedRandomAccessCollection alloc] initWithCollection:mutableCollection] copy];
  
  [mutableCollection addObject:@3];

  expect(copiedReversedCollection.count).to.equal(2);
  expect(copiedReversedCollection.firstObject).to.equal(@2);
  expect(copiedReversedCollection.lastObject).to.equal(@1);
});

SpecEnd

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLULazyNodeCollection.h"

#import "BLUNode.h"
#import "NSArray+BLUNodeCollection.h"

SpecBegin(BLULazyNodeCollection)

__block NSArray *baseCollection;

__block BLUNode *firstNode;
__block BLUNode *middleNode;
__block BLUNode *lastNode;

__block BLULazyNodeCollection *collection;

beforeEach(^{
  baseCollection = @[@1, @2, @3];
  collection = [[BLULazyNodeCollection alloc] initWithCollection:baseCollection
                                                     namingBlock:^(NSNumber *value) {
    return [@(value.unsignedIntegerValue * 2) description];
  }];

  firstNode = [BLUNode nodeWithName:@"2" childNodes:@[] value:@1];
  middleNode = [BLUNode nodeWithName:@"4" childNodes:@[] value:@2];
  lastNode = [BLUNode nodeWithName:@"6" childNodes:@[] value:@3];
});

context(@"LTRandomAccessCollection", ^{
  it(@"should answer if object is in the collection", ^{
    BLUNode *firstNonExistingObject = [BLUNode nodeWithName:@"2" childNodes:@[] value:@2];
    BLUNode *secondNonExistingObject = [BLUNode nodeWithName:@"2" childNodes:@[@1] value:@1];

    expect([collection containsObject:firstNode]).to.beTruthy();
    expect([collection containsObject:firstNonExistingObject]).to.beFalsy();
    expect([collection containsObject:secondNonExistingObject]).to.beFalsy();
  });

  it(@"should return object at index", ^{
    expect([collection objectAtIndex:1]).to.equal(middleNode);
    expect(collection[1]).to.equal(middleNode);
  });

  it(@"should return index of object", ^{
    expect([collection indexOfObject:collection.firstObject]).to.equal(0);
    expect([collection indexOfObject:collection.lastObject]).to.equal(2);

    BLUNode *nonExistingObject = [BLUNode nodeWithName:@"2" childNodes:@[] value:@2];
    expect([collection indexOfObject:nonExistingObject]).to.equal(NSNotFound);
  });

  it(@"should return first object", ^{
    expect(collection.firstObject).to.equal(firstNode);
  });

  it(@"should return last object", ^{
    expect(collection.lastObject).to.equal(lastNode);
  });

  it(@"should return count", ^{
    expect(collection.count).to.equal(3);
  });
});

context(@"NSFastEnumeration", ^{
  it(@"should fast enumerate correctly", ^{
    NSMutableArray *values = [NSMutableArray array];
    for (id value in collection) {
      [values addObject:value];
    }

    expect(values).to.equal(@[firstNode, middleNode, lastNode]);
  });
});

context(@"BLUNodeCollection", ^{
  it(@"should return node for a given name", ^{
    expect([collection blu_nodeForName:middleNode.name]).to.equal(middleNode);
  });

  it(@"should return nil for a non-existing name", ^{
    expect([collection blu_nodeForName:@"5"]).to.beNil();
  });
});

SpecEnd

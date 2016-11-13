// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "LTCompoundRandomAccessCollection.h"

SpecBegin(LTCompoundRandomAccessCollection)

__block NSMutableArray *firstCollection;
__block NSMutableArray *secondCollection;
__block NSMutableArray<NSMutableArray *> *collections;

__block LTCompoundRandomAccessCollection *collection;

beforeEach(^{
  firstCollection = [@[@1, @2, @3] mutableCopy];
  secondCollection = [@[@4, @5, @6] mutableCopy];
  collections = [@[firstCollection, secondCollection] mutableCopy];
  collection = [[LTCompoundRandomAccessCollection alloc] initWithCollections:collections];
});

context(@"LTRandomAccessCollection", ^{
  it(@"should correctly determine whether an object is in the collection", ^{
    expect([collection containsObject:@1]).to.beTruthy();
    expect([collection containsObject:@5]).to.beTruthy();
    expect([collection containsObject:@7]).to.beFalsy();
  });

  it(@"should return object at index", ^{
    expect([collection objectAtIndex:1]).to.equal(@2);
    expect([collection objectAtIndex:5]).to.equal(@6);
    expect(collection[0]).to.equal(@1);
    expect(collection[4]).to.equal(@5);
  });

  it(@"should raise for indexes out of bounds", ^{
    expect(^{
      id __unused value = [collection objectAtIndex:6];
    }).to.raise(NSRangeException);

    expect(^{
      id __unused value = collection[6];
    }).to.raise(NSRangeException);
  });

  it(@"should return index of object", ^{
    expect([collection indexOfObject:@1]).to.equal(0);
    expect([collection indexOfObject:@6]).to.equal(5);

    expect([collection indexOfObject:@7]).to.equal(NSNotFound);
  });

  it(@"should return first object", ^{
    expect(collection.firstObject).to.equal(@1);
  });

  it(@"should return first object regardless of first underlying collection", ^{
    LTCompoundRandomAccessCollection *emptyLast = [[LTCompoundRandomAccessCollection alloc]
                                                   initWithCollections:@[@[], @[], @[@1]]];
    expect(emptyLast.firstObject).to.equal(@1);
  });

  it(@"should return last object", ^{
    expect(collection.lastObject).to.equal(@6);
  });

  it(@"should return last object regardless of last underlying collection", ^{
    LTCompoundRandomAccessCollection *emptyLast = [[LTCompoundRandomAccessCollection alloc]
                                                   initWithCollections:@[@[@1], @[], @[]]];
    expect(emptyLast.lastObject).to.equal(@1);
  });

  it(@"should return count", ^{
    expect(collection.count).to.equal(6);
  });

  it(@"should change when the underlying collection changes", ^{
    [firstCollection addObject:@7];

    expect(collection.count).to.equal(7);
    expect(collection[3]).to.equal(@7);
    expect(collection[4]).to.equal(4);
  });

  it(@"should change when the underlying collections changes", ^{
    [collections addObject:[@[@7, @8] mutableCopy]];

    expect(collection.count).to.equal(8);
    expect(collection[3]).to.equal(@4);
    expect(collection[7]).to.equal(@8);
  });

  it(@"should not change when the underlying collection changes when copied", ^{
    LTCompoundRandomAccessCollection *copiedCollection = [collection copy];

    [firstCollection addObject:@4];

    expect(copiedCollection.count).to.equal(6);
    expect(copiedCollection[3]).to.equal(@4);
    expect(copiedCollection[4]).to.equal(@5);
  });

  it(@"should not change when the underlying collections changes when copied", ^{
    LTCompoundRandomAccessCollection *copiedCollection = [collection copy];

    [collections addObject:[@[@7, @8] mutableCopy]];

    expect(copiedCollection.count).to.equal(6);
    expect(copiedCollection[3]).to.equal(@4);
    expect(copiedCollection[4]).to.equal(@5);
  });
});

context(@"NSFastEnumeration", ^{
  it(@"should fast enumerate correctly", ^{
    NSMutableArray *values = [NSMutableArray array];
    for (id value in collection) {
      [values addObject:value];
    }
    
    expect(values).to.equal(@[@1, @2, @3, @4, @5, @6]);
  });
});

SpecEnd

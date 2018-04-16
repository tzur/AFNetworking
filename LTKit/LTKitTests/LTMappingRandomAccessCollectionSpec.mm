// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "LTMappingRandomAccessCollection.h"

SpecBegin(LTMappingRandomAccessCollection)

__block NSMutableArray *baseCollection;

__block LTMappingRandomAccessCollection *collection;

beforeEach(^{
  baseCollection = [@[@1, @2, @3] mutableCopy];
  collection = [[LTMappingRandomAccessCollection alloc] initWithCollection:baseCollection
      forwardMapBlock:^NSNumber *(NSNumber *value) {
        return @(value.unsignedIntegerValue * 10);
      }
      reverseMapBlock:^NSNumber * _Nullable (NSNumber *value) {
        if (value.unsignedIntegerValue == 1337) {
          return nil;
        }
        return @(value.unsignedIntegerValue / 10.0);
      }];
});

context(@"LTRandomAccessCollection", ^{
  it(@"should answer if object is in the collection", ^{
    expect([collection containsObject:@10]).to.beTruthy();
    expect([collection containsObject:@15]).to.beFalsy();
    expect([collection containsObject:@1]).to.beFalsy();
  });

  it(@"should return object at index", ^{
    expect([collection objectAtIndex:1]).to.equal(@20);
    expect(collection[1]).to.equal(@20);
  });

  it(@"should return index of object", ^{
    expect([collection indexOfObject:nn(collection.firstObject)]).to.equal(0);
    expect([collection indexOfObject:nn(collection.lastObject)]).to.equal(2);

    expect([collection indexOfObject:@15]).to.equal(NSNotFound);
  });

  it(@"should not find items that have no mapping", ^{
    expect([collection indexOfObject:@1337]).to.equal(NSNotFound);
  });

  it(@"should return first object", ^{
    expect(collection.firstObject).to.equal(@10);
  });

  it(@"should return last object", ^{
    expect(collection.lastObject).to.equal(@30);
  });

  it(@"should return count", ^{
    expect(collection.count).to.equal(3);
  });

  it(@"should change when the underlying collection changes", ^{
    [baseCollection addObject:@4];

    expect(collection.count).to.equal(4);
    expect(collection.firstObject).to.equal(@10);
    expect(collection.lastObject).to.equal(@40);
  });

  it(@"should not change when the underlying collection changes when copied", ^{
    LTMappingRandomAccessCollection *copiedCollection = [collection copy];

    [baseCollection addObject:@4];

    expect(copiedCollection.count).to.equal(3);
    expect(copiedCollection.firstObject).to.equal(@10);
    expect(copiedCollection.lastObject).to.equal(@30);
  });
});

context(@"NSFastEnumeration", ^{
  it(@"should fast enumerate correctly", ^{
    NSMutableArray *values = [NSMutableArray array];
    for (id value in collection) {
      [values addObject:value];
    }

    expect(values).to.equal(@[@10, @20, @30]);
  });
});

SpecEnd

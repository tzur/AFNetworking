// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUFastEnumerator.h"

static NSArray *BLUArrayWithFastEnumeration(id<NSFastEnumeration> enumeration) {
  NSMutableArray *array = [NSMutableArray array];
  for (id value in enumeration) {
    [array addObject:value];
  }
  return [array copy];
}

SpecBegin(BLUFastEnumerator)

context(@"enumerator of items", ^{
  __block NSArray *source;
  __block BLUFastEnumerator *enumerator;

  beforeEach(^{
    source = @[@1, @2, @3];
    enumerator = [[BLUFastEnumerator alloc] initWithSource:source];
  });

  it(@"should enumerate source", ^{
    NSArray *values = BLUArrayWithFastEnumeration(enumerator);
    expect(values).to.equal(source);
  });

  it(@"should enumerate large source", ^{
    NSMutableArray *source = [NSMutableArray array];
    for (NSUInteger i = 0; i < 10000; ++i) {
      [source addObject:@(i)];
    }
    BLUFastEnumerator *enumerator = [[BLUFastEnumerator alloc] initWithSource:source];

    NSArray *values = BLUArrayWithFastEnumeration(enumerator);
    expect(values).to.equal(source);
  });

  it(@"should partially enumerate source", ^{
    NSUInteger index = 0;
    for (id __unused value in enumerator) {
      ++index;
      if (index == 2) {
        break;
      }
    }

    NSArray *values = BLUArrayWithFastEnumeration(enumerator);
    expect(values).to.equal(source);
  });

  it(@"should partially enumerate on source after executing an operation", ^{
    BLUFastEnumerator *mappedEnumerator = [enumerator map:^NSNumber *(NSNumber *value) {
      return @(value.unsignedIntegerValue * 2);
    }];

    NSUInteger index = 0;
    for (id __unused value in mappedEnumerator) {
      ++index;
      if (index == 2) {
        break;
      }
    }

    NSArray *values = BLUArrayWithFastEnumeration(mappedEnumerator);
    expect(values).to.equal(@[@2, @4, @6]);
  });

  it(@"should map source", ^{
    BLUFastEnumerator *mappedEnumerator = [enumerator map:^NSNumber *(NSNumber *value) {
      return @(value.unsignedIntegerValue * 2);
    }];

    NSArray *values = BLUArrayWithFastEnumeration(mappedEnumerator);
    expect(values).to.equal(@[@2, @4, @6]);
  });

  it(@"should flatMap source", ^{
    BLUFastEnumerator *flatMappedEnumerator = [enumerator flatMap:^(NSNumber *value) {
      return @[value, @(value.unsignedIntegerValue * 2)];
    }];

    NSArray *values = BLUArrayWithFastEnumeration(flatMappedEnumerator);
    expect(values).to.equal(@[@1, @2, @2, @4, @3, @6]);
  });

  it(@"should concat two operators", ^{
    BLUFastEnumerator *flatMappedEnumerator = [[enumerator map:^(NSNumber *value) {
          return @[value, @(value.unsignedIntegerValue * 2)];
        }] flatten];

    NSArray *values = BLUArrayWithFastEnumeration(flatMappedEnumerator);
    expect(values).to.equal(@[@1, @2, @2, @4, @3, @6]);
  });

  it(@"should concat three operators", ^{
    BLUFastEnumerator *mappedEnumerator = [[[enumerator
        map:^(NSNumber *value) {
          return @[value, @(value.unsignedIntegerValue * 2)];
        }]
        map:^(NSArray *value) {
          return @[@([value.lastObject unsignedIntegerValue] * 2)];
        }]
        flatten];

    NSArray *values = BLUArrayWithFastEnumeration(mappedEnumerator);
    expect(values).to.equal(@[@4, @8, @12]);
  });

  it(@"should detect mutation while iterating source", ^{
    NSMutableArray *source = [@[@1, @2, @3] mutableCopy];
    BLUFastEnumerator *enumerator = [[BLUFastEnumerator alloc] initWithSource:source];

    expect(^{
      for (NSNumber *value in enumerator) {
        [source addObject:value];
      }
    }).to.raiseAny();
  });
});

context(@"enumerator of enumerators", ^{
  __block NSArray *source;
  __block BLUFastEnumerator *enumerator;

  beforeEach(^{
    source = @[@[@1, @3], @[@2, @4]];
    enumerator = [[BLUFastEnumerator alloc] initWithSource:source];
  });

  it(@"should flatten source", ^{
    BLUFastEnumerator *flattenedEnumerator = [enumerator flatten];

    NSArray *values = BLUArrayWithFastEnumeration(flattenedEnumerator);
    expect(values).to.equal(@[@1, @3, @2, @4]);
  });
});

context(@"quick enumerator creation", ^{
  it(@"should create enumerator from NSArray", ^{
    NSArray *source = @[@1, @2, @3];

    BLUFastEnumerator *enumerator = source.blu_enumerator;
    NSArray *values = BLUArrayWithFastEnumeration(enumerator);

    expect(values).to.equal(@[@1, @2, @3]);
  });

  it(@"should create enumerator from NSOrderedSet", ^{
    NSOrderedSet *source = [NSOrderedSet orderedSetWithArray:@[@1, @2, @3]];

    BLUFastEnumerator *enumerator = source.blu_enumerator;
    NSArray *values = BLUArrayWithFastEnumeration(enumerator);

    expect(values).to.equal(@[@1, @2, @3]);
  });
});

SpecEnd

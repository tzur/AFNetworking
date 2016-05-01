// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFastEnumerator.h"

static NSArray *LTArrayWithFastEnumeration(id<NSFastEnumeration> enumeration) {
  NSMutableArray *array = [NSMutableArray array];
  for (id value in enumeration) {
    [array addObject:value];
  }
  return [array copy];
}

SpecBegin(LTFastEnumerator)

context(@"enumerator of items", ^{
  __block NSArray *source;
  __block LTFastEnumerator *enumerator;

  beforeEach(^{
    source = @[@1, @2, @3];
    enumerator = [[LTFastEnumerator alloc] initWithSource:source];
  });

  it(@"should enumerate source", ^{
    NSArray *values = LTArrayWithFastEnumeration(enumerator);
    expect(values).to.equal(source);
  });

  it(@"should enumerate large source", ^{
    NSMutableArray *source = [NSMutableArray array];
    for (NSUInteger i = 0; i < 10000; ++i) {
      [source addObject:@(i)];
    }
    LTFastEnumerator *enumerator = [[LTFastEnumerator alloc] initWithSource:source];

    NSArray *values = LTArrayWithFastEnumeration(enumerator);
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

    NSArray *values = LTArrayWithFastEnumeration(enumerator);
    expect(values).to.equal(source);
  });

  it(@"should partially enumerate on source after executing an operation", ^{
    LTFastEnumerator *mappedEnumerator = [enumerator map:^NSNumber *(NSNumber *value) {
      return @(value.unsignedIntegerValue * 2);
    }];

    NSUInteger index = 0;
    for (id __unused value in mappedEnumerator) {
      ++index;
      if (index == 2) {
        break;
      }
    }

    NSArray *values = LTArrayWithFastEnumeration(mappedEnumerator);
    expect(values).to.equal(@[@2, @4, @6]);
  });

  it(@"should map source", ^{
    LTFastEnumerator *mappedEnumerator = [enumerator map:^NSNumber *(NSNumber *value) {
      return @(value.unsignedIntegerValue * 2);
    }];

    NSArray *values = LTArrayWithFastEnumeration(mappedEnumerator);
    expect(values).to.equal(@[@2, @4, @6]);
  });

  it(@"should map mutalbe source over", ^{
    enumerator = [[LTFastEnumerator alloc] initWithSource:[source mutableCopy]];
    LTFastEnumerator *mappedEnumerator = [enumerator map:^NSNumber *(NSNumber *value) {
      return @(value.unsignedIntegerValue * 2);
    }];

    NSArray *values = LTArrayWithFastEnumeration(mappedEnumerator);
    expect(values).to.equal(@[@2, @4, @6]);
  });

  it(@"should flatMap source", ^{
    LTFastEnumerator *flatMappedEnumerator = [enumerator flatMap:^(NSNumber *value) {
      return @[value, @(value.unsignedIntegerValue * 2)];
    }];

    NSArray *values = LTArrayWithFastEnumeration(flatMappedEnumerator);
    expect(values).to.equal(@[@1, @2, @2, @4, @3, @6]);
  });

  it(@"should flatMap mutalbe source", ^{
    enumerator = [[LTFastEnumerator alloc] initWithSource:[source mutableCopy]];
    LTFastEnumerator *flatMappedEnumerator = [enumerator flatMap:^(NSNumber *value) {
      return @[value, @(value.unsignedIntegerValue * 2)];
    }];

    NSArray *values = LTArrayWithFastEnumeration(flatMappedEnumerator);
    expect(values).to.equal(@[@1, @2, @2, @4, @3, @6]);
  });

  it(@"should concat two operators", ^{
    LTFastEnumerator *flatMappedEnumerator = [[enumerator map:^(NSNumber *value) {
          return @[value, @(value.unsignedIntegerValue * 2)];
        }] flatten];

    NSArray *values = LTArrayWithFastEnumeration(flatMappedEnumerator);
    expect(values).to.equal(@[@1, @2, @2, @4, @3, @6]);
  });

  it(@"should concat three operators", ^{
    LTFastEnumerator *mappedEnumerator = [[[enumerator
        map:^(NSNumber *value) {
          return @[value, @(value.unsignedIntegerValue * 2)];
        }]
        map:^(NSArray *value) {
          return @[@([value.lastObject unsignedIntegerValue] * 2)];
        }]
        flatten];

    NSArray *values = LTArrayWithFastEnumeration(mappedEnumerator);
    expect(values).to.equal(@[@4, @8, @12]);
  });

  it(@"should detect mutation while iterating source", ^{
    NSMutableArray *source = [@[@1, @2, @3] mutableCopy];
    LTFastEnumerator *enumerator = [[LTFastEnumerator alloc] initWithSource:source];

    expect(^{
      for (NSNumber *value in enumerator) {
        [source addObject:value];
      }
    }).to.raiseAny();
  });
});

context(@"enumerator of enumerators", ^{
  __block NSArray *source;
  __block LTFastEnumerator *enumerator;

  beforeEach(^{
    source = @[@[@1, @3], @[@2, @4]];
    enumerator = [[LTFastEnumerator alloc] initWithSource:source];
  });

  it(@"should flatten source", ^{
    LTFastEnumerator *flattenedEnumerator = [enumerator flatten];

    NSArray *values = LTArrayWithFastEnumeration(flattenedEnumerator);
    expect(values).to.equal(@[@1, @3, @2, @4]);
  });

  it(@"should flatten mutable source", ^{
    NSMutableArray *mutableSource = [@[@[@1, @3], [@[@2, @4] mutableCopy]] mutableCopy];
    enumerator = [[LTFastEnumerator alloc] initWithSource:mutableSource];
    LTFastEnumerator *flattenedEnumerator = [enumerator flatten];

    NSArray *values = LTArrayWithFastEnumeration(flattenedEnumerator);
    expect(values).to.equal(@[@1, @3, @2, @4]);
  });
});

context(@"quick enumerator creation", ^{
  it(@"should create enumerator from NSArray", ^{
    NSArray *source = @[@1, @2, @3];

    LTFastEnumerator *enumerator = source.lt_enumerator;
    NSArray *values = LTArrayWithFastEnumeration(enumerator);

    expect(values).to.equal(@[@1, @2, @3]);
  });

  it(@"should create enumerator from NSOrderedSet", ^{
    NSOrderedSet *source = [NSOrderedSet orderedSetWithArray:@[@1, @2, @3]];

    LTFastEnumerator *enumerator = source.lt_enumerator;
    NSArray *values = LTArrayWithFastEnumeration(enumerator);

    expect(values).to.equal(@[@1, @2, @3]);
  });
});

SpecEnd

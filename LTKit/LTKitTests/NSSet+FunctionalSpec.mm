// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSSet+Functional.h"

#import "NSArray+NSSet.h"

static NSSet<NSNumber *> * const kSourceSet = [@[@1, @2, @5, @6] lt_set];

SpecBegin(NSSet_Functional)

context(@"map", ^{
  it(@"should map the set using the provided block", ^{
    auto mapped = [kSourceSet lt_map:^(NSNumber *object) {
      return @(object.integerValue * object.integerValue);
    }];
    expect(mapped).to.equal([@[@1, @4, @25, @36] lt_set]);
  });
});

context(@"filter", ^{
  it(@"should return all and only those items that the filter block has returned YES for", ^{
    auto filteredSet = [kSourceSet lt_filter:^BOOL(NSNumber *object) {
      return object.integerValue % 2;
    }];

    expect(filteredSet).to.equal([@[@1, @5] lt_set]);
  });

  it(@"should return empty set if block returns NO for all items", ^{
    auto filteredSet = [kSourceSet lt_filter:^BOOL(NSNumber *) {
      return NO;
    }];

    expect(filteredSet).to.equal([@[] lt_set]);
  });
});

SpecEnd

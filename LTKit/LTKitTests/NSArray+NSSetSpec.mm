// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "NSArray+NSSet.h"

SpecBegin(NSArray_NSSet)

it(@"should transform an empty array to an empty set", ^{
  expect([@[] lt_set]).to.equal([NSSet set]);
});

it(@"should transform an array with no repetitions to a set correctly", ^{
  expect([@[@1, @2, @3] lt_set]).to.equal([NSSet setWithArray:@[@1, @2, @3]]);
});

it(@"should transform an array with repetitions to a set correctly", ^{
  expect([@[@1, @2, @3, @3] lt_set]).to.equal([NSSet setWithArray:@[@1, @2, @3]]);
});

SpecEnd

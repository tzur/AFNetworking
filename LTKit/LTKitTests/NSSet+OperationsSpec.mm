// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSSet+Operations.h"

#import "NSArray+NSSet.h"

static NSSet<NSNumber *> * const kFirstSet = [@[@1, @2, @3, @4] lt_set];
static NSSet<NSNumber *> * const kSecondSet = [@[@3, @4, @5, @6] lt_set];

SpecBegin(NSSet_Operations)

it(@"should create a union set of two sets", ^{
  auto unionSet = [kFirstSet lt_union:kSecondSet];
  expect(unionSet).to.equal([@[@1, @2, @3, @4, @5, @6] lt_set]);
});

it(@"should create a minus set of two sets", ^{
  auto minusSet = [kFirstSet lt_minus:kSecondSet];
  expect(minusSet).to.equal([@[@1, @2] lt_set]);
});

it(@"should create an intersection set of two sets", ^{
  auto intersectionSet = [kFirstSet lt_intersect:kSecondSet];
  expect(intersectionSet).to.equal([@[@3, @4] lt_set]);
});

SpecEnd

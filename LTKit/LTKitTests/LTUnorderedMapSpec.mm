// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTUnorderedMap.h"

SpecBegin(LTUnorderedMap)

__block lt::unordered_map<NSString *, CGPoint> map;

beforeEach(^{
  map[@"foo"] = CGPointMake(5, 7);
  map[@"bar"] = CGPointMake(2, 4);
});

it(@"should insert and fetch values from map", ^{
  expect(map[@"foo"]).to.equal(CGPointMake(5, 7));
  expect(map[@"bar"]).to.equal(CGPointMake(2, 4));
});

it(@"should insert and fetch value with different key instance", ^{
  NSString *key = [[@"foo" mutableCopy] copy];

  expect(@"foo").notTo.beIdenticalTo(key);
  expect(map[key]).to.equal(CGPointMake(5, 7));
});

SpecEnd

// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSDictionary+Operations.h"

SpecBegin(NSDictionary_Merging)

__block NSDictionary<NSNumber *, NSString *> *sourceDictionary;

beforeEach(^{
  sourceDictionary = @{
    @4: @"foo",
    @8: @"bar",
    @5: @"baz",
    @9: @"ping",
    @3: @"pong"
  };
});

it(@"should not change dictionary when merging an enmpty dictionary", ^{
  expect([sourceDictionary lt_merge:@{}]).to.equal(sourceDictionary);
});

it(@"should add entries from dictionary", ^{
  auto updatedDictionary = [sourceDictionary lt_merge:@{
    @10: @"bar",
    @19: @"quee"
  }];

  auto expectedDictonary = @{
    @4: @"foo",
    @8: @"bar",
    @5: @"baz",
    @9: @"ping",
    @3: @"pong",
    @10: @"bar",
    @19: @"quee"
  };

  expect(updatedDictionary).to.equal(expectedDictonary);
});

it(@"should override source dictionary entries", ^{
  auto updatedDictionary = [sourceDictionary lt_merge:@{
    @10: @"bar",
    @3: @"thud"
  }];

  auto expectedDictonary = @{
    @4: @"foo",
    @8: @"bar",
    @5: @"baz",
    @9: @"ping",
    @3: @"thud",
    @10: @"bar"
  };

  expect(updatedDictionary).to.equal(expectedDictonary);
});

it(@"should remove keys", ^{
  auto updatedDictionary = [sourceDictionary lt_removeObjectsForKeys:@[@4, @8]];

  auto expectedDictonary = @{
    @5: @"baz",
    @9: @"ping",
    @3: @"pong"
  };

  expect(updatedDictionary).to.equal(expectedDictonary);
});

it(@"should not remove non existing keys", ^{
  auto updatedDictionary = [sourceDictionary lt_removeObjectsForKeys:@[@7, @21]];

  expect(updatedDictionary).to.equal(sourceDictionary);
});

SpecEnd

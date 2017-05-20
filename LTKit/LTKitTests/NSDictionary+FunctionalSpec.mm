// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSDictionary+Functional.h"

SpecBegin(NSDictionary_Functional)

context(@"filter", ^{
  __block NSDictionary<NSNumber *, NSString *> *baseDictionary;

  beforeEach(^{
    baseDictionary = @{
      @4: @"foo",
      @8: @"bar",
      @5: @"baz",
      @9: @"ping",
      @3: @"pong"
    };
  });

  it(@"should return all and only those items that the filter block has returned YES for", ^{
    auto filteredDictionary = [baseDictionary lt_filter:^BOOL(NSNumber * key, NSString *) {
      return key.unsignedIntegerValue > 5;
    }];

    expect(filteredDictionary).to.equal(@{
      @8: @"bar",
      @9: @"ping"
    });
  });

  it(@"should return empty array if block returns NO for all items", ^{
    auto filteredDictionary = [baseDictionary lt_filter:^BOOL(NSNumber *, NSString *) {
      return NO;
    }];

    expect(filteredDictionary).to.equal(@{});
  });
});

SpecEnd

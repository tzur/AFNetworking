// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSDictionary+Functional.h"

#import "NSArray+NSSet.h"

static NSDictionary<NSNumber *, NSString *> *const kSourceDictionary = @{
  @4: @"foo",
  @8: @"bar",
  @5: @"baz",
  @9: @"ping",
  @3: @"pong"
};

SpecBegin(NSDictionary_Functional)

context(@"map values", ^{
  it(@"should map the values using the provided block", ^{
    auto mapped = [kSourceDictionary lt_mapValues:^id(NSNumber *key, NSString *obj) {
      return [NSString stringWithFormat:@"%@ %@", key, obj];
    }];

    expect(mapped).to.equal(@{
      @4: @"4 foo",
      @8: @"8 bar",
      @5: @"5 baz",
      @9: @"9 ping",
      @3: @"3 pong"
    });
  });

  it(@"should raise if mapping block returns nil", ^{
    expect(^{
      [kSourceDictionary lt_mapValues:^id(NSNumber *, NSString *) {
        return nil;
      }];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"filter", ^{
  it(@"should return all and only those items that the filter block has returned YES for", ^{
    auto filteredDictionary = [kSourceDictionary lt_filter:^BOOL(NSNumber * key, NSString *) {
      return key.unsignedIntegerValue > 5;
    }];

    expect(filteredDictionary).to.equal(@{
      @8: @"bar",
      @9: @"ping"
    });
  });

  it(@"should return empty dictionary if block returns NO for all items", ^{
    auto filteredDictionary = [kSourceDictionary lt_filter:^BOOL(NSNumber *, NSString *) {
      return NO;
    }];

    expect(filteredDictionary).to.equal(@{});
  });
});

context(@"map to array", ^{
  it(@"should map the values using the provided block", ^{
    auto mapped = [kSourceDictionary lt_mapToArray:^NSString *(NSNumber *key, NSString *obj) {
      return [NSString stringWithFormat:@"%@ %@", key, obj];
    }];

    expect(mapped.count).to.equal(kSourceDictionary.count);
    expect([mapped lt_set])
        .to.equal([@[@"4 foo", @"8 bar", @"5 baz", @"9 ping", @"3 pong"] lt_set]);
  });
});

SpecEnd

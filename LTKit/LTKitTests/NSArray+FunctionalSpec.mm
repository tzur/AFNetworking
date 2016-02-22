// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSArray+Functional.h"

SpecBegin(NSArray_Functional)

static NSArray<NSNumber *> * const kSourceArray = @[@1, @3, @3, @7];

context(@"map", ^{
  it(@"should map the source array using the provided block", ^{
    NSArray *mapped = [kSourceArray lt_map:^(NSNumber * _Nonnull object) {
      return @([object integerValue] * [object integerValue]);
    }];
    expect(mapped).to.equal(@[@1, @9, @9, @49]);
  });

  it(@"should raise if mapping block returns nil", ^{
    expect(^{
      [kSourceArray lt_map:^id _Nonnull(NSNumber * _Nonnull) {
        return nil;
      }];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"reduce", ^{
  it(@"should reduce the source array using the provided block and initial value", ^{
    NSNumber *value =
        [kSourceArray lt_reduce:^id _Nonnull(id  _Nonnull value, NSNumber * _Nonnull object) {
          return @([object integerValue] + [value integerValue]);
        } initial:@(-14)];
    expect(value).to.equal(0);
  });
});

SpecEnd

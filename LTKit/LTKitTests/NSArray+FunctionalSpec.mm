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

context(@"filter", ^{
  it(@"should return all and only those items that the filter block has returned yes for", ^{
    NSArray<NSNumber *> *array = @[@3, @1, @3, @3, @7];
    NSArray<NSNumber *> *filteredArray = [array lt_filter:^BOOL(NSNumber *object) {
      return ![object isEqual:@3];
    }];

    expect(filteredArray).to.equal(@[@1, @7]);
  });

  it(@"should return empty array if block returns no for all items", ^{
    NSArray<NSNumber *> *array = @[@3, @1, @3, @3, @7];
    NSArray<NSNumber *> *filteredArray = [array lt_filter:^BOOL(NSNumber *) {
      return NO;
    }];

    expect(filteredArray).to.equal(@[]);
  });
});

context(@"classify", ^{
  it(@"should return a dictionary mapping objects to their labels", ^{
    NSArray<NSNumber *> *array = @[@(-1), @0, @1];
    NSDictionary<NSNumber *, NSArray<NSNumber *> *> *classifiedArray =
        (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)
        [array lt_classify:^NSNumber * _Nonnull(NSNumber * _Nonnull value) {
          return @([value integerValue] >= 0);
        }];

    expect(classifiedArray.allKeys.count).to.equal(2);
    expect(classifiedArray[@YES]).to.equal(@[@0, @1]);
    expect(classifiedArray[@NO]).to.equal(@[@(-1)]);
  });

  it(@"should return a dictionary mapping one label for all objects", ^{
    NSArray<NSNumber *> *array = @[@(-1), @0, @1];
    NSDictionary<NSString *, NSArray<NSNumber *> *> *classifiedArray =
        (NSDictionary<NSString *, NSArray<NSNumber *> *> *)
        [array lt_classify:^NSString * _Nonnull(NSNumber *) {
          return @"foo";
        }];

    expect(classifiedArray.allKeys.count).to.equal(1);
    expect(classifiedArray[@"foo"]).to.equal(array);
  });

  it(@"should return a dictionary with a unique label for each object", ^{
    NSArray<NSNumber *> *array = @[@(-1), @0, @1];
    NSDictionary<NSNumber *, NSArray<NSNumber *> *> *classifiedArray =
        (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)
        [array lt_classify:^NSNumber * _Nonnull(NSNumber * _Nonnull value) {
          return value;
        }];

    expect(classifiedArray.allKeys.count).to.equal(array.count);
    expect(classifiedArray[@0]).to.equal(@[@0]);
    expect(classifiedArray[@1]).to.equal(@[@1]);
    expect(classifiedArray[@(-1)]).to.equal(@[@(-1)]);
  });
});

SpecEnd

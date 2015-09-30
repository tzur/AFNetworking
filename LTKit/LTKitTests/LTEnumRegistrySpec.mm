// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEnumRegistry.h"

LTEnumMake(NSUInteger, LTMyName,
  LTMyNameA,
  LTMyNameB,
  LTMyNameC
);

LTEnumMakeWithValues(NSUInteger, LTMyNameWithValues,
  LTMyNameWithValuesA, 5,
  LTMyNameWithValuesB, 7,
  LTMyNameWithValuesC, 550
);

LTEnumMakeWithValues(NSUInteger, LTMyNameWithUnorderedValues,
  LTMyNameWithUnorderedValuesA, 2,
  LTMyNameWithUnorderedValuesB, 1,
  LTMyNameWithUnorderedValuesC, 3
);

SpecBegin(LTEnumRegistry)

it(@"should register enum", ^{
  expect([[LTEnumRegistry sharedInstance] isEnumRegistered:@"LTMyName"]).to.beTruthy();
});

context(@"automatic value assignment", ^{
  it(@"should have correct field to value mapping", ^{
    LTBidirectionalMap<NSString *, NSNumber *> *fieldToValue =
        [LTEnumRegistry sharedInstance][@"LTMyName"];
    LTBidirectionalMap<NSString *, NSNumber *> *expectedFieldToValue =
        [LTBidirectionalMap mapWithDictionary:@{
          @"LTMyNameA": @0,
          @"LTMyNameB": @1,
          @"LTMyNameC": @2,
        }];

    expect(fieldToValue).to.equal(expectedFieldToValue);
  });
});

context(@"manual value assignment", ^{
  it(@"should have correct field to value mapping", ^{
    LTBidirectionalMap<NSString *, NSNumber *> *fieldToValue =
        [LTEnumRegistry sharedInstance][@"LTMyNameWithValues"];
    LTBidirectionalMap<NSString *, NSNumber *> *expectedFieldToValue =
        [LTBidirectionalMap mapWithDictionary:@{
          @"LTMyNameWithValuesA": @5,
          @"LTMyNameWithValuesB": @7,
          @"LTMyNameWithValuesC": @550,
        }];

    expect(fieldToValue).to.equal(expectedFieldToValue);
  });
});

context(@"enum objects", ^{
  it(@"should get correct name from value", ^{
    LTMyNameWithValues *enumObjectA = [LTMyNameWithValues enumWithValue:LTMyNameWithValuesA];
    expect(enumObjectA.name).to.equal(@"LTMyNameWithValuesA");

    LTMyNameWithValues *enumObjectB = [LTMyNameWithValues enumWithValue:LTMyNameWithValuesB];
    expect(enumObjectB.name).to.equal(@"LTMyNameWithValuesB");

    LTMyNameWithValues *enumObjectC = [LTMyNameWithValues enumWithValue:LTMyNameWithValuesC];
    expect(enumObjectC.name).to.equal(@"LTMyNameWithValuesC");
  });

  it(@"should get correct value from name", ^{
    LTMyNameWithValues *enumObjectA = [LTMyNameWithValues enumWithName:@"LTMyNameWithValuesA"];
    expect(enumObjectA.value).to.equal(LTMyNameWithValuesA);

    LTMyNameWithValues *enumObjectB = [LTMyNameWithValues enumWithName:@"LTMyNameWithValuesB"];
    expect(enumObjectB.value).to.equal(LTMyNameWithValuesB);

    LTMyNameWithValues *enumObjectC = [LTMyNameWithValues enumWithName:@"LTMyNameWithValuesC"];
    expect(enumObjectC.value).to.equal(LTMyNameWithValuesC);
  });

  it(@"should enumerate enum values", ^{
    NSMutableArray<NSNumber *> *values = [NSMutableArray array];

    [LTMyNameWithValues enumerateValuesUsingBlock:^(_LTMyNameWithValues value) {
      [values addObject:@(value)];
    }];

    expect([values sortedArrayUsingSelector:@selector(compare:)]).to.equal(
      @[@(LTMyNameWithValuesA), @(LTMyNameWithValuesB), @(LTMyNameWithValuesC)]
    );
  });

  it(@"should enumerate enum objects", ^{
    NSMutableArray<LTMyNameWithValues *> *values = [NSMutableArray array];

    [LTMyNameWithValues enumerateEnumUsingBlock:^(LTMyNameWithValues *value) {
      [values addObject:value];
    }];

    expect([values sortedArrayUsingSelector:@selector(compare:)]).to.equal(
      @[$(LTMyNameWithValuesA), $(LTMyNameWithValuesB), $(LTMyNameWithValuesC)]
    );
  });

  it(@"should return new enum object with next value", ^{
    LTMyNameWithUnorderedValues *value =
      [LTMyNameWithUnorderedValues enumWithValue:LTMyNameWithUnorderedValuesB];
    value = [value enumWithNextValue];
    expect(value.value).to.equal(LTMyNameWithUnorderedValuesA);

    value = [value enumWithNextValue];
    expect(value.value).to.equal(LTMyNameWithUnorderedValuesC);

    value = [value enumWithNextValue];
    expect(value).to.beNil();
  });

  it(@"should encode and decode enum", ^{
    LTMyName *value1 = $(LTMyNameA);
    LTMyName *value2 = $(LTMyNameB);
    NSData *data1 = [NSKeyedArchiver archivedDataWithRootObject:value1];
    NSData *data2 = [NSKeyedArchiver archivedDataWithRootObject:value2];
    expect([NSKeyedUnarchiver unarchiveObjectWithData:data1]).to.equal(value1);
    expect([NSKeyedUnarchiver unarchiveObjectWithData:data2]).to.equal(value2);
  });

  it(@"should copy", ^{
    LTMyName *value1 = $(LTMyNameB);
    LTMyName *copy1 = [value1 copy];
    expect(copy1).to.equal(value1);
    expect(copy1).toNot.beIdenticalTo(value1);

    LTMyNameWithValues *value2 = $(LTMyNameWithValuesA);
    LTMyNameWithValues *copy2 = [value2 copy];
    expect(copy2).to.equal(value2);
    expect(copy2).toNot.beIdenticalTo(value2);

    LTMyNameWithUnorderedValues *value3 = $(LTMyNameWithUnorderedValuesC);
    LTMyNameWithUnorderedValues *copy3 = [value3 copy];
    expect(copy3).to.equal(value3);
    expect(copy3).toNot.beIdenticalTo(value3);
  });
});

SpecEnd

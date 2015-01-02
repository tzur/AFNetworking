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
    NSDictionary *fieldToValue = [LTEnumRegistry sharedInstance][@"LTMyName"];
    LTBidirectionalMap *expectedFieldToValue = [LTBidirectionalMap mapWithDictionary:@{
      @"LTMyNameA": @0,
      @"LTMyNameB": @1,
      @"LTMyNameC": @2,
    }];

    expect(fieldToValue).to.equal(expectedFieldToValue);
  });
});

context(@"manual value assignment", ^{
  it(@"should have correct field to value mapping", ^{
    NSDictionary *fieldToValue = [LTEnumRegistry sharedInstance][@"LTMyNameWithValues"];
    LTBidirectionalMap *expectedFieldToValue = [LTBidirectionalMap mapWithDictionary:@{
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
    NSMutableArray *values = [NSMutableArray array];

    [LTMyNameWithValues enumerateValuesUsingBlock:^(_LTMyNameWithValues value) {
      [values addObject:@(value)];
    }];

    expect([values sortedArrayUsingSelector:@selector(compare:)]).to.equal(
      @[@(LTMyNameWithValuesA), @(LTMyNameWithValuesB), @(LTMyNameWithValuesC)]
    );
  });

  it(@"should enumerate enum objects", ^{
    NSMutableArray *values = [NSMutableArray array];

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
});

SpecEnd

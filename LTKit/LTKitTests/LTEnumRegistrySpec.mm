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
  LTMyNameWithValuesC, 9
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
      @"LTMyNameWithValuesC": @9,
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
});

SpecEnd

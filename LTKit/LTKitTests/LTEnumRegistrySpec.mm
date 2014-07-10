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
    NSDictionary *expectedFieldToValue = @{
      @"LTMyNameA": @0,
      @"LTMyNameB": @1,
      @"LTMyNameC": @2,
    };

    expect(fieldToValue).to.equal(expectedFieldToValue);
  });
});

context(@"manual value assignment", ^{
  it(@"should have correct field to value mapping", ^{
    NSDictionary *fieldToValue = [LTEnumRegistry sharedInstance][@"LTMyNameWithValues"];
    NSDictionary *expectedFieldToValue = @{
      @"LTMyNameWithValuesA": @5,
      @"LTMyNameWithValuesB": @7,
      @"LTMyNameWithValuesC": @9,
    };

    expect(fieldToValue).to.equal(expectedFieldToValue);
  });
});

SpecEnd

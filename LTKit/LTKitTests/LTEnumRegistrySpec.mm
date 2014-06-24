// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEnumRegistry.h"

LTEnumMake(NSUInteger, LTMyName,
           LTMyNameA,
           LTMyNameB,
           LTMyNameC);

SpecBegin(LTEnumRegistry)

it(@"should register enum", ^{
  expect([[LTEnumRegistry sharedInstance] isEnumRegistered:@"LTMyName"]).to.beTruthy();
});

it(@"should have correct field to value mapping", ^{
  NSDictionary *fieldToValue = [LTEnumRegistry sharedInstance][@"LTMyName"];
  NSDictionary *expectedFieldToValue = @{
    @"LTMyNameA": @0,
    @"LTMyNameB": @1,
    @"LTMyNameC": @2,
  };

  expect(fieldToValue).to.equal(expectedFieldToValue);
});

SpecEnd

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "PTULocalization.h"

SpecBegin(PTULocalization)

__block NSDictionary<NSString *, LTLocalizationTable *> *localizationTables;

beforeEach(^{
  localizationTables = [PTULocalization localizationTables];
});

it(@"should not be empty", ^{
  expect(localizationTables.count).to.beGreaterThan(0);
});

SpecEnd

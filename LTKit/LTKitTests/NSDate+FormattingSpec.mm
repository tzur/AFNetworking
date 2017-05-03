// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "NSDate+Formatting.h"

SpecBegin(NSDate_Formatting)

it(@"should return a date string with the correct format", ^{
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:60];
  NSTimeZone *timezone = [NSTimeZone systemTimeZone];
  NSInteger timezoneOffset = [timezone secondsFromGMT] - [timezone daylightSavingTimeOffset];

  NSDate *offsetDate = [NSDate dateWithTimeInterval:-timezoneOffset sinceDate:date];
  expect([offsetDate lt_deviceTimezoneString]).to.equal(@"00:01:00.000");
});

SpecEnd

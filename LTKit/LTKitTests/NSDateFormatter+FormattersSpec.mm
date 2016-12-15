// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSDateFormatter+Formatters.h"

SpecBegin(NSDateFormatter_Formatters)

context(@"UTC date formatter", ^{
  __block NSDateFormatter *dateFormatter;

  beforeEach(^{
    dateFormatter = [NSDateFormatter lt_UTCDateFormatter];
  });

  it(@"should output a date string with the correct format", ^{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:60];
    NSString *expectedDateString = @"1970-01-01T00:01:00.000Z";

    expect([dateFormatter stringFromDate:date]).to.equal(expectedDateString);
  });

  it(@"should return a valid date from a correctly formatted string date", ^{
    NSString *stringDate = @"1970-01-01T00:01:00.000Z";
    NSDate *expectedDate = [NSDate dateWithTimeIntervalSince1970:60];

    expect([dateFormatter dateFromString:stringDate]).to.equal(expectedDate);
  });
});

SpecEnd

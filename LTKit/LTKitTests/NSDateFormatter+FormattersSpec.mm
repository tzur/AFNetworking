// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSDateFormatter+Formatters.h"

SpecBegin(NSDateFormatter_Formatters)

static NSString * const kKeyForDateFormatter = @"dateFormatter";
static NSString * const kKeyForDate = @"date";
static NSString * const kKeyForStringDate = @"stringDate";

sharedExamplesFor(@"formatting", ^(NSDictionary *data) {
  __block NSDateFormatter *dateFormatter;

  beforeEach(^{
    dateFormatter = data[kKeyForDateFormatter];
  });

  it(@"should output a date string with the correct format", ^{
    NSDate *date = data[kKeyForDate];
    NSString *expectedStringDate = data[kKeyForStringDate];

    expect([dateFormatter stringFromDate:date]).to.equal(expectedStringDate);
  });

  it(@"should return a valid date from a correctly formatted string date", ^{
    NSString *stringDate = data[kKeyForStringDate];
    NSDate *expectedDate = data[kKeyForDate];

    expect([dateFormatter dateFromString:stringDate]).to.equal(expectedDate);
  });
});

context(@"UTC date formatter", ^{
  itShouldBehaveLike(@"formatting", @{
    kKeyForDateFormatter: [NSDateFormatter lt_UTCDateFormatter],
    kKeyForDate: [NSDate dateWithTimeIntervalSince1970:60],
    kKeyForStringDate: @"1970-01-01T00:01:00.000Z"
  });
});

context(@"device timezone date formatter", ^{
  itShouldBehaveLike(@"formatting", ^{
    NSInteger timezoneOffset = [[NSTimeZone systemTimeZone] secondsFromGMT];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:60];

    return @{
      kKeyForDateFormatter: [NSDateFormatter lt_deviceTimezoneDateFormatter],
      kKeyForDate: [NSDate dateWithTimeInterval:-timezoneOffset sinceDate:date],
      kKeyForStringDate: @"00:01:00.000"
    };
  });
});

SpecEnd

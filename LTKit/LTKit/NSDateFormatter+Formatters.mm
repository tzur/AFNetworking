// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSDateFormatter+Formatters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSDateFormatter (Formatters)

+ (instancetype)lt_UTCDateFormatter {
  NSDateFormatter *dateFormatter = [self lt_localeNeutralDateFormatter];
  dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
  dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
  return dateFormatter;
}

+ (instancetype)lt_deviceTimezoneDateFormatter {
  NSDateFormatter *dateFormatter = [self lt_localeNeutralDateFormatter];
  dateFormatter.dateFormat = @"HH:mm:ss.SSS";
  dateFormatter.defaultDate = [NSDate dateWithTimeIntervalSince1970:0];
  return dateFormatter;
}

+ (instancetype)lt_localeNeutralDateFormatter {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
  return dateFormatter;
}

@end

NS_ASSUME_NONNULL_END

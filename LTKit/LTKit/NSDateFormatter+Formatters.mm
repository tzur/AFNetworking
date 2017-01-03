// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSDateFormatter+Formatters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSDateFormatter (Formatters)

+ (instancetype)lt_UTCDateFormatter {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
  dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
  dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
  return dateFormatter;
}

@end

NS_ASSUME_NONNULL_END

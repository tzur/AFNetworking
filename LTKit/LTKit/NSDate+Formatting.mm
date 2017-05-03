// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "NSDate+Formatting.h"

#import "NSDateFormatter+Formatters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSDate (Formatting)

- (NSString *)lt_deviceTimezoneString {
  return [[NSDate lt_deviceTimezoneDateFormatter] stringFromDate:self];
}

+ (NSDateFormatter *)lt_deviceTimezoneDateFormatter {
  static NSDateFormatter *dateFormatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [NSDateFormatter lt_deviceTimezoneDateFormatter];
  });
  return dateFormatter;
}

@end

NS_ASSUME_NONNULL_END

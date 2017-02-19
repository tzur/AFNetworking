// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Zur Tene.

#import "PTUTimeFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUTimeFormatter ()

/// Used to format \c NSDate to \c NSString.
@property (readonly, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation PTUTimeFormatter

- (instancetype)init {
  if (self = [super init]) {
    _dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
  }
  return self;
}

- (NSString *)timeStringForTime:(CMTime)time {
  CGFloat timeInSeconds = (CMTIME_IS_VALID(time)) ? CMTimeGetSeconds(time) : 0;
  return [self timeStringForTimeInSeconds:timeInSeconds];
}

- (NSString *)timeStringForTimeInterval:(NSTimeInterval)timeInterval {
  return [self timeStringForTimeInSeconds:timeInterval];
}

- (NSString *)timeStringForTimeInSeconds:(CGFloat)timeInSeconds {
  self.dateFormatter.dateFormat = (timeInSeconds >= 3600) ? @"hh:mm:ss" : @"mm:ss";
  NSDate *dateOfTime = [NSDate dateWithTimeIntervalSince1970:timeInSeconds];
  return [self.dateFormatter stringFromDate:dateOfTime];
}

@end

NS_ASSUME_NONNULL_END

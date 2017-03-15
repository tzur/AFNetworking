// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTEventMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@implementation INTEventMetadata

- (instancetype)initWithTotalRunTime:(NSTimeInterval)totalRunTime
                   foregroundRunTime:(NSTimeInterval)foregroundRunTime
                     deviceTimestamp:(NSDate *)deviceTimestamp eventID:(NSUUID *)eventID {
  if (self = [super init]) {
    _totalRunTime = totalRunTime;
    _foregroundRunTime = foregroundRunTime;
    _deviceTimestamp = deviceTimestamp;
    _eventID = eventID;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END

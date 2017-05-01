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

INTEventMetadata *INTCreateEventMetadata(NSTimeInterval totalRunTime,
                                         NSTimeInterval foregroundRunTime,
                                         NSDate * _Nullable deviceTimestamp,
                                         NSUUID * _Nullable eventID) {
  return [[INTEventMetadata alloc] initWithTotalRunTime:totalRunTime
                                      foregroundRunTime:foregroundRunTime
                                        deviceTimestamp:deviceTimestamp ?: [NSDate date]
                                                eventID:eventID ?: [NSUUID UUID]];
}

NS_ASSUME_NONNULL_END

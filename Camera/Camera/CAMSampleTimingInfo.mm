// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CAMSampleTimingInfo.h"

NS_ASSUME_NONNULL_BEGIN

NSUInteger CAMSampleTimingInfoHash(CMSampleTimingInfo sampleTimingInfo) {
  return [NSValue value:&sampleTimingInfo withObjCType:@encode(CMSampleTimingInfo)].hash;
}

BOOL CAMSampleTimingInfoIsEqual(CMSampleTimingInfo left, CMSampleTimingInfo right) {
  NSValue *leftValue = [NSValue value:&left withObjCType:@encode(CMSampleTimingInfo)];
  NSValue *rightValue = [NSValue value:&right withObjCType:@encode(CMSampleTimingInfo)];
  return [leftValue isEqualToValue:rightValue];
}

NS_ASSUME_NONNULL_END

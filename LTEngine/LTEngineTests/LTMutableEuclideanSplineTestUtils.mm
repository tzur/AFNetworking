// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTMutableEuclideanSplineTestUtils.h"

#import "LTSplineControlPoint.h"

NSArray<LTSplineControlPoint *> *LTCreateSplinePoints(CGFloats timestamps,
                                                      std::vector<CGPoint> locations,
                                                      NSString *attributeKey,
                                                      NSArray<NSNumber *> *values) {
  LTParameterAssert(timestamps.size() == locations.size());
  NSMutableArray<LTSplineControlPoint *> *mutablePoints =
      [NSMutableArray arrayWithCapacity:timestamps.size()];
  for (CGFloats::size_type i = 0; i < timestamps.size(); ++i) {
    [mutablePoints addObject:[[LTSplineControlPoint alloc]
                              initWithTimestamp:timestamps[i] location:locations[i]
                              attributes:@{attributeKey: values[i]}]];
  }
  return [mutablePoints copy];
}

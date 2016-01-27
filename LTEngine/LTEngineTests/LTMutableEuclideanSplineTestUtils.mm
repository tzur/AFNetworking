// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Lightricks.

#import "LTMutableEuclideanSplineTestUtils.h"

#import "LTEuclideanSplineControlPoint.h"

NSArray<LTEuclideanSplineControlPoint *> *LTCreateSplinePoints(CGFloats timestamps,
                                                               std::vector<CGPoint> locations,
                                                               NSString *attributeKey,
                                                               NSArray<NSNumber *> *values) {
  LTParameterAssert(timestamps.size() == locations.size());
  NSMutableArray<LTEuclideanSplineControlPoint *> *mutablePoints =
      [NSMutableArray arrayWithCapacity:timestamps.size()];
  for (CGFloats::size_type i = 0; i < timestamps.size(); ++i) {
    [mutablePoints addObject:[[LTEuclideanSplineControlPoint alloc]
                              initWithTimestamp:timestamps[i] location:locations[i]
                              attributes:@{attributeKey: values[i]}]];
  }
  return [mutablePoints copy];
}

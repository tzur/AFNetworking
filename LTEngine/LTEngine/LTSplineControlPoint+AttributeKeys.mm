// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSplineControlPoint+AttributeKeys.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTSplineControlPoint (AttributeKeys)

+ (NSString *)keyForRadius {
  return @"radius";
}

+ (NSString *)keyForForce {
  return @"force";
}

+ (NSString *)keyForSpeedInScreenCoordinates {
  return @"speedInViewCoordinates";
}

@end

NS_ASSUME_NONNULL_END

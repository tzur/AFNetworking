// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTLinearInterpolationRoutine.h"

#import "LTInterpolatedObject.h"

@implementation LTLinearInterpolationRoutine

- (NSDictionary *)calculateCoefficientsForKeyFrames:(NSArray *)keyFrames {
  NSArray *propertiesToInterpolate = [keyFrames.firstObject propertiesToInterpolate];
  NSObject *first = keyFrames.firstObject;
  NSObject *last = keyFrames.lastObject;
  NSMutableDictionary *coefficients = [NSMutableDictionary dictionary];
  for (NSString *propertyName in propertiesToInterpolate) {
    double firstValue = [[first valueForKey:propertyName] doubleValue];
    double lastValue = [[last valueForKey:propertyName] doubleValue];
    coefficients[propertyName] = @[@(lastValue - firstValue), @(firstValue)];
  }
  return coefficients;
}

+ (NSUInteger)expectedKeyFrames {
  return 2;
}

@end

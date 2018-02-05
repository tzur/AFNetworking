// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "NSValue+LTInterval.h"

@implementation NSValue (LTInterval)

- (lt::Interval<CGFloat>)LTCGFloatIntervalValue {
  lt::Interval<CGFloat> interval;
  [self getValue:&interval];
  return interval;
}

- (lt::Interval<NSUInteger>)LTNSUIntegerIntervalValue {
  lt::Interval<NSUInteger> interval;
  [self getValue:&interval];
  return interval;
}

- (lt::Interval<NSInteger>)LTNSIntegerIntervalValue {
  lt::Interval<NSInteger> interval;
  [self getValue:&interval];
  return interval;
}

+ (NSValue *)valueWithLTCGFloatInterval:(lt::Interval<CGFloat>)interval {
  return [NSValue valueWithBytes:&interval objCType:@encode(lt::Interval<CGFloat>)];
}

+ (NSValue *)valueWithLTNSUIntegerInterval:(lt::Interval<NSUInteger>)interval {
  return [NSValue valueWithBytes:&interval objCType:@encode(lt::Interval<NSUInteger>)];
}

+ (NSValue *)valueWithLTNSIntegerInterval:(lt::Interval<NSInteger>)interval {
  return [NSValue valueWithBytes:&interval objCType:@encode(lt::Interval<NSInteger>)];
}

@end

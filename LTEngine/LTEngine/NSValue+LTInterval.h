// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInterval.h"

#ifdef __cplusplus

@interface NSValue (LTInterval)

- (lt::Interval<CGFloat>)LTCGFloatIntervalValue;
- (lt::Interval<NSUInteger>)LTNSUIntegerIntervalValue;
- (lt::Interval<NSInteger>)LTNSIntegerIntervalValue;

+ (NSValue *)valueWithLTCGFloatInterval:(lt::Interval<CGFloat>)interval;
+ (NSValue *)valueWithLTNSUIntegerInterval:(lt::Interval<NSUInteger>)interval;
+ (NSValue *)valueWithLTNSIntegerInterval:(lt::Interval<NSInteger>)interval;

@end

#endif

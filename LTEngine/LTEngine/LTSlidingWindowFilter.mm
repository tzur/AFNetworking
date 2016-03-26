// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTSlidingWindowFilter.h"

NS_ASSUME_NONNULL_BEGIN

/// A list of \c CGFloat.
typedef std::list<CGFloat> CGFloatList;

@interface LTSlidingWindowFilter () {
  CGFloatList _values;
  CGFloats _weights;
}

@end

@implementation LTSlidingWindowFilter

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return nil;
}

- (instancetype)initWithKernel:(const CGFloats &)kernel {
  if (self = [super init]) {
    _weights = kernel;
  }
  return self;
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (void)clear {
  _values.clear();
}

- (CGFloat)pushValueAndFilter:(CGFloat)value {
  if (!_values.size()) {
    _values = CGFloatList(_weights.size(), value);
  } else {
    _values.pop_front();
    _values.push_back(value);
  }
  return [self weightedAverageForLastValue];
}

- (CGFloat)weightedAverageForLastValue {
  CGFloat value = 0;
  NSUInteger index = 0;
  for (auto it = _values.cbegin(); it != _values.cend(); ++it, ++index) {
    value += *it * _weights[index];
  }

  return value;
}

@end

NS_ASSUME_NONNULL_END

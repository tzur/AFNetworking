// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTReparameterization.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTReparameterization () {
  /// Mapping used to compute the reparameterization.
  CGFloats _mapping;
}

@end

@implementation LTReparameterization

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithMapping:(CGFloats)mapping {
  if (self = [super init]) {
    [self validateMapping:mapping];
    _mapping = mapping;
  }
  return self;
}

- (void)validateMapping:(const CGFloats &)mapping {
  LTParameterAssert(mapping.size() >= 2, @"Mapping must consist of at least two values.");

  const auto it = std::adjacent_find(mapping.cbegin(), mapping.cend(),
                                     [](CGFloat current, CGFloat next) {
    return current >= next;
  });

  LTParameterAssert(it == mapping.cend(), @"Mapping must be strictly monotonically increasing");
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark LTPrimitiveParameterizedObject
#pragma mark -

- (CGFloat)floatForParametricValue:(CGFloat)value {
  // TODO:(rouven) In case of performance issues, optimize the following lines such that they return
  // the requested iterator in O(1) rather than O(log n) for parametric values which fall into the
  // same or the next interval as the one returned for the previously provided parametric value.
  auto it = std::upper_bound(_mapping.begin(), _mapping.end() - 1, value);
  // \c it points to the first element of \c _mapping that is greater than \c value. In case that
  // this element is not the first element of \c _mapping, make \c it point to the previous element,
  // which is the beginning of the interval subsequently used to compute the result value, via
  // linear interpolation.
  it = it != _mapping.begin() ? it - 1 : it;

  // Compute the mapped value by linearly interpolating the corresponding position inside the
  // computed interval.
  CGFloat start = *it;
  CGFloat end = *(it + 1);
  CGFloat factor = (value - start) / (end - start);
  const auto index = it - _mapping.begin();
  const auto lastIndex = _mapping.size() - 1;
  return (index + factor) / lastIndex;
}

- (CGFloat)minParametricValue {
  return _mapping.front();
}

- (CGFloat)maxParametricValue {
  return _mapping.back();
}

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizationKeyToValues.h"

#import <LTKit/LTHashExtensions.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTParameterizationKeyToValues () {
  cv::Mat1g _valuesPerKey;
}

@end

@implementation LTParameterizationKeyToValues

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithKeys:(NSOrderedSet<NSString *> *)keys
                valuesPerKey:(const cv::Mat1g &)valuesPerKey {
  LTParameterAssert(keys.count > 0, @"There must be at least one key");
  LTParameterAssert(keys.count <= INT_MAX,
                    @"Number (%lu) of keys must not exceed INT_MAX", (unsigned long)keys.count);
  LTParameterAssert((int)keys.count == valuesPerKey.rows,
                    @"Number (%lu) of keys must equal number (%lu) of rows",
                    (unsigned long)keys.count, (unsigned long)valuesPerKey.rows);

  if (self = [super init]) {
    _keys = [keys copy];
    _valuesPerKey = valuesPerKey;
    _numberOfValuesPerKey = valuesPerKey.cols;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTParameterizationKeyToValues *)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  return [self.keys isEqualToOrderedSet:object.keys] &&
      (sum(_valuesPerKey != object.valuesPerKey) == cv::Scalar(0));
}

- (NSUInteger)hash {
  size_t seed = 0;
  lt::hash_combine(seed, self.keys.hash);
  // Refrain from computing a hash of the matrix for efficiency reasons.
  return seed;
}

#pragma mark -
#pragma mark Public API
#pragma mark -

- (CGFloats)valuesForKey:(NSString *)key atIndices:(const std::vector<NSUInteger> &)indices {
  NSUInteger keyIndex = [self.keys indexOfObject:key];
  LTParameterAssert(keyIndex != NSNotFound, @"Object does not provide mapping for given key (%@)",
                    key);

  CGFloats values;
  values.reserve(indices.size());
  size_t numberOfValues = self.numberOfValuesPerKey;

  for (NSUInteger index : indices) {
    LTParameterAssert(index < numberOfValues,
                      @"Given index (%lu) must be smaller than number (%lu) of values",
                      (unsigned long)index, (unsigned long)numberOfValues);
    values.push_back(_valuesPerKey((int)keyIndex, (int)index));
  }
  return values;
}

- (CGFloats)valuesForKey:(NSString *)key {
  LTParameterAssert([self.keys containsObject:key], @"Key (%@) not found in keys (%@)", key,
                    self.keys);
  cv::Mat1g row(_valuesPerKey.row((int)[self.keys indexOfObject:key]));
  return CGFloats(row.begin(), row.end());
}

@end

NS_ASSUME_NONNULL_END

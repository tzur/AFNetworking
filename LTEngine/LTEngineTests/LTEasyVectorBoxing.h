// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Shorthand for boxing \c std::vector objects containing structs (for which the \c $ operator is
/// defined) with \c NSArray<NSValue *>. To use, wrap the std::vector variable with \c $().
template <typename T>
NS_INLINE NSArray *$(const std::vector<T> &vector) {
  NSMutableArray<NSValue *> *boxedVector = [NSMutableArray arrayWithCapacity:vector.size()];
  for (const auto &object : vector) {
    [boxedVector addObject:$(object)];
  }
  return [boxedVector copy];
}

NS_ASSUME_NONNULL_END

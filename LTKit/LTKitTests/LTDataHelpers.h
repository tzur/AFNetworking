// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// Returns a new \c NSData with \c bytes.
template <typename T>
NSData *LTVectorToNSData(const std::vector<T> &vector) {
  return [NSData dataWithBytes:&vector[0] length:vector.size() * sizeof(T)];
}

NS_ASSUME_NONNULL_END

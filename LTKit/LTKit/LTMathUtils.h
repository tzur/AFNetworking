// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Returns \c YES if given \c value is integral and a power of two.
NS_INLINE BOOL LTIsPowerOfTwo(CGFloat value) {
  int intValue = value;
  return intValue == value && !(intValue & (intValue - 1));
}

/// Returns \c YES if both dimensions of the given size are integral and a power of two.
NS_INLINE BOOL LTIsPowerOfTwo(CGSize size) {
  return LTIsPowerOfTwo(size.width) && LTIsPowerOfTwo(size.height);
}

/// Returns a value which a smooth non-linear interploation of \c min and \c max based on \c x.
NS_INLINE CGFloat LTSmoothstep(CGFloat min, CGFloat max, CGFloat x) {
  x = std::clamp((x - min) / (max - min), 0.0, 1.0);
  return x * x * (3 - 2 * x);
}

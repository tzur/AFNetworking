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

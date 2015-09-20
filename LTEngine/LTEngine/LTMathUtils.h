// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTypedefs+LTEngine.h"

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

#ifdef __cplusplus

/// Returns a collection of \c CGFloats representing half a gaussian with the given \c radius and
/// \c sigma (both must be greater than \c 0). The collection will have \c radius+1 elements, where
/// the last element is the center of the gaussian. In case \c normalized is \c YES, the sum of all
/// kernel weights will be \c 1.
CGFloats LTCreateHalfGaussian(NSUInteger radius, CGFloat sigma, BOOL normalized = YES);

#endif

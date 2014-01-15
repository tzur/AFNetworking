// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <GLKit/GLKMath.h>
#import <cmath>
#import <opencv2/core/core.hpp>

GLK_INLINE GLKMatrix3 GLKMatrix3MakeTranslation(float tx, float ty) {
  return GLKMatrix3Make(1, 0, 0,
                        0, 1, 0,
                        tx, ty, 1);
}

#ifdef __cplusplus

/// Multiply a vector by a scalar value.
inline GLKVector4 operator*(const GLKVector4 &lhs, const float &rhs) {
  return GLKVector4MultiplyScalar(lhs, rhs);
}
/// Multiply a vector by a scalar value.
inline GLKVector4 operator*(const float &lhs, const GLKVector4 &rhs) {
  return GLKVector4MultiplyScalar(rhs, lhs);
}

/// Divide a vector by a scalar value.
inline GLKVector3 operator/(const GLKVector3 &lhs, const float &rhs) {
  return GLKVector3DivideScalar(lhs, rhs);
}
/// Divide a vector by a scalar value.
inline GLKVector4 operator/(const GLKVector4 &lhs, const float &rhs)  {
  return GLKVector4DivideScalar(lhs, rhs);
}

namespace std {
  /// Find a sum of the components.
  CG_INLINE float sum(const GLKVector3 &v) {
    return v.x + v.y + v.z;
  }
  /// Find a sum of the components.
  CG_INLINE float sum(const GLKVector4 &v) {
    return v.x + v.y + v.z + v.w;
  }
}

#endif

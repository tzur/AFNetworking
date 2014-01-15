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

/// Returns whether two vectors are equal.
GLK_INLINE BOOL operator==(const GLKVector4 &lhs, const GLKVector4 &rhs) {
  return lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.a == rhs.a;
}

/// Returns whether two vectors are not equal.
GLK_INLINE BOOL operator!=(const GLKVector4 &lhs, const GLKVector4 &rhs) {
  return !(lhs == rhs);
}

/// Multiply a vector by a scalar value.
GLK_INLINE GLKVector4 operator*(const GLKVector4 &lhs, const GLfloat &rhs) {
  return GLKVector4MultiplyScalar(lhs, rhs);
}
/// Multiply a vector by a scalar value.
GLK_INLINE GLKVector4 operator*(const GLfloat &lhs, const GLKVector4 &rhs) {
  return GLKVector4MultiplyScalar(rhs, lhs);
}

/// Divide a vector by a scalar value (element wise).
GLK_INLINE GLKVector4 operator/(const GLKVector4 &lhs, const GLfloat &rhs) {
  return GLKVector4DivideScalar(lhs, rhs);
}

/// Creates a \c GLKVector4 from a \c cv::Vec4b.
GLK_INLINE GLKVector4 GLKVector4FromVec4b(const cv::Vec4b &vec) {
  return GLKVector4Make(vec(0), vec(1), vec(2), vec(3)) / 255.0;
}

namespace std {

/// Floors the given GLKVector2, coordinate-wise.
GLK_INLINE GLKVector2 floor(const GLKVector2 &vector) {
    return GLKVector2Make(floor(vector.x), floor(vector.y));
  }
}

#endif

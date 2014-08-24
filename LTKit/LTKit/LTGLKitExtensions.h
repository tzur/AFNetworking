// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <GLKit/GLKMath.h>
#import <cmath>
#import <opencv2/core/core.hpp>

/// A \c 2x2 identity matrix.
extern const GLKMatrix2 GLKMatrix2Identity;

/// Returns a \c 2x2 matrix created from individual component values.
GLK_INLINE GLKMatrix2 GLKMatrix2Make(float m00, float m01, float m10, float m11) {
  GLKMatrix2 m = {{m00, m01,
                   m10, m11}};
  return m;
}

/// Returns a \c 2x2 matrix that performs a scaling transformation.
GLK_INLINE GLKMatrix2 GLKMatrix2MakeScale(float sx, float sy) {
  return GLKMatrix2Make(sx, 0, 0, sy);
}

/// Returns a \c 2x2 matrix that performs counterclockwise rotation by the given angle (in radians).
GLK_INLINE GLKMatrix2 GLKMatrix2MakeRotation(float radians) {
  return GLKMatrix2Make(cosf(radians), sinf(radians),
                        -sinf(radians), cosf(radians));
}

/// Returns the transpose of a \c 2x2 matrix.
GLK_INLINE GLKMatrix2 GLKMatrix2Transpose(GLKMatrix2 matrix) {
  GLKMatrix2 m = {{matrix.m[0], matrix.m[2],
                   matrix.m[1], matrix.m[3]}};
  return m;
}

/// Returns the product of two \c 2x2 matrices.
GLK_INLINE GLKMatrix2 GLKMatrix2Multiply(GLKMatrix2 matrixLeft, GLKMatrix2 matrixRight) {
  GLKMatrix2 m;
  m.m[0] = matrixLeft.m[0] * matrixRight.m[0] + matrixLeft.m[2] * matrixRight.m[1];
  m.m[2] = matrixLeft.m[0] * matrixRight.m[2] + matrixLeft.m[2] * matrixRight.m[3];
  
  m.m[1] = matrixLeft.m[1] * matrixRight.m[0] + matrixLeft.m[3] * matrixRight.m[1];
  m.m[3] = matrixLeft.m[1] * matrixRight.m[2] + matrixLeft.m[3] * matrixRight.m[3];
  return m;
}

/// Multiplies a \c 2x2 matrix by a vector.
GLK_INLINE GLKVector2 GLKMatrix2MultiplyVector2(GLKMatrix2 matrixLeft, GLKVector2 vectorRight) {
  GLKVector2 v = {{matrixLeft.m[0] * vectorRight.v[0] + matrixLeft.m[2] * vectorRight.v[1],
                   matrixLeft.m[1] * vectorRight.v[0] + matrixLeft.m[3] * vectorRight.v[1]}};
  return v;
}

/// Returns a \c 3x3 matrix that performs a translation.
GLK_INLINE GLKMatrix3 GLKMatrix3MakeTranslation(float tx, float ty) {
  return GLKMatrix3Make(1, 0, 0,
                        0, 1, 0,
                        tx, ty, 1);
}

#ifdef __cplusplus

/// The "zero" vector, equivalent to GLKVector4Make(0, 0, 0, 0).
GLK_EXTERN const GLKVector4 GLKVector4Zero;

/// The "zero" vector, equivalent to GLKVector3Make(0, 0, 0).
GLK_EXTERN const GLKVector3 GLKVector3Zero;

/// The "zero" vector, equivalent to GLKVector2Make(0, 0).
GLK_EXTERN const GLKVector2 GLKVector2Zero;

/// The "one" vector, equivalent to GLKVector4Make(1, 1, 1, 1).
GLK_EXTERN const GLKVector4 GLKVector4One;

/// The "one" vector, equivalent to GLKVector3Make(1, 1, 1).
GLK_EXTERN const GLKVector3 GLKVector3One;

/// The "one" vector, equivalent to GLKVector2Make(1, 1).
GLK_EXTERN const GLKVector2 GLKVector2One;

/// Returns a new three-component vector with the same value for each component.
GLK_INLINE GLKVector3 GLKVector3Make(float value) {
  return GLKVector3Make(value, value, value);
}

/// Returns a new four-component vector with the same value for each component.
GLK_INLINE GLKVector4 GLKVector4Make(float value) {
  return GLKVector4Make(value, value, value, value);
}

/// Returns whether two vectors are equal.
GLK_INLINE BOOL operator==(const GLKVector2 &lhs, const GLKVector2 &rhs) {
  return !memcmp(lhs.v, rhs.v, sizeof(lhs.v));
}

/// Returns whether two vectors are equal.
GLK_INLINE BOOL operator==(const GLKVector3 &lhs, const GLKVector3 &rhs) {
  return !memcmp(lhs.v, rhs.v, sizeof(lhs.v));
}

/// Returns whether two vectors are equal.
GLK_INLINE BOOL operator==(const GLKVector4 &lhs, const GLKVector4 &rhs) {
  return !memcmp(lhs.v, rhs.v, sizeof(lhs.v));
}

/// Returns whether two matrices are equal.
GLK_INLINE BOOL operator==(const GLKMatrix2 &lhs, const GLKMatrix2 &rhs) {
  return !memcmp(lhs.m, rhs.m, sizeof(lhs.m));
}

/// Returns whether two matrices are equal.
GLK_INLINE BOOL operator==(const GLKMatrix3 &lhs, const GLKMatrix3 &rhs) {
  return !memcmp(lhs.m, rhs.m, sizeof(lhs.m));
}

/// Returns whether two matrices are equal.
GLK_INLINE BOOL operator==(const GLKMatrix4 &lhs, const GLKMatrix4 &rhs) {
  return !memcmp(lhs.m, rhs.m, sizeof(lhs.m));
}

/// Returns whether two vectors are not equal.
GLK_INLINE BOOL operator!=(const GLKVector2 &lhs, const GLKVector2 &rhs) {
  return !(lhs == rhs);
}

/// Returns whether two vectors are not equal.
GLK_INLINE BOOL operator!=(const GLKVector3 &lhs, const GLKVector3 &rhs) {
  return !(lhs == rhs);
}

/// Returns whether two vectors are not equal.
GLK_INLINE BOOL operator!=(const GLKVector4 &lhs, const GLKVector4 &rhs) {
  return !(lhs == rhs);
}

/// Returns whether two matrices are not equal.
GLK_INLINE BOOL operator!=(const GLKMatrix2 &lhs, const GLKMatrix2 &rhs) {
  return !(lhs == rhs);
}

/// Returns whether two matrices are not equal.
GLK_INLINE BOOL operator!=(const GLKMatrix3 &lhs, const GLKMatrix3 &rhs) {
  return !(lhs == rhs);
}

/// Returns whether two matrices are not equal.
GLK_INLINE BOOL operator!=(const GLKMatrix4 &lhs, const GLKMatrix4 &rhs) {
  return !(lhs == rhs);
}

/// Returns YES if each component in the second vector is greater than or equal to the corresponding
/// component of the first vector, NO otherwise.
GLK_INLINE BOOL operator<=(const GLKVector4 &lhs, const GLKVector4 &rhs) {
  return GLKVector4AllGreaterThanOrEqualToVector4(rhs, lhs);
}

/// Returns YES if each component in the first vector is greater than or equal to the corresponding
/// component of the second vector, NO otherwise.
GLK_INLINE BOOL operator>=(const GLKVector4 &lhs, const GLKVector4 &rhs) {
  return GLKVector4AllGreaterThanOrEqualToVector4(lhs, rhs);
}

/// Returns YES if each component in the second vector is greater than or equal to the corresponding
/// component of the first vector, NO otherwise.
GLK_INLINE BOOL operator<=(const GLKVector3 &lhs, const GLKVector3 &rhs) {
  return GLKVector3AllGreaterThanOrEqualToVector3(rhs, lhs);
}

/// Returns YES if each component in the first vector is greater than or equal to the corresponding
/// component of the second vector, NO otherwise.
GLK_INLINE BOOL operator>=(const GLKVector3 &lhs, const GLKVector3 &rhs) {
  return GLKVector3AllGreaterThanOrEqualToVector3(lhs, rhs);
}

/// Negate vector.
GLK_INLINE GLKVector2 operator-(const GLKVector2 &vec) {
  return GLKVector2Negate(vec);
}

/// Negate vector.
GLK_INLINE GLKVector3 operator-(const GLKVector3 &vec) {
  return GLKVector3Negate(vec);
}

/// Negate vector.
GLK_INLINE GLKVector4 operator-(const GLKVector4 &vec) {
  return GLKVector4Negate(vec);
}

/// Add two vectors.
GLK_INLINE GLKVector2 operator+(const GLKVector2 &lhs, const GLKVector2 &rhs) {
  return GLKVector2Add(lhs, rhs);
}

/// Add two vectors.
GLK_INLINE GLKVector3 operator+(const GLKVector3 &lhs, const GLKVector3 &rhs) {
  return GLKVector3Add(lhs, rhs);
}

/// Add two vectors.
GLK_INLINE GLKVector4 operator+(const GLKVector4 &lhs, const GLKVector4 &rhs) {
  return GLKVector4Add(lhs, rhs);
}

/// Subtract two vectors.
GLK_INLINE GLKVector2 operator-(const GLKVector2 &lhs, const GLKVector2 &rhs) {
  return GLKVector2Subtract(lhs, rhs);
}

/// Subtract two vectors.
GLK_INLINE GLKVector3 operator-(const GLKVector3 &lhs, const GLKVector3 &rhs) {
  return GLKVector3Subtract(lhs, rhs);
}

/// Subtract two vectors.
GLK_INLINE GLKVector4 operator-(const GLKVector4 &lhs, const GLKVector4 &rhs) {
  return GLKVector4Subtract(lhs, rhs);
}

/// Multiply a vector by a scalar value.
GLK_INLINE GLKVector2 operator*(const GLKVector2 &lhs, const float &rhs) {
  return GLKVector2MultiplyScalar(lhs, rhs);
}

/// Multiply a vector by a scalar value.
GLK_INLINE GLKVector2 operator*(const GLKVector2 &lhs, const double &rhs) {
  return GLKVector2MultiplyScalar(lhs, rhs);
}

/// Multiply a vector by a scalar value.
GLK_INLINE GLKVector2 operator*(const GLKVector2 &lhs, const int &rhs) {
  return GLKVector2MultiplyScalar(lhs, rhs);
}

/// Multiply a vector by a scalar value.
GLK_INLINE GLKVector3 operator*(const GLKVector3 &lhs, const float &rhs) {
  return GLKVector3MultiplyScalar(lhs, rhs);
}

/// Multiply a vector by a scalar value.
GLK_INLINE GLKVector3 operator*(const GLKVector3 &lhs, const double &rhs) {
  return GLKVector3MultiplyScalar(lhs, rhs);
}

/// Multiply a vector by a scalar value.
GLK_INLINE GLKVector3 operator*(const GLKVector3 &lhs, const int &rhs) {
  return GLKVector3MultiplyScalar(lhs, rhs);
}

/// Multiply a vector by a scalar value.
GLK_INLINE GLKVector4 operator*(const GLKVector4 &lhs, const float &rhs) {
  return GLKVector4MultiplyScalar(lhs, rhs);
}

GLK_INLINE GLKVector4 operator*(const GLKVector4 &lhs, const int &rhs) {
  return GLKVector4MultiplyScalar(lhs, rhs);
}

/// Multiply a vector by a scalar value.
GLK_INLINE GLKVector4 operator*(const GLKVector4 &lhs, const double &rhs) {
  return GLKVector4MultiplyScalar(lhs, rhs);
}

/// Multiply a vector by a scalar value.
GLK_INLINE GLKVector2 operator*(const float &lhs, const GLKVector2 &rhs) {
  return GLKVector2MultiplyScalar(rhs, lhs);
}

/// Multiply a vector by a scalar value.
GLK_INLINE GLKVector3 operator*(const float &lhs, const GLKVector3 &rhs) {
  return GLKVector3MultiplyScalar(rhs, lhs);
}

/// Multiply a vector by a scalar value.
GLK_INLINE GLKVector4 operator*(const float &lhs, const GLKVector4 &rhs) {
  return GLKVector4MultiplyScalar(rhs, lhs);
}

/// Returns the element-wise product of two vectors.
GLK_INLINE GLKVector2 operator*(const GLKVector2 &lhs, const GLKVector2 &rhs) {
  return GLKVector2Multiply(rhs, lhs);
}

/// Returns the element-wise product of two vectors.
GLK_INLINE GLKVector3 operator*(const GLKVector3 &lhs, const GLKVector3 &rhs) {
  return GLKVector3Multiply(rhs, lhs);
}

/// Returns the element-wise product of two vectors.
GLK_INLINE GLKVector4 operator*(const GLKVector4 &lhs, const GLKVector4 &rhs) {
  return GLKVector4Multiply(rhs, lhs);
}

/// Divide a vector by a scalar value (element wise).
GLK_INLINE GLKVector2 operator/(const GLKVector2 &lhs, const float &rhs) {
  return GLKVector2DivideScalar(lhs, rhs);
}

/// Divide a vector by a scalar value (element wise).
GLK_INLINE GLKVector2 operator/(const GLKVector2 &lhs, const double &rhs) {
  return GLKVector2DivideScalar(lhs, rhs);
}

/// Divide a vector by a scalar value (element wise).
GLK_INLINE GLKVector3 operator/(const GLKVector3 &lhs, const float &rhs) {
  return GLKVector3DivideScalar(lhs, rhs);
}

/// Divide a vector by a scalar value (element wise).
GLK_INLINE GLKVector3 operator/(const GLKVector3 &lhs, const double &rhs) {
  return GLKVector3DivideScalar(lhs, rhs);
}

/// Divide a vector by a scalar value (element wise).
GLK_INLINE GLKVector4 operator/(const GLKVector4 &lhs, const float &rhs)  {
  return GLKVector4DivideScalar(lhs, rhs);
}

/// Divide a vector by a scalar value (element wise).
GLK_INLINE GLKVector4 operator/(const GLKVector4 &lhs, const double &rhs)  {
  return GLKVector4DivideScalar(lhs, rhs);
}

/// Creates a \c GLKVector4 from a \c cv::Vec4b.
GLK_INLINE GLKVector4 GLKVector4FromVec4b(const cv::Vec4b &vec) {
  return GLKVector4Make(vec(0), vec(1), vec(2), vec(3)) / 255.0;
}

/// Creates a \c GLKVector2 from a \c CGPoint.
GLK_INLINE GLKVector2 GLKVector2FromCGPoint(const CGPoint &point) {
  return GLKVector2Make(point.x, point.y);
}

/// Returns a \c GLKVector2 that is perpendicular to the given \c GLKVector2.
/// The length of the returned vector is equal to the length of the source vector, and the direction
/// is a counter clockwise rotation (in bottom-left origin coordinate system).
GLK_INLINE GLKVector2 GLKVector2NormalTo(const GLKVector2 &vec) {
  return GLKVector2Make(vec.y, -vec.x);
}

/// Returns \c YES if every component of the vector is in [a, b] range.
GLK_INLINE BOOL GLKVector3InRange(const GLKVector3 &vec, const float a, const float b) {
  return (vec.x >= a && vec.y >= a && vec.z >= a && vec.x <= b && vec.y <= b && vec.z <= b);
}

/// Returns the coefficients of the standard line equation (Ax + By + C = 0) between the given
/// points, or a \c GLKVector3Zero in the degenerate case.
GLKVector3 GLKLineEquation(const GLKVector2 &source, const GLKVector2 &target);

/// Returns the coefficients of the standard line equation (Ax + By + C = 0) between the given
/// points, or a \c GLKVector3Zero in the degenerate case.
GLK_INLINE GLKVector3 GLKLineEquation(const CGPoint &source, const CGPoint &target) {
  return GLKLineEquation(GLKVector2FromCGPoint(source), GLKVector2FromCGPoint(target));
}

namespace std {
  /// Floors the given GLKVector2, coordinate-wise.
  GLK_INLINE GLKVector2 floor(const GLKVector2 &vector) {
    return GLKVector2Make(floor(vector.x), floor(vector.y));
  }
  
  /// Find a sum of the components.
  CG_INLINE float sum(const GLKVector3 &v) {
    return v.x + v.y + v.z;
  }
  
  /// Find a sum of the components.
  CG_INLINE float sum(const GLKVector4 &v) {
    return v.x + v.y + v.z + v.w;
  }
  
  /// Round the elements.
  CG_INLINE GLKVector2 round(const GLKVector2 &v) {
    return GLKVector2Make(round(v.x), round(v.y));
  }
  
  /// Round the elements.
  CG_INLINE GLKVector3 round(const GLKVector3 &v) {
    return GLKVector3Make(round(v.x), round(v.y), round(v.z));
  }
  
  /// Round the elements.
  CG_INLINE GLKVector4 round(const GLKVector4 &v) {
    return GLKVector4Make(round(v.x), round(v.y), round(v.z), round(v.w));
  }
  
  /// Element-wise minimum.
  GLK_INLINE GLKVector3 min(const GLKVector3 &lhs, const GLKVector3 &rhs) {
    return GLKVector3Make(min(lhs.x, rhs.x), min(lhs.y, rhs.y), min(lhs.z, rhs.z));
  }
  
  /// Element-wise maximum.
  GLK_INLINE GLKVector3 max(const GLKVector3 &lhs, const GLKVector3 &rhs) {
    return GLKVector3Make(max(lhs.x, rhs.x), max(lhs.y, rhs.y), max(lhs.z, rhs.z));
  }
  
  /// Element-wise minimum.
  GLK_INLINE GLKVector4 min(const GLKVector4 &lhs, const GLKVector4 &rhs) {
    return
        GLKVector4Make(min(lhs.x, rhs.x), min(lhs.y, rhs.y), min(lhs.z, rhs.z), min(lhs.w, rhs.w));
  }
  
  /// Element-wise maximum.
  GLK_INLINE GLKVector4 max(const GLKVector4 &lhs, const GLKVector4 &rhs) {
    return
        GLKVector4Make(max(lhs.x, rhs.x), max(lhs.y, rhs.y), max(lhs.z, rhs.z), max(lhs.w, rhs.w));
  }
}

/// Converts the given \c GLKVector4 from the RGB colorspace to the HSV colorspace.
GLKVector4 GLKRGBA2HSVA(const GLKVector4 &rgba);

/// Converts the given \c GLKVector3 from the RGB colorspace to the YIQ colorspace.
GLKVector3 GLKRGB2YIQ(const GLKVector3 &rgb);

#endif

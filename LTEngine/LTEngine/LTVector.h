// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <GLKit/GLKit.h>

#import "LTOpenCVCore.h"
#import "LTOpenCVHalfFloat.h"

#ifdef __cplusplus

#pragma mark -
#pragma mark LTVector2
#pragma mark -

struct LTVector2;

inline LTVector2 operator*(LTVector2 lhs, LTVector2 rhs);
inline LTVector2 operator/(LTVector2 lhs, CGFloat rhs);

/// Represents a 2 element vector.
struct LTVector2 {
  /// Initializes a new \c LTVector2 with two zero elements.
  LTVector2() : x(0), y(0) {}

  /// Initializes a new \c LTVector2 with \c x and \c y elements equal to the given scalar.
  explicit constexpr LTVector2(float scalar) : x(scalar), y(scalar) {}

  /// Initializes a new \c LTVector2 from \c GLKVector2.
  explicit constexpr LTVector2(GLKVector2 vector) : x(vector.x), y(vector.y) {}

  /// Initializes a new \c LTVector2 from \c CGPoint.
  explicit constexpr LTVector2(CGPoint point) : x(point.x), y(point.y) {}

  /// Initializes a new \c LTVector2 from \c CGSize.
  explicit constexpr LTVector2(CGSize size) : x(size.width), y(size.height) {}

  /// Initializes a new \c LTVector2 with \c x and \c y elements.
  constexpr LTVector2(float x, float y) : x(x), y(y) {}

  /// Cast operator to \c GLKVector2.
  explicit constexpr operator GLKVector2() const {
    return {.x = x, .y = y};
  }

  /// Cast operator to \c CGPoint.
  explicit constexpr operator CGPoint() const {
    return {.x = x, .y = y};
  }

  explicit constexpr operator CGSize() const {
    return {.width = x, .height = y};
  }

  /// Adds the given vector element wise to this vector.
  LTVector2 &operator+=(LTVector2 rhs) {
    x += rhs.x;
    y += rhs.y;
    return *this;
  }

  /// Adds each element of this vector ro the given \c rhs.
  LTVector2 &operator+=(float rhs) {
    x += rhs;
    y += rhs;
    return *this;
  }

  /// Subtracts the given vector element wise from this vector.
  LTVector2 &operator-=(LTVector2 rhs) {
    x -= rhs.x;
    y -= rhs.y;
    return *this;
  }

  /// Subtracts each element of this vector from the given \c rhs.
  LTVector2 &operator-=(float rhs) {
    x -= rhs;
    y -= rhs;
    return *this;
  }

  /// Multiplies the given vector element wise with this vector.
  LTVector2 &operator*=(LTVector2 rhs) {
    x *= rhs.x;
    y *= rhs.y;
    return *this;
  }

  /// Multiplies each element of this vector with the given \c rhs.
  LTVector2 &operator*=(float rhs) {
    x *= rhs;
    y *= rhs;
    return *this;
  }

  /// Divides the given vector element wise with this vector.
  LTVector2 &operator/=(LTVector2 rhs) {
    x /= rhs.x;
    y /= rhs.y;
    return *this;
  }

  /// Divides each element of this vector with the given \c rhs.
  LTVector2 &operator/=(float rhs) {
    x /= rhs;
    y /= rhs;
    return *this;
  }

  /// Returns YES if the vector is \c LTVector2:null().
  inline bool isNull() const {
    return isnan(x) && isnan(y);
  }

  /// Returns the red component (first element).
  inline float &r() {
    return x;
  }

  /// Returns the red component (first element).
  constexpr float r() const {
    return x;
  }

  /// Returns the green component (second element).
  inline float &g() {
    return y;
  }

  /// Returns the red component (first element).
  constexpr float g() const {
    return y;
  }

  /// Returns the sum of the components.
  constexpr float sum() const {
    return x + y;
  }

  /// Returns the length of this vector.
  inline float length() const {
    return std::sqrt(x * x + y * y);
  }

  /// Returns the dot product between this vector and the given \c vector.
  inline float dot(LTVector2 vector) const {
    return (*this * vector).sum();
  }

  /// Returns the determinant of this vector and the given \c vector.
  inline float determinant(LTVector2 vector) const {
    return x * vector.y - y * vector.x;
  }

  /// Returns the counter-clockwise angle (in bottom-left origin coordinate system) between this
  /// vector and the given \c vector. The result is guaranteed to be in the range [0, 2 * PI).
  inline CGFloat angle(LTVector2 vector) const {
    return CGNormalizedAngle(std::atan2(determinant(vector), dot(vector)));
  }

  /// Returns a new vector which is a normalized copy of this vector.
  inline LTVector2 normalized() const {
    return *this / length();
  }

  /// Returns a new vector that is perpendicular to the given \c vector.
  /// The length of the returned vector is equal to the length of the given \c vector.
  /// If \c clockwise is set to \c YES, its direction reflects a clockwise rotation (in bottom-left
  /// origin coordinate system), otherwise it reflects a counter-clockwise one. By default
  /// \c clockwise is set to \c YES.
  inline LTVector2 perpendicular(BOOL clockwise = YES) const {
    return clockwise ? LTVector2(y, -x) : LTVector2(-y, x);
  }

  /// Returns pointer to the first element of the vector.
  inline float *data() {
    return reinterpret_cast<float *>(this);
  }

  /// Returns pointer to the first element of the vector.
  inline const float *data() const {
    return reinterpret_cast<const float *>(this);
  }

  /// Returns a vector where each entry is \c 0.
  constexpr static LTVector2 zeros() {
    return LTVector2(0);
  }

  /// Returns a vector where each entry is \c 1.
  constexpr static LTVector2 ones() {
    return LTVector2(1);
  }

  /// Returns a vector where each entry is NaN.
  constexpr static LTVector2 null() {
    return LTVector2(NAN);
  }

  /// Returns a unit vector in the direction specified by the given \c angle.
  inline static LTVector2 angle(float angle) {
    return LTVector2(std::cosf(angle), std::sinf(angle));
  }

  float x;
  float y;
};

constexpr bool operator==(LTVector2 lhs, LTVector2 rhs) {
  return lhs.x == rhs.x && lhs.y == rhs.y;
}

constexpr bool operator!=(LTVector2 lhs, LTVector2 rhs) {
  return !(lhs == rhs);
}

constexpr LTVector2 operator-(LTVector2 vector) {
  return LTVector2(-vector.x, -vector.y);
}

inline LTVector2 operator+(LTVector2 lhs, LTVector2 rhs) {
  lhs += rhs;
  return lhs;
}

inline LTVector2 operator-(LTVector2 lhs, LTVector2 rhs) {
  lhs -= rhs;
  return lhs;
}

inline LTVector2 operator*(LTVector2 lhs, LTVector2 rhs) {
  lhs *= rhs;
  return lhs;
}

inline LTVector2 operator*(LTVector2 lhs, CGFloat rhs) {
  lhs *= rhs;
  return lhs;
}

inline LTVector2 operator*(CGFloat lhs, LTVector2 rhs) {
  rhs *= lhs;
  return rhs;
}

inline LTVector2 operator/(LTVector2 lhs, LTVector2 rhs) {
  lhs /= rhs;
  return lhs;
}

inline LTVector2 operator/(LTVector2 lhs, CGFloat rhs) {
  lhs /= rhs;
  return lhs;
}

inline LTVector2 operator/(CGFloat lhs, LTVector2 rhs) {
  return LTVector2(lhs) / rhs;
}

namespace std {
  /// Constrains point elements to lie between two points elements.
  inline LTVector2 clamp(LTVector2 point, LTVector2 a, LTVector2 b) {
    return LTVector2(clamp(point.x, a.x, b.x), clamp(point.y, a.y, b.y));
  }

  /// Constrains point elements to lie between two scalars.
  inline LTVector2 clamp(LTVector2 point, float a, float b) {
    return clamp(point, LTVector2(a), LTVector2(b));
  }

  /// Constrains point to lie inside the given rect.
  inline LTVector2 clamp(LTVector2 point, CGRect rect) {
    return LTVector2(clamp(point.x, rect.origin.x, rect.origin.x + rect.size.width),
                     clamp(point.y, rect.origin.y, rect.origin.y + rect.size.height));
  }

  /// Round the elements.
  inline LTVector2 round(LTVector2 v) {
    return LTVector2(round(v.x), round(v.y));
  }

  /// Returns element-wise minimal vector.
  inline LTVector2 min(LTVector2 a, LTVector2 b) {
    return LTVector2(min(a.x, b.x), min(a.y, b.y));
  }

  /// Returns the minimal element of the vector.
  inline float min(LTVector2 a) {
    return min(a.x, a.y);
  }

  /// Return element-wise maximal vector.
  inline LTVector2 max(LTVector2 a, LTVector2 b) {
    return LTVector2(max(a.x, b.x), max(a.y, b.y));
  }

  /// Returns the maximal element of the vector.
  inline float max(LTVector2 a) {
    return max(a.x, a.y);
  }

  /// Returns the absolute value of each element of the vector.
  inline LTVector2 abs(LTVector2 v) {
    return LTVector2(abs(v.x), abs(v.y));
  }

  /// Returns the square root of each element of the vector.
  inline LTVector2 sqrt(LTVector2 v) {
    return LTVector2(sqrt(v.x), sqrt(v.y));
  }

  /// Returns the raised to the power value of each element of the vector.
  inline LTVector2 pow(LTVector2 base, CGFloat power) {
    return LTVector2(pow(base.x, power), pow(base.y, power));
  }

  /// Returns element-wise raised to the power vector.
  inline LTVector2 pow(LTVector2 base, LTVector2 power) {
    return LTVector2(pow(base.x, power.x), pow(base.y, power.y));
  }

  /// Returns a linear interpolation between two values using a scalar.
  inline LTVector2 mix(LTVector2 a, LTVector2 b, float alpha) {
    return (1 - alpha) * a + alpha * b;
  }

  /// Returns a linear interpolation between two values using an element wise interpolation vector.
  inline LTVector2 mix(LTVector2 a, LTVector2 b, LTVector2 alpha) {
    return (LTVector2::ones() - alpha) * a + alpha * b;
  }

  /// Returns a vector with the result of an element wise comparison between a given vector to an
  /// edge vector. For element \c i of the return value, \c 0 is returned if <tt>v[i] < edge[i]</tt>
  /// and \c 1 is returned otherwise.
  inline LTVector2 step(LTVector2 edge, LTVector2 v) {
    return LTVector2(v.x >= edge.x, v.y >= edge.y);
  }

  /// Returns a vector with the result of an element wise comparison between a given vector to an
  /// edge scalar. For element \c i of the return value, \c 0 is returned if <tt>v[i] < edge</tt>
  /// and \c 1 is returned otherwise.
  inline LTVector2 step(float edge, LTVector2 v) {
    return step(LTVector2(edge), v);
  }
}

/// Returns an \c NSString representation of the given \c vector. The returned \c NSString is
/// <tt>@"(x, y)"</tt>, where \c x and \c y are the string representations of \c vector.x and
/// \c vector.y, respectively.
NSString *NSStringFromLTVector2(LTVector2 vector);

/// Returns a vector from its string representation. The representation should be in the format
/// \c @"(%g, %g), where %g can also be nan/inf/-inf". In case an invalid format is given, an
/// \c LTVector2 that is set to all zeros will be returned.
LTVector2 LTVector2FromString(NSString *string);

#pragma mark -
#pragma mark LTVector3
#pragma mark -

struct LTVector3;

inline LTVector3 operator*(LTVector3 lhs, LTVector3 rhs);
inline LTVector3 operator/(LTVector3 lhs, CGFloat rhs);

/// Represents a 3 element vector.
struct LTVector3 {
  /// Initializes a new \c LTVector3 with three zero elements.
  constexpr LTVector3() : x(0), y(0), z(0) {}

  /// Initializes a new \c LTVector3 with \c x, y and \c z elements equal to the given scalar.
  explicit constexpr LTVector3(float scalar) : x(scalar), y(scalar), z(scalar) {}

  /// Initializes a new \c LTVector3 from \c GLKVector3.
  explicit constexpr LTVector3(GLKVector3 vector) : x(vector.x), y(vector.y), z(vector.z) {}

  /// Initializes a new \c LTVector3 with \c x,\c y and \c z elements.
  constexpr LTVector3(float x, float y, float z) : x(x), y(y), z(z) {}

  /// Cast operator to \c GLKVector3.
  explicit operator GLKVector3() const {
    return GLKVector3Make(x, y, z);
  }

  /// Cast operator to \c cv::Vec3b, mapping range \c [0,1] to \c [0,255].
  explicit operator cv::Vec3b() const {
    return cv::Vec3b(std::round(x * UCHAR_MAX), std::round(y * UCHAR_MAX),
                     std::round(z * UCHAR_MAX));
  }

  /// Cast operator to \c cv::Vec3f.
  explicit operator cv::Vec3f() const {
    return cv::Vec3f(x, y, z);
  }

  /// Adds the given vector element wise to this vector.
  LTVector3 &operator+=(LTVector3 rhs) {
    x += rhs.x;
    y += rhs.y;
    z += rhs.z;
    return *this;
  }

  /// Adds each element of this vector ro the given \c rhs.
  LTVector3 &operator+=(float rhs) {
    x += rhs;
    y += rhs;
    z += rhs;
    return *this;
  }

  /// Subtracts the given vector element wise from this vector.
  LTVector3 &operator-=(LTVector3 rhs) {
    x -= rhs.x;
    y -= rhs.y;
    z -= rhs.z;
    return *this;
  }

  /// Subtracts each element of this vector from the given \c rhs.
  LTVector3 &operator-=(float rhs) {
    x -= rhs;
    y -= rhs;
    z -= rhs;
    return *this;
  }

  /// Multiplies the given vector element wise with this vector.
  LTVector3 &operator*=(LTVector3 rhs) {
    x *= rhs.x;
    y *= rhs.y;
    z *= rhs.z;
    return *this;
  }

  /// Multiplies each element of this vector with the given \c rhs.
  LTVector3 &operator*=(float rhs) {
    x *= rhs;
    y *= rhs;
    z *= rhs;
    return *this;
  }

  /// Divides the given vector element wise with this vector.
  LTVector3 &operator/=(LTVector3 rhs) {
    x /= rhs.x;
    y /= rhs.y;
    z /= rhs.z;
    return *this;
  }

  /// Divides each element of this vector with the given \c rhs.
  LTVector3 &operator/=(float rhs) {
    x /= rhs;
    y /= rhs;
    z /= rhs;
    return *this;
  }

  /// Returns YES if the vector is LTVector3::null().
  inline bool isNull() const {
    return isnan(x) && isnan(y) && isnan(z);
  }

  /// Returns the red component (first element).
  inline float &r() {
    return x;
  }

  /// Returns the red component (first element).
  constexpr float r() const {
    return x;
  }

  /// Returns the green component (second element).
  inline float &g() {
    return y;
  }

  /// Returns the red component (first element).
  constexpr float g() const {
    return y;
  }

  /// Returns the blue component (third element).
  inline float &b() {
    return z;
  }

  /// Returns the red component (first element).
  constexpr float b() const {
    return z;
  }

  /// Returns the sum of the components.
  constexpr float sum() const {
    return x + y + z;
  }

  /// Returns the length of this vector.
  inline float length() const {
    return std::sqrt(x * x + y * y + z * z);
  }

  /// Returns the dot product between this vector and the given \c vector.
  inline float dot(LTVector3 vector) const {
    return (*this * vector).sum();
  }

  /// Returns a new vector which is a normalized copy of this vector.
  inline LTVector3 normalized() const {
    return *this / length();
  }

  /// Returns pointer to the first element of the vector.
  inline float *data() {
    return reinterpret_cast<float *>(this);
  }

  /// Returns pointer to the first element of the vector.
  inline const float *data() const {
    return reinterpret_cast<const float *>(this);
  }

  /// Returns a vector where each entry is \c 0.
  constexpr static LTVector3 zeros() {
    return LTVector3(0);
  }

  /// Returns a vector where each entry is \c 1.
  constexpr static LTVector3 ones() {
    return LTVector3(1);
  }

  /// Returns a vector where each entry is \c NaN.
  constexpr static LTVector3 null() {
    return LTVector3(NAN);
  }

  /// Converts from RGB to HSV color space.
  LTVector3 rgbToHsv() const;

  /// Converts from HSV to RGB color space.
  LTVector3 hsvToRgb() const;

  float x;
  float y;
  float z;
};

constexpr bool operator==(LTVector3 lhs, LTVector3 rhs) {
  return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z;
}

constexpr bool operator!=(LTVector3 lhs, LTVector3 rhs) {
  return !(lhs == rhs);
}

constexpr LTVector3 operator-(LTVector3 vector) {
  return LTVector3(-vector.x, -vector.y, -vector.z);
}

inline LTVector3 operator+(LTVector3 lhs, LTVector3 rhs) {
  lhs += rhs;
  return lhs;
}

inline LTVector3 operator-(LTVector3 lhs, LTVector3 rhs) {
  lhs -= rhs;
  return lhs;
}

inline LTVector3 operator*(LTVector3 lhs, LTVector3 rhs) {
  lhs *= rhs;
  return lhs;
}

inline LTVector3 operator*(LTVector3 lhs, CGFloat rhs) {
  lhs *= rhs;
  return lhs;
}

inline LTVector3 operator*(CGFloat lhs, LTVector3 rhs) {
  rhs *= lhs;
  return rhs;
}

inline LTVector3 operator/(LTVector3 lhs, LTVector3 rhs) {
  lhs /= rhs;
  return lhs;
}

inline LTVector3 operator/(LTVector3 lhs, CGFloat rhs) {
  lhs /= rhs;
  return lhs;
}

inline LTVector3 operator/(CGFloat lhs, LTVector3 rhs) {
  return LTVector3(lhs) / rhs;
}

namespace std {
  /// Round the elements.
  inline LTVector3 round(LTVector3 v) {
    return LTVector3(round(v.x), round(v.y), round(v.z));
  }

  /// Return element-wise minimal vector.
  inline LTVector3 min(LTVector3 a, LTVector3 b) {
    return LTVector3(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z));
  }

  /// Returns the minimal element of the vector.
  inline float min(LTVector3 a) {
    return min(min(a.x, a.y), a.z);
  }

  /// Return element-wise maximal vector.
  inline LTVector3 max(LTVector3 a, LTVector3 b) {
    return LTVector3(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z));
  }

  /// Returns the maximal element of the vector.
  inline float max(LTVector3 a) {
    return max(max(a.x, a.y), a.z);
  }

  /// Returns the absolute value of each element of the vector.
  inline LTVector3 abs(LTVector3 v) {
    return LTVector3(abs(v.x), abs(v.y), abs(v.z));
  }

  /// Returns the square root of each element of the vector.
  inline LTVector3 sqrt(LTVector3 v) {
    return LTVector3(sqrt(v.x), sqrt(v.y), sqrt(v.z));
  }

  /// Returns the raised to the power value of each element of the vector.
  inline LTVector3 pow(LTVector3 base, CGFloat power) {
    return LTVector3(pow(base.x, power), pow(base.y, power), pow(base.z, power));
  }

  /// Returns element-wise raised to the power vector.
  inline LTVector3 pow(LTVector3 base, LTVector3 power) {
    return LTVector3(pow(base.x, power.x), pow(base.y, power.y), pow(base.z, power.z));
  }

  /// Constrains vector elements to lie between two vectors elements.
  inline LTVector3 clamp(LTVector3 point, LTVector3 a, LTVector3 b) {
    return LTVector3(clamp(point.x, a.x, b.x), clamp(point.y, a.y, b.y), clamp(point.z, a.z, b.z));
  }

  /// Constrains vector elements to lie between two scalars.
  inline LTVector3 clamp(LTVector3 v, float a, float b) {
    return clamp(v, LTVector3(a), LTVector3(b));
  }

  /// Returns a linear interpolation between two values using a scalar.
  inline LTVector3 mix(LTVector3 a, LTVector3 b, float alpha) {
    return (1 - alpha) * a + alpha * b;
  }

  /// Returns a linear interpolation between two values using an element wise interpolation vector.
  inline LTVector3 mix(LTVector3 a, LTVector3 b, LTVector3 alpha) {
    return (LTVector3::ones() - alpha) * a + alpha * b;
  }

  /// Returns a vector with the result of an element wise comparison between a given vector to an
  /// edge vector. For element \c i of the return value, \c 0 is returned if <tt>v[i] < edge[i]</tt>
  /// and \c 1 is returned otherwise.
  inline LTVector3 step(LTVector3 edge, LTVector3 v) {
    return LTVector3(v.x >= edge.x, v.y >= edge.y, v.z >= edge.z);
  }

  /// Returns a vector with the result of an element wise comparison between a given vector to an
  /// edge scalar. For element \c i of the return value, \c 0 is returned if <tt>v[i] < edge</tt>
  /// and \c 1 is returned otherwise.
  inline LTVector3 step(float edge, LTVector3 v) {
    return step(LTVector3(edge), v);
  }
}

/// Returns an \c NSString representation of the given \c vector. The returned \c NSString is
/// <tt>@"(x, y, z)"</tt>, where \c x, \c y, and \c z are the string representations of \c vector.x,
/// \c vector.y, and \c vector.z, respectively.
NSString *NSStringFromLTVector3(LTVector3 vector);

/// Returns a vector from its string representation. The representation should be in the format
/// \c @"(%g, %g, %g), where %g can also be nan/inf/-inf". In case an invalid format is given, an
/// \c LTVector3 that is set to all zeros will be returned.
LTVector3 LTVector3FromString(NSString *string);

#pragma mark -
#pragma mark LTVector4
#pragma mark -

struct LTVector4;

inline LTVector4 operator*(LTVector4 lhs, LTVector4 rhs);
inline LTVector4 operator/(LTVector4 lhs, CGFloat rhs);

/// Represents a 4 element vector.
struct LTVector4 {
  /// Initializes a new \c LTVector4 with two zero elements.
  constexpr LTVector4() : x(0), y(0), z(0), w(0) {}

  /// Initializes a new \c LTVector4 with \c x, y, z and \c w elements equal to the given scalar.
  explicit constexpr LTVector4(float scalar) : x(scalar), y(scalar), z(scalar), w(scalar) {}

  /// Initializes a new \c LTVector4 with the given \c rgb vector and \c alpha.
  explicit constexpr LTVector4(LTVector3 rgb, float a) : x(rgb.x), y(rgb.y), z(rgb.z), w(a) {}

  /// Initializes a new \c LTVector4 from \c GLKVector4.
  explicit constexpr LTVector4(GLKVector4 vector) : x(vector.x), y(vector.y), z(vector.z),
      w(vector.w) {}

  /// Initializes a new \c LTVector4 from \c cv::Vec4b, normalized to values in \c [0,1].
  explicit LTVector4(cv::Vec4b vector) : x(vector[0]), y(vector[1]), z(vector[2]), w(vector[3]) {
    *this /= UCHAR_MAX;
  }

  /// Initializes a new \c LTVector4 from \c cv::Vec4f.
  explicit LTVector4(cv::Vec4f vector) : x(vector[0]), y(vector[1]), z(vector[2]), w(vector[3]) {}

  /// Initializes a new \c LTVector4 from \c cv::Vec4hf.
  explicit LTVector4(cv::Vec4hf vector) : x(vector[0]), y(vector[1]), z(vector[2]), w(vector[3]) {}

  /// Cast operator to \c GLKVector4.
  explicit constexpr operator GLKVector4() const {
    return {.x = x, .y = y, .z = z, .w = w};
  }

  /// Cast operator to \c cv::Vec4b, mapping range \c [0,1] to \c [0,255].
  explicit operator cv::Vec4b() const {
    return cv::Vec4b(std::round(x * UCHAR_MAX), std::round(y * UCHAR_MAX),
                     std::round(z * UCHAR_MAX), std::round(w * UCHAR_MAX));
  }

  /// Cast operator to \c cv::Vec4f.
  explicit operator cv::Vec4f() const {
    return cv::Vec4f(x, y, z, w);
  }

  /// Cast operator to \c cv::Vec4hf.
  explicit operator cv::Vec4hf() const {
    return cv::Vec4f(half_float::half(x), half_float::half(y), half_float::half(z),
                     half_float::half(w));
  }

  /// Initializes a new \c LTVector4 with \c x, \c y, \c z, and w elements.
  constexpr LTVector4(float x, float y, float z, float w) : x(x), y(y), z(z), w(w) {}

  /// Adds the given vector element wise to this vector.
  LTVector4 &operator+=(LTVector4 rhs) {
    x += rhs.x;
    y += rhs.y;
    z += rhs.z;
    w += rhs.w;
    return *this;
  }

  /// Adds each element of this vector ro the given \c rhs.
  LTVector4 &operator+=(float rhs) {
    x += rhs;
    y += rhs;
    z += rhs;
    w += rhs;
    return *this;
  }

  /// Subtracts the given vector element wise from this vector.
  LTVector4 &operator-=(LTVector4 rhs) {
    x -= rhs.x;
    y -= rhs.y;
    z -= rhs.z;
    w -= rhs.w;
    return *this;
  }

  /// Subtracts each element of this vector from the given \c rhs.
  LTVector4 &operator-=(float rhs) {
    x -= rhs;
    y -= rhs;
    z -= rhs;
    w -= rhs;
    return *this;
  }

  /// Multiplies the given vector element wise with this vector.
  LTVector4 &operator*=(LTVector4 rhs) {
    x *= rhs.x;
    y *= rhs.y;
    z *= rhs.z;
    w *= rhs.w;
    return *this;
  }

  /// Multiplies each element of this vector with the given \c rhs.
  LTVector4 &operator*=(float rhs) {
    x *= rhs;
    y *= rhs;
    z *= rhs;
    w *= rhs;
    return *this;
  }

  /// Divides the given vector element wise with this vector.
  LTVector4 &operator/=(LTVector4 rhs) {
    x /= rhs.x;
    y /= rhs.y;
    z /= rhs.z;
    w /= rhs.w;
    return *this;
  }

  /// Divides each element of this vector with the given \c rhs.
  LTVector4 &operator/=(float rhs) {
    x /= rhs;
    y /= rhs;
    z /= rhs;
    w /= rhs;
    return *this;
  }

  /// Returns YES if the vector is \c LTVector4::null().
  inline bool isNull() const {
    return isnan(x) && isnan(y) && isnan(z) && isnan(w);
  }

  /// Returns the red component (first element).
  inline float &r() {
    return x;
  }

  /// Returns the red component (first element).
  constexpr float r() const {
    return x;
  }

  /// Returns the green component (second element).
  inline float &g() {
    return y;
  }

  /// Returns the red component (first element).
  constexpr float g() const {
    return y;
  }

  /// Returns the blue component (third element).
  inline float &b() {
    return z;
  }

  /// Returns the red component (first element).
  constexpr float b() const {
    return z;
  }

  /// Returns the alpha component (fourth element).
  inline float &a() {
    return w;
  }

  /// Returns the red component (first element).
  constexpr float a() const {
    return w;
  }

  /// Returns the rgb components (first three elements).
  constexpr LTVector3 rgb() const {
    return LTVector3(x, y, z);
  }

  /// Returns a copy of this vector in which its red component (first element) and blue component
  /// (third element) are replaced.
  constexpr LTVector4 bgra() const {
    return LTVector4(z, y, x, w);
  }

  /// Returns the sum of the components.
  constexpr float sum() const {
    return x + y + w + z;
  }

  /// Returns the length of this vector.
  inline float length() const {
    return std::sqrt(x * x + y * y + z * z + w * w);
  }

  /// Returns the dot product between this vector and the given \c vector.
  inline float dot(LTVector4 vector) const {
    return (*this * vector).sum();
  }

  /// Returns a new vector which is a normalized copy of this vector.
  inline LTVector4 normalized() const {
    return *this / length();
  }

  /// Returns pointer to the first element of the vector.
  inline float *data() {
    return reinterpret_cast<float *>(this);
  }

  /// Returns pointer to the first element of the vector.
  inline const float *data() const {
    return reinterpret_cast<const float *>(this);
  }

  /// Returns a vector where each entry is \c 0.
  constexpr static LTVector4 zeros() {
    return LTVector4(0);
  }

  /// Returns a vector where each entry is \c 1.
  constexpr static LTVector4 ones() {
    return LTVector4(1);
  }

  /// Returns a vector where each entry is \c NaN.
  constexpr static LTVector4 null() {
    return LTVector4(NAN);
  }

  /// Converts from RGB to HSV color space, leaving last coordinate unchanged.
  LTVector4 rgbToHsv() const;

  /// Converts from HSV to RGB color space, leaving last coordinate unchanged.
  LTVector4 hsvToRgb() const;

  float x;
  float y;
  float z;
  float w;
};

constexpr bool operator==(LTVector4 lhs, LTVector4 rhs) {
  return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w;
}

constexpr bool operator!=(LTVector4 lhs, LTVector4 rhs) {
  return !(lhs == rhs);
}

constexpr LTVector4 operator-(LTVector4 vector) {
  return LTVector4(-vector.x, -vector.y, -vector.z, -vector.w);
}

inline LTVector4 operator+(LTVector4 lhs, LTVector4 rhs) {
  lhs += rhs;
  return lhs;
}

inline LTVector4 operator+(LTVector4 lhs, CGFloat rhs) {
  lhs += rhs;
  return lhs;
}

inline LTVector4 operator-(LTVector4 lhs, LTVector4 rhs) {
  lhs -= rhs;
  return lhs;
}

inline LTVector4 operator*(LTVector4 lhs, LTVector4 rhs) {
  lhs *= rhs;
  return lhs;
}

inline LTVector4 operator*(LTVector4 lhs, CGFloat rhs) {
  lhs *= rhs;
  return lhs;
}

inline LTVector4 operator*(CGFloat lhs, LTVector4 rhs) {
  rhs *= lhs;
  return rhs;
}

inline LTVector4 operator/(LTVector4 lhs, LTVector4 rhs) {
  lhs /= rhs;
  return lhs;
}

inline LTVector4 operator/(LTVector4 lhs, CGFloat rhs) {
  lhs /= rhs;
  return lhs;
}

inline LTVector4 operator/(CGFloat lhs, LTVector4 rhs) {
  return LTVector4(lhs) / rhs;
}

namespace std {
  /// Round the elements.
  inline LTVector4 round(LTVector4 v) {
    return LTVector4(round(v.x), round(v.y), round(v.z), round(v.w));
  }

  /// Return element-wise minimal vector.
  inline LTVector4 min(LTVector4 a, LTVector4 b) {
    return LTVector4(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z), min(a.w, b.w));
  }

  /// Returns the minimal element of the vector.
  inline float min(LTVector4 a) {
    return min(min(min(a.x, a.y), a.z), a.w);
  }

  /// Return element-wise maximal vector.
  inline LTVector4 max(LTVector4 a, LTVector4 b) {
    return LTVector4(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z), max(a.w, b.w));
  }

  /// Returns the maximal element of the vector.
  inline float max(LTVector4 a) {
    return max(max(max(a.x, a.y), a.z), a.w);
  }

  /// Returns the absolute value of each element of the vector.
  inline LTVector4 abs(LTVector4 v) {
    return LTVector4(abs(v.x), abs(v.y), abs(v.z), abs(v.w));
  }

  /// Returns the square root of each element of the vector.
  inline LTVector4 sqrt(LTVector4 v) {
    return LTVector4(sqrt(v.x), sqrt(v.y), sqrt(v.z), sqrt(v.w));
  }

  /// Returns the raised to the power value of each element of the vector.
  inline LTVector4 pow(LTVector4 base, CGFloat power) {
    return LTVector4(pow(base.x, power), pow(base.y, power), pow(base.z, power),
                     pow(base.w, power));
  }

  /// Returns element-wise raised to the power vector.
  inline LTVector4 pow(LTVector4 base, LTVector4 power) {
    return LTVector4(pow(base.x, power.x), pow(base.y, power.y), pow(base.z, power.z),
                     pow(base.w, power.w));
  }

  /// Constrains vector elements to lie between two vectors elements.
  inline LTVector4 clamp(LTVector4 point, LTVector4 a, LTVector4 b) {
    return LTVector4(clamp(point.x, a.x, b.x), clamp(point.y, a.y, b.y), clamp(point.z, a.z, b.z),
                     clamp(point.w, a.w, b.w));
  }

  /// Constrains vector elements to lie between two scalars.
  inline LTVector4 clamp(LTVector4 v, float a, float b) {
    return clamp(v, LTVector4(a), LTVector4(b));
  }

  /// Returns a linear interpolation between two values using a scalar.
  inline LTVector4 mix(LTVector4 a, LTVector4 b, float alpha) {
    return (1 - alpha) * a + alpha * b;
  }

  /// Returns a linear interpolation between two values using an element wise interpolation vector.
  inline LTVector4 mix(LTVector4 a, LTVector4 b, LTVector4 alpha) {
    return (LTVector4::ones() - alpha) * a + alpha * b;
  }

  /// Returns a vector with the result of an element wise comparison between a given vector to an
  /// edge vector. For element \c i of the return value, \c 0 is returned if <tt>v[i] < edge[i]</tt>
  /// and \c 1 is returned otherwise.
  inline LTVector4 step(LTVector4 edge, LTVector4 v) {
    return LTVector4(v.x >= edge.x, v.y >= edge.y, v.z >= edge.z, v.w >= edge.w);
  }

  /// Returns a vector with the result of an element wise comparison between a given vector to an
  /// edge scalar. For element \c i of the return value, \c 0 is returned if <tt>v[i] < edge</tt>
  /// and \c 1 is returned otherwise.
  inline LTVector4 step(float edge, LTVector4 v) {
    return step(LTVector4(edge), v);
  }
}

namespace lt::detail {

template<>
struct RangeValidator<LTVector2> {
  bool operator()(const LTVector2 &value, const LTVector2 &low, const LTVector2 &high) {
    return low.x <= value.x && low.y <= value.y && value.x <= high.x && value.y <= high.y;
  }
};

template<>
struct RangeValidator<LTVector3> {
  bool operator()(const LTVector3 &value, const LTVector3 &low, const LTVector3 &high) {
    return low.x <= value.x && low.y <= value.y && low.z <= value.z &&
        value.x <= high.x && value.y <= high.y && value.z <= high.z;
  }
};

template<>
struct RangeValidator<LTVector4> {
  bool operator()(const LTVector4 &value, const LTVector4 &low, const LTVector4 &high) {
    return low.x <= value.x && low.y <= value.y && low.z <= value.z && low.w <= value.w &&
        value.x <= high.x && value.y <= high.y && value.z <= high.z && value.w <= high.w;
  }
};

} // namespace lt::detail

/// Returns an \c NSString representation of the given \c vector. The returned \c NSString is
/// <tt>@"(x, y, z, w)"</tt>, where \c x, \c y, \c z, and \c w are the string representations of
/// \c vector.x, \c vector.y, \c vector.z, and \c vector.w, respectively.
NSString *NSStringFromLTVector4(LTVector4 vector);

/// Returns a vector from its string representation. The representation should be in the format
/// \c @"(%g, %g, %g, %g), where %g can also be nan/inf/-inf". In case an invalid format is given,
/// an \c LTVector4 that is set to all zeros will be returned.
LTVector4 LTVector4FromString(NSString *string);

#endif

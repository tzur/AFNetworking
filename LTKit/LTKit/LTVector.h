// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <GLKit/GLKit.h>

#pragma mark -
#pragma mark LTVector2
#pragma mark -

struct LTVector2;

inline LTVector2 operator*(LTVector2 lhs, const LTVector2 &rhs);
inline LTVector2 operator/(LTVector2 lhs, const CGFloat rhs);

/// Represents a 2 element vector.
struct LTVector2 {
  /// Initializes a new \c LTVector2 with two zero elements.
  LTVector2() : x(0), y(0) {}

  /// Initializes a new \c LTVector2 with \c x and \c y elements equal to the given scalar.
  explicit LTVector2(float scalar) : x(scalar), y(scalar) {}

  /// Initializes a new \c LTVector2 from \c GLKVector2.
  explicit LTVector2(GLKVector2 vector) : x(vector.x), y(vector.y) {}

  /// Initializes a new \c LTVector2 from \c CGPoint.
  explicit LTVector2(CGPoint point) : x(point.x), y(point.y) {}

  /// Initializes a new \c LTVector2 from \c CGSize.
  explicit LTVector2(CGSize size) : x(size.width), y(size.height) {}

  /// Initializes a new \c LTVector2 with \c x and \c y elements.
  LTVector2(float x, float y) : x(x), y(y) {}

  /// Cast operator to \c GLKVector2.
  explicit operator GLKVector2() const {
    return GLKVector2Make(x, y);
  }

  /// Cast operator to \c CGPoint.
  explicit operator CGPoint() const {
    return CGPointMake(x, y);
  }
  
  explicit operator CGSize() const {
    return CGSizeMake(x, y);
  }

  /// Adds the given vector element wise to this vector.
  LTVector2 &operator+=(const LTVector2 &rhs) {
    x += rhs.x;
    y += rhs.y;
    return *this;
  }

  /// Adds each element of this vector ro the given \c rhs.
  LTVector2 &operator+=(const float &rhs) {
    x += rhs;
    y += rhs;
    return *this;
  }

  /// Subtracts the given vector element wise from this vector.
  LTVector2 &operator-=(const LTVector2 &rhs) {
    x -= rhs.x;
    y -= rhs.y;
    return *this;
  }

  /// Subtracts each element of this vector from the given \c rhs.
  LTVector2 &operator-=(const float &rhs) {
    x -= rhs;
    y -= rhs;
    return *this;
  }

  /// Multiplies the given vector element wise with this vector.
  LTVector2 &operator*=(const LTVector2 &rhs) {
    x *= rhs.x;
    y *= rhs.y;
    return *this;
  }
  
  /// Multiplies each element of this vector with the given \c rhs.
  LTVector2 &operator*=(const float rhs) {
    x *= rhs;
    y *= rhs;
    return *this;
  }

  /// Divides the given vector element wise with this vector.
  LTVector2 &operator/=(const LTVector2 &rhs) {
    x /= rhs.x;
    y /= rhs.y;
    return *this;
  }
  
  /// Divides each element of this vector with the given \c rhs.
  LTVector2 &operator/=(const float rhs) {
    x /= rhs;
    y /= rhs;
    return *this;
  }

  /// Returns the red component (first element).
  inline float &r() {
    return x;
  }

  /// Returns the red component (first element).
  inline float r() const {
    return x;
  }

  /// Returns the green component (second element).
  inline float &g() {
    return y;
  }

  /// Returns the red component (first element).
  inline float g() const {
    return y;
  }

  /// Returns the sum of the components.
  inline float sum() const {
    return x + y;
  }

  /// Returns the length of this vector.
  inline float length() const {
    return std::sqrt(x * x + y * y);
  }

  /// Returns the dot product between this vector and the given \c vector.
  inline float dot(const LTVector2 &vector) const {
    return (*this * vector).sum();
  }

  /// Returns a new vector which is a normalized copy of this vector.
  inline LTVector2 normalized() const {
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

  float x;
  float y;
};

inline bool operator==(LTVector2 lhs, LTVector2 rhs) {
  return lhs.x == rhs.x && lhs.y == rhs.y;
}

inline bool operator>=(const LTVector2 &lhs, const LTVector2 &rhs) {
  return lhs.x >= rhs.x && lhs.y >= rhs.y;
}

inline bool operator<=(const LTVector2 &lhs, const LTVector2 &rhs) {
  return lhs.x <= rhs.x && lhs.y <= rhs.y;
}

inline bool operator!=(LTVector2 lhs, LTVector2 rhs) {
  return !(lhs == rhs);
}

inline LTVector2 operator-(const LTVector2 &vector) {
  return LTVector2(-vector.x, -vector.y);
}

inline LTVector2 operator+(LTVector2 lhs, const LTVector2 &rhs) {
  lhs += rhs;
  return lhs;
}

inline LTVector2 operator-(LTVector2 lhs, const LTVector2 &rhs) {
  lhs -= rhs;
  return lhs;
}

inline LTVector2 operator*(LTVector2 lhs, const LTVector2 &rhs) {
  lhs *= rhs;
  return lhs;
}

inline LTVector2 operator*(LTVector2 lhs, const CGFloat rhs) {
  lhs *= rhs;
  return lhs;
}

inline LTVector2 operator*(const CGFloat lhs, LTVector2 rhs) {
  rhs *= lhs;
  return rhs;
}

inline LTVector2 operator/(LTVector2 lhs, const LTVector2 &rhs) {
  lhs /= rhs;
  return lhs;
}

inline LTVector2 operator/(LTVector2 lhs, const CGFloat rhs) {
  lhs /= rhs;
  return lhs;
}

inline LTVector2 operator/(const CGFloat lhs, LTVector2 rhs) {
  return LTVector2(lhs) / rhs;
}

namespace std {
  /// Round the elements.
  inline LTVector2 round(const LTVector2 &v) {
    return LTVector2(round(v.x), round(v.y));
  }

  /// Returns element-wise minimal vector.
  inline LTVector2 min(const LTVector2 &a, const LTVector2 &b) {
    return LTVector2(min(a.x, b.x), min(a.y, b.y));
  }

  /// Returns the minimal element of the vector.
  inline float min(const LTVector2 &a) {
    return min(a.x, a.y);
  }
}

/// Returns an \c NSString representation of the given vector.
NSString *NSStringFromLTVector2(const LTVector2 &vector);

/// Returns a vector from its string representation. The representation should be in the format
/// \c @"(%g, %g)". In case an invalid format is given, LTVector2 that is set to all zeroes will be
/// returned.
LTVector2 LTVector2FromString(NSString *string);

#pragma mark -
#pragma mark LTVector3
#pragma mark -

struct LTVector3;

inline LTVector3 operator*(LTVector3 lhs, const LTVector3 &rhs);
inline LTVector3 operator/(LTVector3 lhs, const CGFloat rhs);

/// Represents a 3 element vector.
struct LTVector3 {
  /// Initializes a new \c LTVector3 with three zero elements.
  LTVector3() : x(0), y(0), z(0) {}

  /// Initializes a new \c LTVector3 with \c x, y and \c z elements equal to the given scalar.
  explicit LTVector3(float scalar) : x(scalar), y(scalar), z(scalar) {}

  /// Initializes a new \c LTVector3 from \c GLKVector3.
  explicit LTVector3(GLKVector3 vector) : x(vector.x), y(vector.y), z(vector.z) {}

  /// Initializes a new \c LTVector3 with \c x,\c y and \c z elements.
  LTVector3(float x, float y, float z) : x(x), y(y), z(z) {}

  /// Cast operator to \c GLKVector3.
  explicit operator GLKVector3() const {
    return GLKVector3Make(x, y, z);
  }

  /// Adds the given vector element wise to this vector.
  LTVector3 &operator+=(const LTVector3 &rhs) {
    x += rhs.x;
    y += rhs.y;
    z += rhs.z;
    return *this;
  }

  /// Adds each element of this vector ro the given \c rhs.
  LTVector3 &operator+=(const float &rhs) {
    x += rhs;
    y += rhs;
    z += rhs;
    return *this;
  }

  /// Subtracts the given vector element wise from this vector.
  LTVector3 &operator-=(const LTVector3 &rhs) {
    x -= rhs.x;
    y -= rhs.y;
    z -= rhs.z;
    return *this;
  }

  /// Subtracts each element of this vector from the given \c rhs.
  LTVector3 &operator-=(const float &rhs) {
    x -= rhs;
    y -= rhs;
    z -= rhs;
    return *this;
  }

  /// Multiplies the given vector element wise with this vector.
  LTVector3 &operator*=(const LTVector3 &rhs) {
    x *= rhs.x;
    y *= rhs.y;
    z *= rhs.z;
    return *this;
  }

  /// Multiplies each element of this vector with the given \c rhs.
  LTVector3 &operator*=(const float rhs) {
    x *= rhs;
    y *= rhs;
    z *= rhs;
    return *this;
  }
  
  /// Divides the given vector element wise with this vector.
  LTVector3 &operator/=(const LTVector3 &rhs) {
    x /= rhs.x;
    y /= rhs.y;
    z /= rhs.z;
    return *this;
  }

  /// Divides each element of this vector with the given \c rhs.
  LTVector3 &operator/=(const float rhs) {
    x /= rhs;
    y /= rhs;
    z /= rhs;
    return *this;
  }
  
  /// Returns the red component (first element).
  inline float &r() {
    return x;
  }

  /// Returns the red component (first element).
  inline float r() const {
    return x;
  }

  /// Returns the green component (second element).
  inline float &g() {
    return y;
  }

  /// Returns the red component (first element).
  inline float g() const {
    return y;
  }

  /// Returns the blue component (third element).
  inline float &b() {
    return z;
  }

  /// Returns the red component (first element).
  inline float b() const {
    return z;
  }

  /// Returns the sum of the components.
  inline float sum() const {
    return x + y + z;
  }

  /// Returns the length of this vector.
  inline float length() const {
    return std::sqrt(x * x + y * y + z * z);
  }

  /// Returns the dot product between this vector and the given \c vector.
  inline float dot(const LTVector3 &vector) const {
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

  float x;
  float y;
  float z;
};

inline bool operator==(const LTVector3 &lhs, const LTVector3 &rhs) {
  return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z;
}

inline bool operator>=(const LTVector3 &lhs, const LTVector3 &rhs) {
  return lhs.x >= rhs.x && lhs.y >= rhs.y && lhs.z >= rhs.z;
}

inline bool operator<=(const LTVector3 &lhs, const LTVector3 &rhs) {
  return lhs.x <= rhs.x && lhs.y <= rhs.y && lhs.z <= rhs.z;
}

inline bool operator!=(const LTVector3 &lhs, const LTVector3 &rhs) {
  return !(lhs == rhs);
}

inline LTVector3 operator-(const LTVector3 &vector) {
  return LTVector3(-vector.x, -vector.y, -vector.z);
}

inline LTVector3 operator+(LTVector3 lhs, const LTVector3 &rhs) {
  lhs += rhs;
  return lhs;
}

inline LTVector3 operator-(LTVector3 lhs, const LTVector3 &rhs) {
  lhs -= rhs;
  return lhs;
}

inline LTVector3 operator*(LTVector3 lhs, const LTVector3 &rhs) {
  lhs *= rhs;
  return lhs;
}

inline LTVector3 operator*(LTVector3 lhs, const CGFloat rhs) {
  lhs *= rhs;
  return lhs;
}

inline LTVector3 operator*(const CGFloat lhs, LTVector3 rhs) {
  rhs *= lhs;
  return rhs;
}

inline LTVector3 operator/(LTVector3 lhs, const LTVector3 &rhs) {
  lhs /= rhs;
  return lhs;
}

inline LTVector3 operator/(LTVector3 lhs, const CGFloat rhs) {
  lhs /= rhs;
  return lhs;
}

inline LTVector3 operator/(const CGFloat lhs, LTVector3 rhs) {
  return LTVector3(lhs) / rhs;
}

namespace std {
  /// Round the elements.
  inline LTVector3 round(const LTVector3 &v) {
    return LTVector3(round(v.x), round(v.y), round(v.z));
  }

  /// Return element-wise minimal vector.
  inline LTVector3 min(const LTVector3 &a, const LTVector3 &b) {
    return LTVector3(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z));
  }

  /// Returns the minimal element of the vector.
  inline float min(const LTVector3 &a) {
    return min(min(a.x, a.y), a.z);
  }
}

/// Returns an \c NSString representation of the given vector.
NSString *NSStringFromLTVector3(const LTVector3 &vector);

/// Returns a vector from its string representation. The representation should be in the format
/// \c @"(%g, %g, %g)". In case an invalid format is given, LTVector3 that is set to all zeroes will
/// be returned.
LTVector3 LTVector3FromString(NSString *string);

#pragma mark -
#pragma mark LTVector4
#pragma mark -

struct LTVector4;

inline LTVector4 operator*(LTVector4 lhs, const LTVector4 &rhs);
inline LTVector4 operator/(LTVector4 lhs, const CGFloat rhs);

/// Represents a 4 element vector.
struct LTVector4 {
  /// Initializes a new \c LTVector4 with two zero elements.
  LTVector4() : x(0), y(0), z(0), w(0) {}
  
  /// Initializes a new \c LTVector4 with \c x, y, z and \c w elements equal to the given scalar.
  explicit LTVector4(float scalar) : x(scalar), y(scalar), z(scalar), w(scalar) {}

  /// Initializes a new \c LTVector4 from \c GLKVector4.
  explicit LTVector4(GLKVector4 vector) : x(vector.x), y(vector.y), z(vector.z), w(vector.w) {}

  /// Cast operator to \c GLKVector4.
  explicit operator GLKVector4() const {
    return GLKVector4Make(x, y, z, w);
  }
  
  /// Initializes a new \c LTVector4 with \c x, \c y, \c z, and w elements.
  LTVector4(float x, float y, float z, float w) : x(x), y(y), z(z), w(w) {}

  /// Adds the given vector element wise to this vector.
  LTVector4 &operator+=(const LTVector4 &rhs) {
    x += rhs.x;
    y += rhs.y;
    z += rhs.z;
    w += rhs.w;
    return *this;
  }

  /// Adds each element of this vector ro the given \c rhs.
  LTVector4 &operator+=(const float &rhs) {
    x += rhs;
    y += rhs;
    z += rhs;
    w += rhs;
    return *this;
  }

  /// Subtracts the given vector element wise from this vector.
  LTVector4 &operator-=(const LTVector4 &rhs) {
    x -= rhs.x;
    y -= rhs.y;
    z -= rhs.z;
    w -= rhs.w;
    return *this;
  }

  /// Subtracts each element of this vector from the given \c rhs.
  LTVector4 &operator-=(const float &rhs) {
    x -= rhs;
    y -= rhs;
    z -= rhs;
    w -= rhs;
    return *this;
  }

  /// Multiplies the given vector element wise with this vector.
  LTVector4 &operator*=(const LTVector4 &rhs) {
    x *= rhs.x;
    y *= rhs.y;
    z *= rhs.z;
    w *= rhs.w;
    return *this;
  }
  
  /// Multiplies each element of this vector with the given \c rhs.
  LTVector4 &operator*=(const float rhs) {
    x *= rhs;
    y *= rhs;
    z *= rhs;
    w *= rhs;
    return *this;
  }

  /// Divides the given vector element wise with this vector.
  LTVector4 &operator/=(const LTVector4 &rhs) {
    x /= rhs.x;
    y /= rhs.y;
    z /= rhs.z;
    w /= rhs.w;
    return *this;
  }
  
  /// Divides each element of this vector with the given \c rhs.
  LTVector4 &operator/=(const float rhs) {
    x /= rhs;
    y /= rhs;
    z /= rhs;
    w /= rhs;
    return *this;
  }

  /// Returns the red component (first element).
  inline float &r() {
    return x;
  }

  /// Returns the red component (first element).
  inline float r() const {
    return x;
  }

  /// Returns the green component (second element).
  inline float &g() {
    return y;
  }

  /// Returns the red component (first element).
  inline float g() const {
    return y;
  }

  /// Returns the blue component (third element).
  inline float &b() {
    return z;
  }

  /// Returns the red component (first element).
  inline float b() const {
    return z;
  }

  /// Returns the alpha component (fourth element).
  inline float &a() {
    return w;
  }

  /// Returns the red component (first element).
  inline float a() const {
    return w;
  }

  /// Returns the sum of the components.
  inline float sum() const {
    return x + y + w + z;
  }

  /// Returns the length of this vector.
  inline float length() const {
    return std::sqrt(x * x + y * y + z * z + w * w);
  }

  /// Returns the dot product between this vector and the given \c vector.
  inline float dot(const LTVector4 &vector) const {
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

  float x;
  float y;
  float z;
  float w;
};

inline bool operator==(LTVector4 lhs, LTVector4 rhs) {
  return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z;
}

inline bool operator!=(LTVector4 lhs, LTVector4 rhs) {
  return !(lhs == rhs);
}

inline LTVector4 operator-(const LTVector4 &vector) {
  return LTVector4(-vector.x, -vector.y, -vector.z, -vector.w);
}

inline bool operator>=(const LTVector4 &lhs, const LTVector4 &rhs) {
  return lhs.x >= rhs.x && lhs.y >= rhs.y && lhs.z >= rhs.z && lhs.w >= rhs.w;
}

inline bool operator<=(const LTVector4 &lhs, const LTVector4 &rhs) {
  return lhs.x <= rhs.x && lhs.y <= rhs.y && lhs.z <= rhs.z && lhs.w <= rhs.w;
}

inline LTVector4 operator+(LTVector4 lhs, const LTVector4 &rhs) {
  lhs += rhs;
  return lhs;
}

inline LTVector4 operator+(LTVector4 lhs, const CGFloat rhs) {
  lhs += rhs;
  return lhs;
}

inline LTVector4 operator-(LTVector4 lhs, const LTVector4 &rhs) {
  lhs -= rhs;
  return lhs;
}

inline LTVector4 operator*(LTVector4 lhs, const LTVector4 &rhs) {
  lhs *= rhs;
  return lhs;
}

inline LTVector4 operator*(LTVector4 lhs, const CGFloat rhs) {
  lhs *= rhs;
  return lhs;
}

inline LTVector4 operator*(const CGFloat lhs, LTVector4 rhs) {
  rhs *= lhs;
  return rhs;
}

inline LTVector4 operator/(LTVector4 lhs, const LTVector4 &rhs) {
  lhs /= rhs;
  return lhs;
}

inline LTVector4 operator/(LTVector4 lhs, const CGFloat rhs) {
  lhs /= rhs;
  return lhs;
}

inline LTVector4 operator/(const CGFloat lhs, LTVector4 rhs) {
  return LTVector4(lhs) / rhs;
}

namespace std {
  /// Round the elements.
  inline LTVector4 round(const LTVector4 &v) {
    return LTVector4(round(v.x), round(v.y), round(v.z), round(v.w));
  }

  /// Return element-wise minimal vector.
  inline LTVector4 min(const LTVector4 &a, const LTVector4 &b) {
    return LTVector4(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z), min(a.w, b.w));
  }

  /// Returns the minimal element of the vector.
  inline float min(const LTVector4 &a) {
    return min(min(min(a.x, a.y), a.z), a.w);
  }
}

/// Returns an \c NSString representation of the given vector.
NSString *NSStringFromLTVector4(const LTVector4 &vector);

/// Returns a vector from its string representation. The representation should be in the format
/// \c @"(%g, %g, %g, %g)". In case an invalid format is given, LTVector4 that is set to all zeroes
/// will be returned.
LTVector4 LTVector4FromString(NSString *string);

#pragma mark -
#pragma mark Constants
#pragma mark -

static const LTVector2 LTVector2Zero;
static const LTVector3 LTVector3Zero;
static const LTVector4 LTVector4Zero;

static const LTVector2 LTVector2One(1, 1);
static const LTVector3 LTVector3One(1, 1, 1);
static const LTVector4 LTVector4One(1, 1, 1, 1);

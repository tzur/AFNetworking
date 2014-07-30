// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <GLKit/GLKit.h>

#pragma mark -
#pragma mark LTVector2
#pragma mark -

/// Represents a 2 element vector.
struct LTVector2 {
  /// Initializes a new \c LTVector2 with two zero elements.
  LTVector2() : x(0), y(0) {}

  /// Initializes a new \c LTVector2 with \c x and \c y elements.
  LTVector2(float x, float y) : x(x), y(y) {}

  /// Initializes a new \c LTVector2 from \c GLKVector2.
  LTVector2(GLKVector2 vector) : x(vector.x), y(vector.y) {}

  /// Initializes a new \c LTVector2 from \c CGPoint.
  LTVector2(CGPoint point) : x(point.x), y(point.y) {}

  /// Cast operator to \c GLKVector2.
  operator GLKVector2() {
    return GLKVector2Make(x, y);
  }

  /// Cast operator to \c CGPoint.
  operator CGPoint() {
    return CGPointMake(x, y);
  }

  /// Adds the given vector element wise to this vector.
  LTVector2 &operator+=(const LTVector2 &rhs) {
    x += rhs.x;
    y += rhs.y;
    return *this;
  }

  /// Subtracts the given vector element wise from this vector.
  LTVector2 &operator-=(const LTVector2 &rhs) {
    x -= rhs.x;
    y -= rhs.y;
    return *this;
  }

  /// Multiplies the given vector element wise with this vector.
  LTVector2 &operator*=(const LTVector2 &rhs) {
    x *= rhs.x;
    y *= rhs.y;
    return *this;
  }

  /// Divides the given vector element wise with this vector.
  LTVector2 &operator/=(const LTVector2 &rhs) {
    x /= rhs.x;
    y /= rhs.y;
    return *this;
  }

  /// Returns the red component (first element).
  inline float &r() {
    return x;
  }

  /// Returns the green component (second element).
  inline float &g() {
    return y;
  }

  float x;
  float y;
};

inline bool operator==(LTVector2 lhs, LTVector2 rhs) {
  return lhs.x == rhs.x && lhs.y == rhs.y;
}

inline bool operator!=(LTVector2 lhs, LTVector2 rhs) {
  return !(lhs == rhs);
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

inline LTVector2 operator/(LTVector2 lhs, const LTVector2 &rhs) {
  lhs /= rhs;
  return lhs;
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

/// Represents a 3 element vector.
struct LTVector3 {
  /// Initializes a new \c LTVector3 with two zero elements.
  LTVector3() : x(0), y(0), z(0) {}

  /// Initializes a new \c LTVector3 with \c x,\c y and \c z elements.
  LTVector3(float x, float y, float z) : x(x), y(y), z(z) {}

  /// Initializes a new \c LTVector3 from \c GLKVector3.
  LTVector3(GLKVector3 vector) : x(vector.x), y(vector.y), z(vector.z) {}

  /// Cast operator to \c GLKVector3.
  operator GLKVector3() {
    return GLKVector3Make(x, y, z);
  }

  /// Adds the given vector element wise to this vector.
  LTVector3 &operator+=(const LTVector3 &rhs) {
    x += rhs.x;
    y += rhs.y;
    z += rhs.z;
    return *this;
  }

  /// Subtracts the given vector element wise from this vector.
  LTVector3 &operator-=(const LTVector3 &rhs) {
    x -= rhs.x;
    y -= rhs.y;
    z -= rhs.z;
    return *this;
  }

  /// Multiplies the given vector element wise with this vector.
  LTVector3 &operator*=(const LTVector3 &rhs) {
    x *= rhs.x;
    y *= rhs.y;
    z *= rhs.z;
    return *this;
  }

  /// Divides the given vector element wise with this vector.
  LTVector3 &operator/=(const LTVector3 &rhs) {
    x /= rhs.x;
    y /= rhs.y;
    z /= rhs.z;
    return *this;
  }

  /// Returns the red component (first element).
  inline float &r() {
    return x;
  }

  /// Returns the green component (second element).
  inline float &g() {
    return y;
  }

  /// Returns the blue component (third element).
  inline float &b() {
    return z;
  }

  float x;
  float y;
  float z;
};

inline bool operator==(const LTVector3 &lhs, const LTVector3 &rhs) {
  return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z;
}

inline bool operator!=(const LTVector3 &lhs, const LTVector3 &rhs) {
  return !(lhs == rhs);
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

inline LTVector3 operator/(LTVector3 lhs, const LTVector3 &rhs) {
  lhs /= rhs;
  return lhs;
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

/// Represents a 4 element vector.
struct LTVector4 {
  /// Initializes a new \c LTVector4 with two zero elements.
  LTVector4() : x(0), y(0), z(0), w(0) {}

  /// Initializes a new \c LTVector4 with \c x, \c y, \c z, and w elements.
  LTVector4(float x, float y, float z, float w) : x(x), y(y), z(z), w(w) {}

  /// Initializes a new \c LTVector4 from \c GLKVector4.
  LTVector4(GLKVector4 vector) : x(vector.x), y(vector.y), z(vector.z), w(vector.w) {}

  /// Cast operator to \c GLKVector4.
  operator GLKVector4() {
    return GLKVector4Make(x, y, z, w);
  }

  /// Adds the given vector element wise to this vector.
  LTVector4 &operator+=(const LTVector4 &rhs) {
    x += rhs.x;
    y += rhs.y;
    z += rhs.z;
    w += rhs.w;
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

  /// Multiplies the given vector element wise with this vector.
  LTVector4 &operator*=(const LTVector4 &rhs) {
    x *= rhs.x;
    y *= rhs.y;
    z *= rhs.z;
    w *= rhs.w;
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

  /// Returns the red component (first element).
  inline float &r() {
    return x;
  }

  /// Returns the green component (second element).
  inline float &g() {
    return y;
  }

  /// Returns the blue component (third element).
  inline float &b() {
    return z;
  }

  /// Returns the alpha component (fourth element).
  inline float &a() {
    return w;
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

inline LTVector4 operator+(LTVector4 lhs, const LTVector4 &rhs) {
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

inline LTVector4 operator/(LTVector4 lhs, const LTVector4 &rhs) {
  lhs /= rhs;
  return lhs;
}

/// Returns an \c NSString representation of the given vector.
NSString *NSStringFromLTVector4(const LTVector4 &vector);

/// Returns a vector from its string representation. The representation should be in the format
/// \c @"(%g, %g, %g, %g)". In case an invalid format is given, LTVector4 that is set to all zeroes
/// will be returned.
LTVector4 LTVector4FromString(NSString *string);

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTKit/LTHashExtensions.h>

/// An array of three \c CGPoint values representing the corners of a triangle.
typedef std::array<CGPoint, 3> LTTriangleCorners;

namespace lt {

/// Struct representing a primitive triangle.
struct Triangle {
  /// Type of triangle.
  enum Type {
    /// All corners of triangle are \c CGPointNull.
    Null,
    /// All corners of triangle are the same.
    Point,
    /// All corners of triangle are collinear.
    Collinear,
    /// Corners of triangle are in clockwise direction.
    Clockwise,
    /// Corners of triangle are in counter-clockwise direction.
    CounterClockwise
  };

#pragma mark -
#pragma mark Initialization
#pragma mark -

  /// Initializes with \c CGPointNull for all corners.
  constexpr Triangle() noexcept : v({{CGPointNull, CGPointNull, CGPointNull}}),
                                  triangleType(Type::Null) {};

  /// Initializes with the given vertices \c v0, \c v1, and \c v2. If any of the given vertices is
  /// \c CGPointNull, all vertices will be set to \c CGPointNull.
  Triangle(CGPoint v0, CGPoint v1, CGPoint v2) noexcept : Triangle({{v0, v1, v2}}) {};

  /// Initializes with the given \c corners. If any of the given \c corners is \c CGPointNull, all
  /// corners will be set to \c CGPointNull.
  explicit Triangle(const LTTriangleCorners &corners) noexcept;

#pragma mark -
#pragma mark Convenience methods
#pragma mark -

  /// Returns a triangle with the same corners as this triangle, but in flipped order.
  Triangle flipped() const noexcept {
    return Triangle(v[2], v[1], v[0]);
  }

#pragma mark -
#pragma mark Point containment/relation
#pragma mark -

  /// Returns \c YES if the given \c point is contained by this triangle.
  BOOL containsPoint(CGPoint point) const noexcept;

#pragma mark -
#pragma mark Properties
#pragma mark -

  /// Area occupied by this triangle.
  CGFloat area() const noexcept {
    /// Use a numerically stable algorithm to compute triangle area.
    /// @see https://en.wikipedia.org/wiki/Heron%27s_formula#Numerical_stability
    std::array<CGFloat, 3> d =
        {{CGPointDistance(v[0], v[1]), CGPointDistance(v[1], v[2]), CGPointDistance(v[2], v[0])}};
    std::sort(d.begin(), d.end());
    return std::sqrt((d[2] + (d[1] + d[0])) * (d[0] - (d[2] - d[1])) *
                     (d[0] + (d[2] - d[1])) * (d[2] + (d[1] - d[0]))) / 4;
  }

  /// Corners of this triangle as provided upon initialization.
  constexpr LTTriangleCorners corners() noexcept {
    return v;
  }

  /// Type of this triangle.
  constexpr Type type() noexcept {
    return triangleType;
  }

  /// First vertex of this triangle. Corresponds to \c corners()[0].
  constexpr CGPoint v0() noexcept {
    return v[0];
  }

  /// Second vertex of this triangle. Corresponds to \c corners()[1].
  constexpr CGPoint v1() noexcept {
    return v[1];
  }

  /// Third vertex of this triangle. Corresponds to \c corners()[2].
  constexpr CGPoint v2() noexcept {
    return v[2];
  }

private:
  LTTriangleCorners v;
  Type triangleType;
};

#pragma mark -
#pragma mark Equality
#pragma mark -

inline bool operator==(lt::Triangle lhs, lt::Triangle rhs) {
  return lhs.corners() == rhs.corners();
}

inline bool operator!=(lt::Triangle lhs, lt::Triangle rhs) {
  return lhs.corners() != rhs.corners();
}

} // namespace lt

namespace std {

/// Specialization of \c std hash function for \c lt::Triangle objects.
template <>
struct hash<lt::Triangle> : public unary_function<lt::Triangle, size_t> {
  size_t operator()(lt::Triangle triangle) const noexcept {
    return lt::hash<LTTriangleCorners>()(triangle.corners());
  }
};

} // namespace std

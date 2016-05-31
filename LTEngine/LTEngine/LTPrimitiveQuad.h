// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTGeometry.h"

#import <LTKit/LTHashExtensions.h>
#import <experimental/optional>

/// Enumeration of regions inside and around the quad.
typedef NS_OPTIONS(NSUInteger, LTQuadCornerRegion) {
  LTQuadCornerRegionNone = 0b00000000,
  LTQuadCornerRegionV0 =   0b00000001,
  LTQuadCornerRegionV1 =   0b00000010,
  LTQuadCornerRegionV2 =   0b00000100,
  LTQuadCornerRegionV3 =   0b00001000,
  LTQuadCornerRegionAll =  LTQuadCornerRegionV0 | LTQuadCornerRegionV1 |
                           LTQuadCornerRegionV2 | LTQuadCornerRegionV3 // => 0b00001111
};

#ifdef __cplusplus

namespace lt {

/// Immutable object representing a primitive quadrilateral.
struct Quad {

  /// Number of corners of a quad.
  static const NSUInteger kNumQuadCorners = 4;

  /// Ordered collection of four \c CGPoint representing the corners of a quadrilateral.
  typedef std::array<CGPoint, kNumQuadCorners> Corners;

  /// Returns the corners of a null quad.
  static constexpr Corners nullCorners() noexcept {
    return {{CGPointNull, CGPointNull, CGPointNull, CGPointNull}};
  }

#pragma mark -
#pragma mark Initialization
#pragma mark -

  /// Initializes with \c CGPointNull for all corners.
  constexpr Quad() noexcept : _v(nullCorners()), _quadType(Quad::Type::Null) {};

  /// Initializes with the given vertices \c v0, \c v1, \c v2, and \c v3.
  constexpr Quad(CGPoint v0, CGPoint v1, CGPoint v2, CGPoint v3) noexcept :
      _v({{v0, v1, v2, v3}}) {};

  /// Initializes with the given \c corners.
  explicit constexpr Quad(const Corners &corners) noexcept : _v(corners) {};

  /// Initializes with the given \c rect.
  explicit Quad(CGRect rect) noexcept :
      _v({{rect.origin, rect.origin + CGPointMake(rect.size.width, 0), rect.origin + rect.size,
           rect.origin + CGPointMake(0, rect.size.height)}}) {};

#pragma mark -
#pragma mark Transformations
#pragma mark -

  /// Returns a new quad with the corners of this quad rotated in clockwise direction by the given
  /// \c angle, which is to be provided in radians, around the given \c anchorPoint.
  Quad rotatedAroundPoint(CGFloat angle, CGPoint anchorPoint) const noexcept;

  /// Returns a new quad scaled by the given \c scaleFactor around the \c center of this quad.
  Quad scaledBy(CGFloat scaleFactor) const noexcept;

  /// Returns a new quad scaled by the given \c scaleFactor around the given \c anchorPoint.
  Quad scaledAround(CGFloat scaleFactor, CGPoint anchorPoint) const noexcept;

  /// Returns a new quad translated by the given \c translation.
  Quad translatedBy(CGPoint translation) const noexcept;

  /// Returns a new quad with the corners belonging to the given \c group translated by the given
  /// \c translation.
  Quad translatedBy(CGPoint translation, LTQuadCornerRegion group) const noexcept;

  /// Returns a new quad with corners corresponding to those of the given \c rect after transforming
  /// each of the rect corners using the \c transform of this quad. Returns a null quad if this quad
  /// is a null quad itself.
  Quad quadFromTransformedRect(CGRect rect) const noexcept;

  /// Returns \c YES if it is possible to transform this quad using translation, rotation and
  /// scaling such that the corners of this quad corners after the transformation coincide with the
  /// corners of the given \c quad, up to the given \c deviation in distance, for each corner. If
  /// the transformation is possible, \c translation, \c scaling and \c rotation contain the
  /// appropriate values required for the transformation (consisting of first translating, then
  /// rotating in clockwise order around quad center and finally scaling). Otherwise, the values at
  /// the given \c translation, \c scaling and \c rotation addresses are not updated.
  BOOL isTransformableToQuadWithDeviation(Quad quad, CGFloat deviation, CGPoint *translation,
                                          CGFloat *rotation, CGFloat *scaling) const noexcept;

#pragma mark -
#pragma mark Comparison
#pragma mark -

  /// Returns \c YES if the distance between each corner of this quad and the corresponding corner
  /// of the given \c quad is smaller than or equal to the given \c deviation.
 BOOL isSimilarToQuadUpToDeviation(Quad quad, CGFloat deviation) const noexcept;

#pragma mark -
#pragma mark Point containment/relation
#pragma mark -

  /// Returns \c YES if the given \c point is contained by this quad.
  BOOL containsPoint(CGPoint point) const noexcept;

  /// Returns \c YES if this quad contains at least one of the vertices of the given \c quad.
  BOOL containsVertexOfQuad(Quad quad) const noexcept;

  /// Returns the point on any edge of this quad which has the smallest distance to the given
  /// \c point.
  CGPoint pointOnEdgeClosestToPoint(CGPoint point) const noexcept;

  /// Returns a pair <tt>(\c p, \c q)</tt> of points, such that (I) \c p lies on an edge of this
  /// quad and \c q lies on an edge of the given \c quad and (II) \c p and \c q have minimum
  /// distance.
  CGPointPair nearestPoints(Quad quad) const noexcept;

#pragma mark -
#pragma mark Properties
#pragma mark -

  /// Area occupied by this quad.
  CGFloat area() const noexcept;

  /// Rect of minimum size bounding this quad.
  CGRect boundingRect() const noexcept;

  /// Center of this quad.
  CGPoint center() const noexcept {
    return (_v[0] + _v[1] + _v[2] + _v[3]) / 4;
  }

  /// Points representing the convex hull of this quad.
  CGPoints convexHull() const noexcept {
    return LTConvexHull({_v[0], _v[1], _v[2], _v[3]});
  }

  /// Corners \c v0, \c v1, \c v2, \c v3 of this quad.
  constexpr Corners corners() const noexcept {
    return _v;
  }

  /// \c YES if at least one corner of this quad is \c CGPointNull.
  BOOL isNull() const noexcept;

  /// \c YES if this quad is degenerate, i.e. at least two corners coincide, but the corners do not
  /// form a triangle.
  BOOL isDegenerate() const noexcept;

  /// \c YES if this quad represents a triangle.
  BOOL isTriangular() const noexcept;

  /// \c YES if this quad is convex.
  BOOL isConvex() const noexcept;

  /// \c YES if this quad is self-intersecting. Degenerate and triangular quads are not considered
  /// self-intersecting.
  BOOL isSelfIntersecting() const noexcept;

  /// Length of the shortest edge of this quad.
  CGFloat minimumEdgeLength() const noexcept;

  /// Length of the longest edge of this quad.
  CGFloat maximumEdgeLength() const noexcept;

  /// Transformation required to transform a rectangle with origin at <tt>(0, 0)</tt> and size
  /// <tt>(1, 1)</tt> such that its projected corners coincide with the vertices of this quad.
  GLKMatrix3 transform() const noexcept;

  /// First vertex of this quad. Corresponds to \c corners()[0].
  constexpr CGPoint v0() const noexcept {
    return _v[0];
  }

  /// Second vertex of this quad. Corresponds to \c corners()[1].
  constexpr CGPoint v1() const noexcept {
    return _v[1];
  }

  /// Third vertex of this quad. Corresponds to \c corners()[2].
  constexpr CGPoint v2() const noexcept {
    return _v[2];
  }

  /// Fourth vertex of this quad. Corresponds to \c corners()[3].
  constexpr CGPoint v3() const noexcept {
    return _v[3];
  }

private:
  /// Type of quad.
  enum class Type {
    /// All corners of quad are \c CGPointNull.
    Null,
    /// Degenerate quad (at least two points coinciding, but not a triangle).
    Degenerate,
    /// Degenerate quad of triangle shape.
    Triangle,
    /// Quad is convex with corners in clockwise direction.
    ConvexClockwise,
    /// Quad is convex with corners in counter-clockwise direction.
    ConvexCounterClockwise,
    /// Quad is concave with corners in clockwise direction.
    ConcaveClockwise,
    /// Quad is concave with corners in counter-clockwise direction.
    ConcaveCounterClockwise,
    /// Quad is self-intersecting.
    Complex
  };

  /// Lazily initialized type of this quad.
  Type type() const noexcept;

  Corners _v;
  mutable std::experimental::optional<Type> _quadType;
};

#pragma mark -
#pragma mark Transformations
#pragma mark -

inline Quad Quad::scaledBy(CGFloat scaleFactor) const noexcept {
  return scaledAround(scaleFactor, center());
}

inline Quad Quad::scaledAround(CGFloat scaleFactor, CGPoint anchorPoint) const noexcept {
  return Quad(anchorPoint + scaleFactor * (_v[0] - anchorPoint),
              anchorPoint + scaleFactor * (_v[1] - anchorPoint),
              anchorPoint + scaleFactor * (_v[2] - anchorPoint),
              anchorPoint + scaleFactor * (_v[3] - anchorPoint));
}

inline Quad Quad::translatedBy(CGPoint translation) const noexcept {
  return translatedBy(translation, LTQuadCornerRegionAll);
}

#pragma mark -
#pragma mark Comparison
#pragma mark -

inline BOOL Quad::isSimilarToQuadUpToDeviation(Quad quad, CGFloat deviation) const noexcept {
  return CGPointDistance(_v[0], quad._v[0]) <= deviation &&
      CGPointDistance(_v[1], quad._v[1]) <= deviation &&
      CGPointDistance(_v[2], quad._v[2]) <= deviation &&
      CGPointDistance(_v[3], quad._v[3]) <= deviation;
}

#pragma mark -
#pragma mark Point containment/relation
#pragma mark -

inline BOOL Quad::containsVertexOfQuad(Quad quad) const noexcept {
  return (containsPoint(quad._v[0]) || containsPoint(quad._v[1]) ||
          containsPoint(quad._v[2]) || containsPoint(quad._v[3]));
}

#pragma mark -
#pragma mark Properties
#pragma mark -

inline BOOL Quad::isNull() const noexcept {
  return type() == Quad::Type::Null;
}

inline BOOL Quad::isDegenerate() const noexcept {
  return type() == Quad::Type::Degenerate;
}

inline BOOL Quad::isTriangular() const noexcept {
  return type() == Quad::Type::Triangle;
}

inline BOOL Quad::isConvex() const noexcept {
  return type() == Quad::Type::ConvexClockwise || type() == Quad::Type::ConvexCounterClockwise ||
      isTriangular();
}

inline BOOL Quad::isSelfIntersecting() const noexcept {
  return type() == Quad::Type::Complex;
}

#pragma mark -
#pragma mark Equality
#pragma mark -

inline bool operator==(const Quad &lhs, const Quad &rhs) noexcept {
  return lhs.corners() == rhs.corners();
}

inline bool operator!=(const Quad &lhs, const Quad &rhs) noexcept {
  return lhs.corners() != rhs.corners();
}

} // namespace lt

#pragma mark -
#pragma mark Hash
#pragma mark -

/// Hash value of this quad.
template <>
struct ::std::hash<lt::Quad> {
  inline size_t operator()(const lt::Quad &q) const {
    return std::hash<lt::Quad::Corners>()(q.corners());
  }
};

#endif

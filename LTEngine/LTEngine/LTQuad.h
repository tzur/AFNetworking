// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTKit/LTHashExtensions.h>
#import <experimental/optional>

#import "LTGeometry.h"

NS_ASSUME_NONNULL_BEGIN

namespace lt {
  struct Quad;
}

@class LTRotatedRect;

/// An array of four \c CGPoint representing the corners of a quadrilateral.
typedef std::array<CGPoint, 4> LTQuadCorners;

/// Enumeration of regions inside and around the quad.
typedef NS_OPTIONS(NSUInteger, LTQuadCornerRegion) {
  LTQuadCornerRegionNone = 0,
  LTQuadCornerRegionV0 = (1 << 0),  // => 00000001
  LTQuadCornerRegionV1 = (1 << 1),  // => 00000010
  LTQuadCornerRegionV2 = (1 << 2),  // => 00000100
  LTQuadCornerRegionV3 = (1 << 3),  // => 00001000
  LTQuadCornerRegionAll = LTQuadCornerRegionV0 | LTQuadCornerRegionV1 | LTQuadCornerRegionV2 |
      LTQuadCornerRegionV3 // => 00001111
};

/// Enumeration indicating validity of quad corners for initialization.
typedef NS_ENUM(NSUInteger, LTQuadCornersValidity) {
  // Corners can be used for initializing a quad.
  LTQuadCornersValidityValid,
  // Corners can not be used for initializing a quad since they contain at least one null point.
  LTQuadCornersValidityInvalidDueToNull,
  // Corners can not be used for initializing a quad since they are given in counter-clockwise
  // order.
  LTQuadCornersValidityInvalidDueToOrder,
  // Corners can not be used for initializing a quad since all corners are collinear.
  LTQuadCornersValidityInvalidDueToCollinearity,
  // Corners can not be used for initializing a quad since at least two corners are too close to
  // each other.
  LTQuadCornersValidityInvalidDueToProximity
};

/// Value class representing a quadrilateral in a two-dimensional space. Creation of instances of
/// this class is more expensive than the creation of \c lt::Quad objects. \c LTQuad should be used
/// (rather than \c lt::Quad) if the quads need to be stored in an Objective-C container or if a
/// subclass must be created (subclassing this class is discouraged).
/// In addition, \c LTQuad objects must be valid according to \c LTQuadCornersValidity, while
/// \c lt::Quad objects do not enforce any such restriction.
@interface LTQuad : NSObject <NSCopying>

#pragma mark -
#pragma mark Initialization - Factory methods
#pragma mark -

/// Returns a quad with the vertices of the given \c quad. You may call this method using a subclass
/// of \c LTQuad to receive an instance of the desired type, however, only if the subclass has the
/// same designated initializer as \c LTQuad.
+ (instancetype)quadWithVerticesOfQuad:(LTQuad *)quad;

/// Returns a quad with the vertices of the given \c quad. You may call this method using a subclass
/// of \c LTQuad to receive an instance of the desired type, however, only if the subclass has the
/// same designated initializer as \c LTQuad.
+ (instancetype)quadFromQuad:(const lt::Quad &)quad;

/// Returns a rectangular quad defined by the given \c rect. Returns \c nil if the resulting quad
/// would be invalid (refer to \c LTQuadCornersValidity for more details). You may call this method
/// using a subclass of \c LTQuad to receive an instance of the desired type, however, only if the
/// subclass has the same designated initializer as \c LTQuad.
+ (instancetype)quadFromRect:(CGRect)rect;

/// Returns a rectangular quad with the given \c origin and the given \c size. Returns \c nil if the
/// resulting quad would be invalid (refer to \c LTQuadCornersValidity for more details). You may
/// call this method using a subclass of \c LTQuad to receive an instance of the desired type,
/// however, only if the subclass has the same designated initializer as \c LTQuad.
+ (instancetype)quadFromRectWithOrigin:(CGPoint)origin andSize:(CGSize)size;

/// Returns a rectangular rotated quad defined by the given \c rotatedRect. Returns \c nil if the
/// resulting quad would be invalid (refer to \c LTQuadCornersValidity for more details). You may
/// call this method using a subclass of \c LTQuad to receive an instance of the desired type,
/// however, only if the subclass has the same designated initializer as \c LTQuad.
+ (instancetype)quadFromRotatedRect:(LTRotatedRect *)rotatedRect;

/// Returns a quad whose corners correspond to those of the given \c rect after transforming them
/// using the \c transform of the given \c quad. The given \c quad must not be \c nil. Returns
/// \c nil if the resulting quad would be invalid (refer to \c LTQuadCornersValidity for more
/// details). You may call this method using a subclass of \c LTQuad to receive an instance of the
/// desired type, however, only if the subclass has the same designated initializer as \c LTQuad.
+ (instancetype)quadFromRect:(CGRect)rect transformedByTransformOfQuad:(LTQuad *)quad;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a general quad defined by the given \c corners. In case of a simple (i.e.
/// non-self-intersecting) quad, the corners have to be provided in clockwise order. The provided
/// corners must be valid (refer to \c LTQuadCornersValidity for more details). Checking whether
/// corners are valid for initialization can be done using the \c validityOfCorners: method.
- (instancetype)initWithCorners:(const LTQuadCorners &)corners;

/// Designated initializer: initializes a general quad defined by the given \c quad. In case of a
/// simple (i.e. non-self-intersecting) quad, the corners of the given \c quad must be in clockwise
/// order. The corners of the given \c quad must be valid (refer to \c LTQuadCornersValidity for
/// more details). Checking whether corners are valid for initialization can be done using the
/// \c validityOfCorners: method.
- (instancetype)initWithQuad:(const lt::Quad &)quad NS_DESIGNATED_INITIALIZER;

#pragma mark -
#pragma mark Copying
#pragma mark -

/// Returns a copy of this instance with identical properties except for the given \c corners. The
/// provided corners must be valid (refer to \c LTQuadCornersValidity for more details). Checking
/// whether corners are valid for initialization can be done using the \c validityOfCorners: method.
- (instancetype)copyWithCorners:(const LTQuadCorners &)corners;

/// Returns a copy of this instance with identical properties with the exception that the corners of
/// the returned instance correspond to the corners of this instance rotated in clockwise direction
/// by the given \c angle, which is to be provided in radians, around the given \c anchorPoint.
/// Returns \c nil if the resulting quad would be invalid (refer to \c LTQuadCornersValidity for
/// more details).
- (instancetype)copyWithRotation:(CGFloat)angle aroundPoint:(CGPoint)anchorPoint;

/// Returns a copy of this instance with identical properties with the exception that the corners of
/// the returned instance correspond to the corners of this instance scaled by the given
/// \c scaleFactor around the center of this instance. Returns \c nil if the resulting quad would
/// be invalid (refer to \c LTQuadCornersValidity for more details).
- (instancetype)copyWithScaling:(CGFloat)scaleFactor;

/// Returns a copy of this instance with identical properties with the exception that the corners of
/// the returned instance correspond to the corners of this instance scaled by the given
/// \c scaleFactor around the given \c anchorPoint. Returns \c nil if the resulting quad would be
/// invalid (refer to \c LTQuadCornersValidity for more details).
- (instancetype)copyWithScaling:(CGFloat)scaleFactor aroundPoint:(CGPoint)anchorPoint;

/// Returns a copy of this instance with identical properties with the exception that the \c corners
/// of the returned instance correspond to the \c corners of this instance translated by the given
/// \c translation. The quad corners not among the given \c corners are copied without translation.
/// Returns \c nil if the resulting quad would be invalid (refer to \c LTQuadCornersValidity for
/// more details).
- (instancetype)copyWithTranslation:(CGPoint)translation ofCorners:(LTQuadCornerRegion)corners;

/// Returns a copy of this instance with identical properties with the exception that the corners of
/// the returned instance correspond to the corners of this instance translated by the given
/// \c translation. Returns \c nil if the resulting quad would be invalid (refer to
/// \c LTQuadCornersValidity for more details). Calling this method on a \c quad is identical to
/// @code
/// [quad copyWithTranslation:translation ofCorners:LTQuadCornerRegionAll]
/// @endcode
- (instancetype)copyWithTranslation:(CGPoint)translation;

#pragma mark -
#pragma mark Corner validity
#pragma mark -

/// Returns a value of \c LTQuadCornersValidity indicating the validity of the provided corners.
+ (LTQuadCornersValidity)validityOfCorners:(const LTQuadCorners &)corners;

#pragma mark -
#pragma mark Point containment/relation
#pragma mark -

/// Returns \c YES if the given \c point is contained by this quad.
- (BOOL)containsPoint:(CGPoint)point;

/// Returns \c YES if this instance contains at least one of the vertices of the given \c quad.
- (BOOL)containsVertexOfQuad:(LTQuad *)quad;

/// Returns the point on any edge of this quad which has the smallest distance to the given
/// \c point.
- (CGPoint)pointOnEdgeClosestToPoint:(CGPoint)point;

/// Returns a pair (\c p, \c q) of points, such that (I) \c p lies on an edge of this instance and
/// \c q lies on an edge of the given \c quad and (II) \c p and \c q have minimum distance.
- (CGPointPair)nearestPoints:(LTQuad *)quad;

#pragma mark -
#pragma mark Similarity/transformability
#pragma mark -

/// Returns YES if each corner of \c quad equals the corresponding corner of this instance, up to
/// the given \c deviation.
- (BOOL)isSimilarTo:(LTQuad *)quad upToDeviation:(CGFloat)deviation;

/// Returns YES if it is possible to transform this instance using translation, rotation and scaling
/// such that this instance's corners after the transformation coincide with the corners of the
/// given \c quad, up to the given deviation in distance. If the transformation is possible,
/// \c translation, \c scaling and \c rotation contain the appropriate values required for the
/// transformation (consisting of first translating, then rotating in clockwise order around quad
/// center and finally scaling). Otherwise, the values of \c translation, \c scaling and \c rotation
/// are undefined. \c translation, \c scaling and \c rotation must not be \c nil.
- (BOOL)isTransformableToQuad:(LTQuad *)quad withDeviation:(CGFloat)deviation
                  translation:(CGPoint *)translation rotation:(CGFloat *)rotation
                      scaling:(CGFloat *)scaling;

#pragma mark -
#pragma mark Properties
#pragma mark -

/// Area occupied by this quad.
@property (readonly, nonatomic) CGFloat area;

/// Corners of this quad.
@property (readonly, nonatomic) LTQuadCorners corners;

/// First vertex of the quad. Corresponds to \c corners[0].
@property (readonly, nonatomic) CGPoint v0;
/// Second vertex of the quad. Corresponds to \c corners[1].
@property (readonly, nonatomic) CGPoint v1;
/// Third vertex of the quad. Corresponds to \c corners[2].
@property (readonly, nonatomic) CGPoint v2;
/// Fourth vertex of the quad. Corresponds to \c corners[3].
@property (readonly, nonatomic) CGPoint v3;

/// Rect that bounds the quad.
@property (readonly, nonatomic) CGRect boundingRect;

/// Points representing the convex hull of this quad.
@property (readonly, nonatomic) CGPoints convexHull;

/// Center of this quad. The center is defined to be the average of the coordinates of the corner
/// points.
@property (readonly, nonatomic) CGPoint center;

/// \c YES if this quad is convex.
@property (readonly, nonatomic) BOOL isConvex;

/// \c YES if this quad is self-intersecting.
@property (readonly, nonatomic) BOOL isSelfIntersecting;

/// Transpose of the transformation required to transform a rectangle with origin at (0, 0) and size
/// (1, 1) such that its projected corners coincide with the vertices of this quad.
@property (readonly, nonatomic) GLKMatrix3 transform;

/// Length of the shortest edge of this \c quad.
@property (readonly, nonatomic) CGFloat minimalEdgeLength;

/// Length of the longest edge of this \c quad.
@property (readonly, nonatomic) CGFloat maximalEdgeLength;

/// C++ representation of this instance.
@property (readonly, nonatomic) lt::Quad quad;

@end

namespace lt {

/// Value class representing a quadrilateral in a two-dimensional space. Creation of instances of
/// this class is less expensive than the creation of \c LTQuad objects. \c lt::Quad should be used
/// (rather than \c LTQuad) if the quads need to be created stored in an \c STL container or due to
/// performance considerations.
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
#pragma mark Convenience Initialization
#pragma mark -

  /// Returns a new quad representing the canonical square with origin <tt>(0, 0)</tt> and size
  /// <tt>(1, 1)</tt>.
  static Quad canonicalSquare() noexcept;

#pragma mark -
#pragma mark Transformations
#pragma mark -

  /// Returns a new quad with the corners of this quad rotated in clockwise direction by the given
  /// \c angle, which is to be provided in radians, around the given \c anchorPoint.
  Quad rotatedAroundPoint(CGFloat angle, CGPoint anchorPoint) const noexcept;

  /// Returns a new quad scaled uniformly by the given \c scaleFactor around the \c center of this
  /// quad.
  Quad scaledBy(CGFloat scaleFactor) const noexcept;

  /// Returns a new quad scaled non-uniformly by the given \c scaleFactor around the \c center of
  /// this quad.
  Quad scaledBy(LTVector2 scaleFactor) const noexcept;

  /// Returns a new quad scaled uniformly by the given \c scaleFactor around the given
  /// \c anchorPoint.
  Quad scaledAround(CGFloat scaleFactor, CGPoint anchorPoint) const noexcept;

  /// Returns a new quad scaled non-uniformly by the given \c scaleFactor around the given
  /// \c anchorPoint.
  Quad scaledAround(LTVector2 scaleFactor, CGPoint anchorPoint) const noexcept;

  /// Returns a new quad translated by the given \c translation.
  Quad translatedBy(CGPoint translation) const noexcept;

  /// Returns a new quad with the corners belonging to the given \c group translated by the given
  /// \c translation.
  Quad translatedBy(CGPoint translation, LTQuadCornerRegion group) const noexcept;

  /// Returns a new quad with the corners transformed by the given \c transform.
  Quad transformedBy(CGAffineTransform transform) const noexcept;

  /// Returns a new quad with the corners transformed by the given \c transform.
  Quad transformedBy(GLKMatrix3 transform) const noexcept;

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

  /// Transpose of the transformation required to transform a rectangle with origin at
  /// <tt>(0, 0)</tt> and size <tt>(1, 1)</tt> such that its projected corners coincide with the
  /// vertices of this quad.
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
  return scaledAround(LTVector2(scaleFactor), center());
}

inline Quad Quad::scaledBy(LTVector2 scaleFactor) const noexcept {
  return scaledAround(scaleFactor, center());
}

inline Quad Quad::scaledAround(CGFloat scaleFactor, CGPoint anchorPoint) const noexcept {
  return scaledAround(LTVector2(scaleFactor), anchorPoint);
}

inline Quad Quad::scaledAround(LTVector2 scaleFactor, CGPoint anchorPoint) const noexcept {
  return Quad(anchorPoint + (CGPoint)scaleFactor * (_v[0] - anchorPoint),
              anchorPoint + (CGPoint)scaleFactor * (_v[1] - anchorPoint),
              anchorPoint + (CGPoint)scaleFactor * (_v[2] - anchorPoint),
              anchorPoint + (CGPoint)scaleFactor * (_v[3] - anchorPoint));
}

inline Quad Quad::translatedBy(CGPoint translation) const noexcept {
  return translatedBy(translation, LTQuadCornerRegionAll);
}

inline Quad Quad::transformedBy(CGAffineTransform transform) const noexcept {
  return Quad(CGPointApplyAffineTransform(_v[0], transform),
              CGPointApplyAffineTransform(_v[1], transform),
              CGPointApplyAffineTransform(_v[2], transform),
              CGPointApplyAffineTransform(_v[3], transform));
}

inline Quad Quad::transformedBy(GLKMatrix3 transform) const noexcept {
  GLKVector3 v0 = GLKMatrix3MultiplyVector3(transform, GLKVector3Make(_v[0].x, _v[0].y, 1));
  GLKVector3 v1 = GLKMatrix3MultiplyVector3(transform, GLKVector3Make(_v[1].x, _v[1].y, 1));
  GLKVector3 v2 = GLKMatrix3MultiplyVector3(transform, GLKVector3Make(_v[2].x, _v[2].y, 1));
  GLKVector3 v3 = GLKMatrix3MultiplyVector3(transform, GLKVector3Make(_v[3].x, _v[3].y, 1));
  return Quad(CGPointMake(v0.x / v0.z, v0.y / v0.z), CGPointMake(v1.x / v1.z, v1.y / v1.z),
              CGPointMake(v2.x / v2.z, v2.y / v2.z), CGPointMake(v3.x / v3.z, v3.y / v3.z));
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

/// Returns an \c NSString representation of the given \c quad. The returned \c NSString is
/// <tt>@"{{v0_x, v0_y}, {v1_x, v1_y}, {v2_x, v2_y}, {v3_x, v3_y}}"</tt>, where \c v<i>_x and
/// \c v<i>_y are the string representations of \c quad.v<i>().x and \c quad.v<i>().y, respectively,
/// for \c <i> in <tt>{0, 1, 2, 3}</tt>.
NSString *NSStringFromLTQuad(lt::Quad quad);

/// Returns an instance from the given \c string representation. Returns \c lt::Quad() if the given
/// \c string does not have the format
/// <tt>@"{{v0_x, v0_y}, {v1_x, v1_y}, {v2_x, v2_y}, {v3_x, v3_y}}"</tt>, where \c v<i>_x and
/// \c v<i>_y are the string representations of \c quad.v<i>().x and \c quad.v<i>().y, respectively,
/// for \c <i> in <tt>{0, 1, 2, 3}</tt>.
lt::Quad LTQuadFromString(NSString *string);

NS_ASSUME_NONNULL_END

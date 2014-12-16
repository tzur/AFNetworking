// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

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

typedef NS_ENUM(NSUInteger, LTQuadCornersValidity) {
  // Corners can be used for initializing a quad.
  LTQuadCornersValidityValid,
  // Corners can not be used for initializing a quad since they are given in counter-clockwise
  // order.
  LTQuadCornersValidityInvalidDueToOrder,
  // Corners can not be used for initializing a quad since all corners are collinear.
  LTQuadCornersValidityInvalidDueToCollinearity,
  // Corners can not be used for initializing a quad since at least two corners are too close to
  // each other.
  LTQuadCornersValidityInvalidDueToProximity
};

/// Represents a quadrilateral in the XY plane.
@interface LTQuad : NSObject <NSCopying>

/// Returns a rectangular quad defined by the given \c rect. Returns \c nil if the resulting quad
/// would be invalid (refer to \c LTQuadCornersValidity for more details).
+ (instancetype)quadFromRect:(CGRect)rect;

/// Returns a rectangular quad with the given \c origin and the given \c size. Returns \c nil if the
/// resulting quad would be invalid (refer to \c LTQuadCornersValidity for more details).
+ (instancetype)quadFromRectWithOrigin:(CGPoint)origin andSize:(CGSize)size;

/// Returns a rectangular rotated quad defined by the given \c rotatedRect. Returns \c nil if the
/// resulting quad would be invalid (refer to \c LTQuadCornersValidity for more details).
+ (instancetype)quadFromRotatedRect:(LTRotatedRect *)rotatedRect;

/// Returns a quad whose corners correspond to those of the given \c rect after transforming them
/// using the \c transform of the given \c quad. The given \c quad must not be \c nil. Returns
/// \c nil if the resulting quad would be invalid (refer to \c LTQuadCornersValidity for more
/// details).
+ (instancetype)quadFromRect:(CGRect)rect transformedByTransformOfQuad:(LTQuad *)quad;

/// Initializes a general quad defined by the given \c corners. In case of a simple (i.e.
/// non-self-intersecting) quad, the corners have to be provided in clockwise order. The provided
/// corners must valid (refer to \c LTQuadCornersValidity for more details). Checking whether
/// corners are valid for initialization can be done using the \c validityOfCorners: method.
- (instancetype)initWithCorners:(const LTQuadCorners &)corners;

/// Returns a value of \c LTQuadCornersValidity indicating the validity of the provided corners.
+ (LTQuadCornersValidity)validityOfCorners:(const LTQuadCorners &)corners;

/// Updates the corners of this instance using the given \c corners. The provided \c corners must be
/// valid.
- (void)updateWithCorners:(const LTQuadCorners &)corners;

/// Returns \c YES if the given \c point is contained by this quad.
- (BOOL)containsPoint:(CGPoint)point;

/// Rotates this instance by \c angle (which is provided in radians) in the XY plane around the
/// provided \c anchorPoint, in clockwise direction.
- (void)rotateByAngle:(CGFloat)angle aroundPoint:(CGPoint)anchorPoint;

/// Scales this instance by \c scaleFactor.
- (void)scale:(CGFloat)scaleFactor;

/// Scales this instance by \c scaleFactor around the provided \c anchorPoint.
- (void)scale:(CGFloat)scaleFactor aroundPoint:(CGPoint)anchorPoint;

/// Translates the specified \c corners by \c translation.
- (void)translateCorners:(LTQuadCornerRegion)corners
           byTranslation:(CGPoint)translation;

/// Returns the point on any edge of this quad which has the smallest distance to the given
/// \c point.
- (CGPoint)pointOnEdgeClosestToPoint:(CGPoint)point;

/// Returns YES if each corner of \c quad equals the corresponding corner of this instance, up to
/// the given \c deviation.
- (BOOL)isSimilarTo:(LTQuad *)quad upToDeviation:(CGFloat)deviation;

/// Returns YES if it is possible to transform this instance using translation, rotation and scaling
/// such that this instance's corners after the transformation coincide with the corners of the
/// given \c quad, up to the given deviation in distance. If the transformation is possible,
/// \c translation, \c scaling and \c rotation contain the appropriate values required for the
/// transformation (consisting of first translating, then rotating in clockwise order around quad
/// center and finally scaling). Otherwise, the values of \c translation, \c scaling and \c rotation
/// are undefined. \c translation, \c scaling and \c rotation must not be NULL.
- (BOOL)isTransformableToQuad:(LTQuad *)quad withDeviation:(CGFloat)deviation
                  translation:(CGPoint *)translation rotation:(CGFloat *)rotation
                      scaling:(CGFloat *)scaling;

/// First vertex of the quad.
@property (readonly, nonatomic) CGPoint v0;
/// Second vertex of the quad.
@property (readonly, nonatomic) CGPoint v1;
/// Third vertex of the quad.
@property (readonly, nonatomic) CGPoint v2;
/// Fourth vertex of the quad.
@property (readonly, nonatomic) CGPoint v3;

/// Rect that bounds the quad.
@property (readonly, nonatomic) CGRect boundingRect;

/// Center of this quad. The center is defined to be the average of the coordinates of the corner
/// points.
@property (readonly, nonatomic) CGPoint center;

/// Indicates whether this quad is convex.
@property (readonly, nonatomic) BOOL isConvex;

/// Indicates whether this quad is self-intersecting.
@property (readonly, nonatomic) BOOL isSelfIntersecting;

/// Transformation required to transform a rectangle with origin at (0, 0) and size (1, 1) such that
/// its projected corners coincide with the vertices of this quad.
@property (readonly, nonatomic) GLKMatrix3 transform;

/// Returns the length of the shortest edge of this \c quad.
@property (readonly, nonatomic) CGFloat minimalEdgeLength;

/// Returns the length of the longest edge of this \c quad.
@property (readonly, nonatomic) CGFloat maximalEdgeLength;

@end

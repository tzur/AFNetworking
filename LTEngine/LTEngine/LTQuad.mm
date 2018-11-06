// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuad.h"

#import "LTRotatedRect.h"
#import "LTTriangle.h"
#import "NSScanner+LTEngine.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTQuad () {
  /// Corners of this quad.
  lt::Quad _quad;
}

@end

@implementation LTQuad

static const CGFloat kEpsilon = 1e-10;

/// Returns the number of non-left turns in the polyline constituted by the given \c corners.
static NSUInteger LTNumberOfNonLeftTurns(const lt::Quad::Corners &corners);

#pragma mark -
#pragma mark Factory methods
#pragma mark -

+ (instancetype)quadWithVerticesOfQuad:(LTQuad *)quad {
  LTParameterAssert(quad);
  return [[[self class] alloc] initWithQuad:quad->_quad];
}

+ (instancetype)quadFromQuad:(const lt::Quad &)quad {
  return [[[self class] alloc] initWithQuad:quad];
}

+ (nullable instancetype)quadFromRect:(CGRect)rect {
  return [[self class] quadFromRectWithOrigin:rect.origin andSize:rect.size];
}

+ (nullable instancetype)quadFromRectWithOrigin:(CGPoint)origin andSize:(CGSize)size {
  CGPoint v0 = origin;
  CGPoint v1 = origin + CGPointMake(size.width, 0);
  CGPoint v2 = v1 + CGPointMake(0, size.height);
  CGPoint v3 = origin + CGPointMake(0, size.height);

  LTQuadCorners corners{{v0, v1, v2, v3}};
  return [[self class] safeQuadWithCorners:corners];
}

+ (nullable instancetype)quadFromRotatedRect:(LTRotatedRect *)rotatedRect {
  LTParameterAssert(rotatedRect);
  LTQuadCorners corners{{rotatedRect.v0, rotatedRect.v1, rotatedRect.v2, rotatedRect.v3}};
  return [[self class] safeQuadWithCorners:corners];
}

+ (nullable instancetype)quadFromRect:(CGRect)rect transformedByTransformOfQuad:(LTQuad *)quad {
  LTParameterAssert(quad);
  lt::Quad transformedQuad = quad->_quad.quadFromTransformedRect(rect);
  return [[self class] safeQuadWithCorners:transformedQuad.corners()];
}

+ (nullable instancetype)safeQuadWithCorners:(LTQuadCorners)corners {
  return [LTQuad validityOfCorners:corners] == LTQuadCornersValidityValid ?
      [[[self class] alloc] initWithCorners:corners] : nil;
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithCorners:(const LTQuadCorners &)corners {
  return [self initWithQuad:lt::Quad(corners)];
}

- (instancetype)initWithQuad:(const lt::Quad &)quad {
  if (self = [super init]) {
    [self updateWithQuad:quad];
  }
  return self;
}

+ (LTQuadCornersValidity)validityOfCorners:(const LTQuadCorners &)corners {
  // Ensure that the given corners are not too close to each other.
  if ([[self class] minimalDistanceOfPoints:corners] < kEpsilon) {
    return LTQuadCornersValidityInvalidDueToProximity;
  }

  lt::Quad quad(corners);

  if (quad.isNull()) {
    return LTQuadCornersValidityInvalidDueToNull;
  }

  // Ensure that the quad is not degenerate.
  if (quad.isDegenerate()) {
    return LTQuadCornersValidityInvalidDueToCollinearity;
  }

  // Ensure that the given corners are provided in clockwise order. Note that the notion of
  // clockwise/counterclockwise order is not well-defined for complex quadrilaterals due to the
  // self-intersection.
  if (!quad.isSelfIntersecting() && LTNumberOfNonLeftTurns(quad.corners()) < 2) {
    return LTQuadCornersValidityInvalidDueToOrder;
  }

  return LTQuadCornersValidityValid;
}

#pragma mark -
#pragma mark Copying
#pragma mark -

- (instancetype)copyWithCorners:(const LTQuadCorners &)corners {
  LTQuad *copy = [self copy];
  [copy updateWithQuad:lt::Quad(corners)];
  return copy;
}

- (nullable instancetype)safelyCopyWithQuad:(const lt::Quad &)quad {
  return [LTQuad validityOfCorners:quad.corners()] == LTQuadCornersValidityValid ?
      [self copyWithCorners:quad.corners()] : nil;
}

- (nullable instancetype)copyWithRotation:(CGFloat)angle aroundPoint:(CGPoint)anchorPoint {
  return [self safelyCopyWithQuad:_quad.rotatedAroundPoint(angle, anchorPoint)];
}

- (nullable instancetype)copyWithScaling:(CGFloat)scaleFactor {
  return [self copyWithScaling:scaleFactor aroundPoint:self.center];
}

- (nullable nullable instancetype)copyWithScaling:(CGFloat)scaleFactor
                                      aroundPoint:(CGPoint)anchorPoint {
  return [self safelyCopyWithQuad:_quad.scaledAround(scaleFactor, anchorPoint)];
}

- (nullable instancetype)copyWithTranslation:(CGPoint)translation
                                   ofCorners:(LTQuadCornerRegion)corners {
  return [self safelyCopyWithQuad:_quad.translatedBy(translation, corners)];
}

- (nullable instancetype)copyWithTranslation:(CGPoint)translation {
  return [self copyWithTranslation:translation ofCorners:LTQuadCornerRegionAll];
}

#pragma mark -
#pragma mark Updating
#pragma mark -

- (void)updateWithQuad:(const lt::Quad &)quad {
  LTQuadCorners corners({{quad.v0(), quad.v1(), quad.v2(), quad.v3()}});
  auto cornersValidity = [[self class] validityOfCorners:corners];
  LTParameterAssert(cornersValidity == LTQuadCornersValidityValid, @"Received invalid quad %@. "
                    "Validity state: %lu", NSStringFromLTQuad(quad),
                    (unsigned long)cornersValidity);
  _quad = quad;
}

#pragma mark -
#pragma mark Point inclusion
#pragma mark -

- (BOOL)containsPoint:(CGPoint)point {
  return _quad.containsPoint(point);
}

- (BOOL)containsVertexOfQuad:(LTQuad *)quad {
  return _quad.containsVertexOfQuad(quad->_quad);
}

#pragma mark -
#pragma mark Point location
#pragma mark -

- (CGPoint)pointOnEdgeClosestToPoint:(CGPoint)point {
  return _quad.pointOnEdgeClosestToPoint(point);
}

- (CGPointPair)nearestPoints:(LTQuad *)quad {
  return _quad.nearestPoints(quad->_quad);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGRect)boundingRect {
  return _quad.boundingRect();
}

- (std::vector<CGPoint>)convexHull {
  return _quad.convexHull();
}

- (CGPoint)center {
  return _quad.center();
}

- (BOOL)isConvex {
  return _quad.isConvex();
}

- (GLKMatrix3)transform {
  return _quad.transform();
}

- (CGFloat)minimalEdgeLength {
  return _quad.minimumEdgeLength();
}

- (CGFloat)maximalEdgeLength {
  return _quad.maximumEdgeLength();
}

#pragma mark -
#pragma mark Helper methods
#pragma mark -

+ (CGFloat)minimalDistanceOfPoints:(const LTQuadCorners &)points {
  NSUInteger size = points.size();
  std::vector<CGFloat> distances((size * (size - 1)) / 2);
  NSUInteger currentIndex = 0;
  for (NSUInteger i = 0; i < size; ++i) {
    for (NSUInteger j = 0; j < i; ++j) {
      if (i != j) {
        distances[currentIndex] = LTVector2(points[i] - points[j]).length();
      }
      ++currentIndex;
    }
  }
  return *std::min_element(distances.begin(), distances.end());
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (id)copyWithZone:(nullable NSZone *)zone {
  return [[[self class] allocWithZone:zone] initWithQuad:_quad];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, vertices: %@>", self.class, self,
          NSStringFromLTQuad(self.quad)];
}

- (BOOL)isEqual:(LTQuad *)quad {
  if (self == quad) {
    return YES;
  }

  if (![quad isKindOfClass:[self class]]) {
    return NO;
  }

  return _quad == quad->_quad;
}

- (NSUInteger)hash {
  return std::hash<lt::Quad>()(_quad);
}

- (BOOL)isSimilarTo:(LTQuad *)quad upToDeviation:(CGFloat)deviation {
  return _quad.isSimilarToQuadUpToDeviation(quad->_quad, deviation);
}

- (BOOL)isTransformableToQuad:(LTQuad *)quad withDeviation:(CGFloat)deviation
                  translation:(CGPoint *)translation rotation:(CGFloat *)rotation
                      scaling:(CGFloat *)scaling {
  LTParameterAssert(quad);
  LTParameterAssert(translation);
  LTParameterAssert(rotation);
  LTParameterAssert(scaling);
  return _quad.isTransformableToQuadWithDeviation(quad->_quad, deviation, translation, rotation,
                                                  scaling);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGFloat)area {
  return _quad.area();
}

- (LTQuadCorners)corners {
  return _quad.corners();
}

- (CGPoint)v0 {
  return _quad.v0();
}

- (CGPoint)v1 {
  return _quad.v1();
}

- (CGPoint)v2 {
  return _quad.v2();
}

- (CGPoint)v3 {
  return _quad.v3();
}

- (BOOL)isSelfIntersecting {
  return _quad.isSelfIntersecting();
}

@end

#pragma mark -
#pragma mark lt::Quad
#pragma mark -

static std::array<CGFloat, 4> LTEdgeLengthsOfQuad(const lt::Quad &quad) {
  return std::array<CGFloat, 4>{{LTVector2(quad.v0() - quad.v1()).length(),
    LTVector2(quad.v1() - quad.v2()).length(), LTVector2(quad.v2() - quad.v3()).length(),
    LTVector2(quad.v3() - quad.v0()).length()}};
}

/// Transformation required to transform a rectangle with origin at (0, 0) and size (1, 1) such that
/// its projected corners coincide with the given quad vertices \c v0, \c v1, \c v2, \c v3.
///
/// @see http://stackoverflow.com/questions/9470493/transforming-a-rectangle-image-into-a-quadrilateral-using-a-catransform3d/12820877#12820877
static GLKMatrix3 LTTransformationForQuad(CGPoint v0, CGPoint v1, CGPoint v2, CGPoint v3) {
  const CGRect rect = CGRectMake(0, 0, 1, 1);
  const CGFloat x1 = v0.x;
  const CGFloat y1 = v0.y;
  const CGFloat x2 = v1.x;
  const CGFloat y2 = v1.y;
  const CGFloat x3 = v2.x;
  const CGFloat y3 = v2.y;
  const CGFloat x4 = v3.x;
  const CGFloat y4 = v3.y;

  CGFloat X = rect.origin.x;
  CGFloat Y = rect.origin.y;
  CGFloat W = rect.size.width;
  CGFloat H = rect.size.height;

  CGFloat y21 = y2 - y1;
  CGFloat y32 = y4 - y2;
  CGFloat y43 = y3 - y4;
  CGFloat y14 = y1 - y3;
  CGFloat y31 = y4 - y1;
  CGFloat y42 = y3 - y2;

  CGFloat a = -H * (x2 * x4 * y14 + x2 * x3 * y31 - x1 * x3 * y32 + x1 * x4 * y42);
  CGFloat b = W * (x2 * x4 * y14 + x4 * x3 * y21 + x1 * x3 * y32 + x1 * x2 * y43);
  CGFloat c = H * X * (x2 * x4 * y14 + x2 * x3 * y31 - x1 * x3 * y32 + x1 * x4 * y42)
      - H * W * x1 * (x3 * y32 - x4 * y42 + x2 * y43)
      - W * Y * (x2 * x4 * y14 + x4 * x3 * y21 + x1 * x3 * y32 + x1 * x2 * y43);

  CGFloat d = H * (-x3 * y21 * y4 + x2 * y1 * y43 - x1 * y2 * y43 - x4 * y1 * y3 + x4 * y2 * y3);
  CGFloat e = W * (x3 * y2 * y31 - x4 * y1 * y42 - x2 * y31 * y3 + x1 * y4 * y42);
  CGFloat f = -(W * (x3 * (Y * y2 * y31 + H * y1 * y32)
                     - x4 * (H + Y) * y1 * y42 + H * x2 * y1 * y43 + x2 * Y * (y1 - y4) * y3
                     + x1 * Y * y4 * (-y2 + y3))
                - H * X * (x3 * y21 * y4 - x2 * y1 * y43 + x4 * (y1 - y2) * y3
                           + x1 * y2 * (-y4 + y3)));

  CGFloat g = H * (x4 * y21 - x3 * y21 + (-x1 + x2) * y43);
  CGFloat h = W * (-x2 * y31 + x3 * y31 + (x1 - x4) * y42);
  CGFloat i = W * Y * (x2 * y31 - x3 * y31 - x1 * y42 + x4 * y42)
      + H * (X * (-(x4 * y21) + x3 * y21 + x1 * y43 - x2 * y43)
             + W * (-(x4 * y2) + x3 * y2 + x2 * y4 - x3 * y4 - x2 * y3 + x4 * y3));

  if (std::abs(i) < kEpsilon) {
    i = kEpsilon * (i > 0 ? 1 : -1);
  }

  CGFloat iInv = 1 / i;

  return GLKMatrix3Make(a * iInv, b * iInv, c * iInv, d * iInv, e * iInv, f * iInv, g * iInv,
                        h * iInv, 1);
}

static NSUInteger LTIndexOfConcavePointInQuad(const lt::Quad &quad) {
  lt::Quad::Corners corners = quad.corners();

  for (NSUInteger i = 0; i < lt::Quad::kNumQuadCorners; i++) {
    CGPoint origin = corners[i];
    CGPoint direction = corners[(i + 1) % lt::Quad::kNumQuadCorners] - origin;
    if (LTPointLocationRelativeToRay(corners[(i + 2) % lt::Quad::kNumQuadCorners], origin,
                                     direction) == LTPointLocationLeftOfRay) {
      return (i + 1) % lt::Quad::kNumQuadCorners;
    }
  }
  return NSNotFound;
}

/// Returns \c YES if the given \c quad contains the given \c point, assuming that the \c quad is
/// convex.
static BOOL LTConvexQuadContainsPoint(const lt::Quad &quad, CGPoint point,
                                      LTPointLocation location) {
  lt::Quad::Corners corners = quad.corners();

  for (NSUInteger i = 0; i < lt::Quad::kNumQuadCorners; i++) {
    CGPoint origin = corners[i];
    CGPoint direction = corners[(i + 1) % lt::Quad::kNumQuadCorners] - origin;
    if (LTPointLocationRelativeToRay(point, origin, direction) == location) {
      return NO;
    }
  }
  return YES;
}

/// Returns \c YES if the given \c quad contains the given \c point, assuming that the \c quad is
/// simple and concave.
static BOOL LTSimpleConcaveQuadContainsPoint(const lt::Quad &quad, CGPoint point) {
  lt::Quad::Corners corners = quad.corners();
  NSUInteger indexOfConcavePoint = LTIndexOfConcavePointInQuad(quad);
  LTTriangleCorners corners0{{corners[indexOfConcavePoint],
    corners[(indexOfConcavePoint + 1) % lt::Quad::kNumQuadCorners],
    corners[(indexOfConcavePoint + 2) % lt::Quad::kNumQuadCorners]}};
  lt::Triangle triangle0 = lt::Triangle(corners0);
  LTTriangleCorners corners1{{corners[(indexOfConcavePoint + 2) % lt::Quad::kNumQuadCorners],
    corners[(indexOfConcavePoint + 3) % lt::Quad::kNumQuadCorners],
    corners[indexOfConcavePoint]}};
  lt::Triangle triangle1 = lt::Triangle(corners1);
  return triangle0.containsPoint(point) || triangle1.containsPoint(point);
}

/// Returns \c YES if the given \c quad contains the given \c point, assuming that the \c quad is
/// complex.
static BOOL LTComplexQuadContainsPoint(const lt::Quad &quad, CGPoint point) {
  // Compute intersection point.
  std::vector<CGPoint> pointsOfClosedPolyLine{quad.v0(), quad.v1(), quad.v2(), quad.v3(),
                                              quad.v0()};
  std::vector<CGPoint> intersectionPoints =
      LTComputeIntersectionPointsOfPolyLine(pointsOfClosedPolyLine);

  // Compute point inclusion using the two triangles of which the self-intersecting quad consists.
  lt::Triangle triangle0, triangle1;
  lt::Quad::Corners corners = quad.corners();

  if (LTPointsAreCollinear(std::vector<CGPoint>{corners[0], corners[1], intersectionPoints[0]})) {
    LTTriangleCorners corners0{{intersectionPoints[0], corners[1], corners[2]}};
    triangle0 = lt::Triangle(corners0);
    LTTriangleCorners corners1{{intersectionPoints[0], corners[3], corners[0]}};
    triangle1 = lt::Triangle(corners1);
  } else {
    LTTriangleCorners corners0{{intersectionPoints[0], corners[0], corners[1]}};
    triangle0 = lt::Triangle(corners0);
    LTTriangleCorners corners1{{intersectionPoints[0], corners[2], corners[3]}};
    triangle1 = lt::Triangle(corners1);
  }

  return triangle0.containsPoint(point) || triangle1.containsPoint(point);
}

static BOOL LTCornersOfNullQuad(const lt::Quad::Corners &corners) {
  for (CGPoint corner : corners) {
    if (CGPointIsNull(corner)) {
      return YES;
    }
  }
  return NO;
}

static std::vector<std::pair<NSUInteger, NSUInteger>>
    LTIndexPairsOfCoincidingPoints(const lt::Quad::Corners &corners) {
  std::vector<std::pair<NSUInteger, NSUInteger>> indexPairs;

  for (NSUInteger i = 0; i < lt::Quad::kNumQuadCorners; ++i) {
    for (NSUInteger j = i + 1; j < lt::Quad::kNumQuadCorners; ++j) {
      if (corners[i] == corners[j]) {
        indexPairs.emplace_back(i, j);
      }
    }
  }

  return indexPairs;
}

/// Returns the number of non-left turns of the given \c corners. A cyclic polyline constituting a
/// convex quad is \c 4 if its corners are in clockwise order and \c 0 if they are in
/// counterclockwise order. Analogously, the number of non-left turns of the cyclic polyline
/// constituting a concave quad is \c 3 if its corners are in clockwise order and \c 1 if they are
/// in counterclockwise order. The number of non-left turns of the cyclic polyline constituting a
/// complex quad always is \c 2.
static NSUInteger LTNumberOfNonLeftTurns(const lt::Quad::Corners &corners) {
  NSUInteger result = 0;
  for (NSUInteger i = 0; i < lt::Quad::kNumQuadCorners; i++) {
    CGPoint origin = corners[i];
    CGPoint direction = corners[(i + 1) % lt::Quad::kNumQuadCorners] - origin;
    if (LTPointLocationRelativeToRay(corners[(i + 2) % lt::Quad::kNumQuadCorners], origin,
                                     direction) !=
        LTPointLocationLeftOfRay) {
      result++;
    }
  }
  return result;
}

/// Quad representing the canonical square with origin <tt>(0, 0)</tt> and size <tt>(1, 1)</tt>.
static const lt::Quad kCanonicalSquareQuad = lt::Quad(CGRectMake(0, 0, 1, 1));

namespace lt {

#pragma mark -
#pragma mark Initialization
#pragma mark -

Quad Quad::canonicalSquare() noexcept {
  return kCanonicalSquareQuad;
}

#pragma mark -
#pragma mark Transformation
#pragma mark -

Quad Quad::rotatedAroundPoint(CGFloat angle, CGPoint anchorPoint) const noexcept {
  return Quad(
    LTRotatePoint(_v[0], angle, anchorPoint),
    LTRotatePoint(_v[1], angle, anchorPoint),
    LTRotatePoint(_v[2], angle, anchorPoint),
    LTRotatePoint(_v[3], angle, anchorPoint)
  );
}

Quad Quad::translatedBy(CGPoint translation, LTQuadCornerRegion group) const noexcept {
  Quad::Corners corners = this->corners();
  if (group & LTQuadCornerRegionV0) {
    corners[0] = corners[0] + translation;
  }
  if (group & LTQuadCornerRegionV1) {
    corners[1] = corners[1] + translation;
  }
  if (group & LTQuadCornerRegionV2) {
    corners[2] = corners[2] + translation;
  }
  if (group & LTQuadCornerRegionV3) {
    corners[3] = corners[3] + translation;
  }
  return Quad(corners);
}

Quad Quad::quadFromTransformedRect(CGRect rect) const noexcept {
  if (isNull()) {
    return *this;
  }

  GLKMatrix3 transform = GLKMatrix3Transpose(this->transform());
  GLKVector3 topLeft = GLKVector3Make(rect.origin.x, rect.origin.y, 1);
  GLKVector3 projectedTopLeft = GLKMatrix3MultiplyVector3(transform, topLeft);
  GLKVector3 projectedTopRight =
      GLKMatrix3MultiplyVector3(transform,
                                GLKVector3Add(topLeft, GLKVector3Make(rect.size.width, 0, 0)));
  GLKVector3 projectedBottomRight =
      GLKMatrix3MultiplyVector3(transform,
                                GLKVector3Add(topLeft, GLKVector3Make(rect.size.width,
                                                                      rect.size.height, 0)));
  GLKVector3 projectedBottomLeft =
      GLKMatrix3MultiplyVector3(transform,
                                GLKVector3Add(topLeft, GLKVector3Make(0, rect.size.height, 0)));
  return Quad(
    CGPointMake(projectedTopLeft.x, projectedTopLeft.y) / projectedTopLeft.z,
    CGPointMake(projectedTopRight.x, projectedTopRight.y) / projectedTopRight.z,
    CGPointMake(projectedBottomRight.x, projectedBottomRight.y) / projectedBottomRight.z,
    CGPointMake(projectedBottomLeft.x, projectedBottomLeft.y) / projectedBottomLeft.z
  );
}

BOOL Quad::isTransformableToQuadWithDeviation(Quad quad, CGFloat deviation, CGPoint *translation,
                                              CGFloat *rotation, CGFloat *scaling) const noexcept {
  CGPoint translationResult = quad.center() - center();
  Quad centeredQuad = translatedBy(translationResult);

  Quad::Corners corners = quad.corners();

  for (const CGPoint &corner : corners) {
    CGFloat rotationResult = LTVector2(centeredQuad._v[0] - centeredQuad.center())
        .angle(LTVector2(corner - quad.center()));
    Quad rotatedQuad = centeredQuad.rotatedAroundPoint(rotationResult, centeredQuad.center());
    CGFloat scalingResult = LTVector2(corner - rotatedQuad.center()).length() /
        LTVector2(rotatedQuad._v[0] - rotatedQuad.center()).length();
    Quad scaledQuad = rotatedQuad.scaledBy(scalingResult);
    if (scaledQuad.isSimilarToQuadUpToDeviation(quad, deviation)) {
      *translation = translationResult;
      *rotation = rotationResult;
      *scaling = scalingResult;
      return YES;
    }
  }
  return NO;
}

#pragma mark -
#pragma mark Point inclusion
#pragma mark -

BOOL Quad::containsPoint(CGPoint point) const noexcept {
  switch (type()) {
    case Quad::Type::Null:
    case Quad::Type::Degenerate:
      return NO;
    case Quad::Type::Triangle: {
      NSUInteger index = LTIndexPairsOfCoincidingPoints(_v).front().second;
      Triangle triangle(_v[index], _v[(index + 1) % kNumQuadCorners],
                        _v[(index + 2) % kNumQuadCorners]);
      return triangle.containsPoint(point);
    }
    case Quad::Type::ConvexClockwise:
      return LTConvexQuadContainsPoint(*this, point, LTPointLocationLeftOfRay);
    case Quad::Type::ConvexCounterClockwise:
      return LTConvexQuadContainsPoint(*this, point, LTPointLocationRightOfRay);
    case Quad::Type::ConcaveClockwise:
    case Quad::Type::ConcaveCounterClockwise:
      return LTSimpleConcaveQuadContainsPoint(*this, point);
    case Quad::Type::Complex:
      return LTComplexQuadContainsPoint(*this, point);
  }
}

#pragma mark -
#pragma mark Point location
#pragma mark -

CGPoint Quad::pointOnEdgeClosestToPoint(CGPoint point) const noexcept {
  Quad::Corners corners = this->corners();
  CGPoint closestPoint = CGPointNull;
  CGFloat minimalDistance = CGFLOAT_MAX;
  for (NSUInteger i = 0; i < kNumQuadCorners; ++i) {
    CGPoint pointOnLine =
        LTPointOnEdgeClosestToPoint(corners[i], corners[(i + 1) % kNumQuadCorners], point);
    CGFloat distance = LTVector2(pointOnLine - point).length();
    if (distance < minimalDistance) {
      minimalDistance = distance;
      closestPoint = pointOnLine;
    }
  }
  return closestPoint;
}

CGPointPair Quad::nearestPoints(Quad quad) const noexcept {
  std::vector<CGPoint> polyline0{{_v[0], _v[1], _v[2], _v[3], _v[0]}};
  std::vector<CGPoint> polyline1{{quad.v0(), quad.v1(), quad.v2(), quad.v3(), quad.v0()}};
  return LTPointOnPolylineNearestToPointOnPolyline(polyline0, polyline1);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

CGFloat Quad::area() const noexcept {
  switch (type()) {
    case Quad::Type::Null:
      return NAN;
    case Quad::Type::Degenerate:
      return 0;
    case Quad::Type::Triangle: {
      NSUInteger index = LTIndexPairsOfCoincidingPoints(_v).front().second;
      Triangle triangle(_v[index], _v[(index + 1) % kNumQuadCorners],
                            _v[(index + 2) % kNumQuadCorners]);
      return triangle.area();
    }
    case Quad::Type::ConvexClockwise:
    case Quad::Type::ConvexCounterClockwise:
      return Triangle(_v[0], _v[1], _v[2]).area() + Triangle(_v[2], _v[3], _v[0]).area();
    case Quad::Type::ConcaveClockwise:
    case Quad::Type::ConcaveCounterClockwise: {
      NSUInteger indexOfConcavePoint = LTIndexOfConcavePointInQuad(*this);
      return Triangle(_v[indexOfConcavePoint], _v[(indexOfConcavePoint + 1) % kNumQuadCorners],
                      _v[(indexOfConcavePoint + 2) % kNumQuadCorners]).area() +
          Triangle(_v[(indexOfConcavePoint + 2) % kNumQuadCorners],
                   _v[(indexOfConcavePoint + 3) % kNumQuadCorners], _v[indexOfConcavePoint]).area();
    }
    case Quad::Type::Complex: {
      std::vector<CGPoint> pointsOfClosedPolyLine{_v[0], _v[1], _v[2], _v[3], _v[0]};
      std::vector<CGPoint> intersectionPoints =
          LTComputeIntersectionPointsOfPolyLine(pointsOfClosedPolyLine);
      return Triangle(_v[0], _v[1], intersectionPoints.front()).area() +
          Triangle(_v[2], _v[3], intersectionPoints.front()).area();
    }
  }
}

CGRect Quad::boundingRect() const noexcept {
  CGFloat minX = std::min(_v[0].x, std::min(_v[1].x, std::min(_v[2].x, _v[3].x)));
  CGFloat maxX = std::max(_v[0].x, std::max(_v[1].x, std::max(_v[2].x, _v[3].x)));
  CGFloat minY = std::min(_v[0].y, std::min(_v[1].y, std::min(_v[2].y, _v[3].y)));
  CGFloat maxY = std::max(_v[0].y, std::max(_v[1].y, std::max(_v[2].y, _v[3].y)));
  return CGRectFromEdges(minX, minY, maxX, maxY);
}

CGFloat Quad::minimumEdgeLength() const noexcept {
  std::array<CGFloat, 4> lengths = LTEdgeLengthsOfQuad(*this);
  return *std::min_element(lengths.begin(), lengths.end());
}

CGFloat Quad::maximumEdgeLength() const noexcept {
  std::array<CGFloat, 4> lengths = LTEdgeLengthsOfQuad(*this);
  return *std::max_element(lengths.begin(), lengths.end());
}

GLKMatrix3 Quad::transform() const noexcept {
  return LTTransformationForQuad(v0(), v1(), v2(), v3());
}

Quad::Type Quad::type() const noexcept {
  if (_quadType) {
    return *_quadType;
  }

  std::vector<std::pair<NSUInteger, NSUInteger>> indexPairsOfCoincidingPoints =
      LTIndexPairsOfCoincidingPoints(_v);

  if (LTCornersOfNullQuad(_v)) {
    _quadType = Quad::Type::Null;
  } else if (indexPairsOfCoincidingPoints.size()) {
    if (indexPairsOfCoincidingPoints.size() == 1 &&
        indexPairsOfCoincidingPoints[0].first + 1 == indexPairsOfCoincidingPoints[0].second) {
      _quadType = Quad::Type::Triangle;
    } else {
      _quadType = Quad::Type::Degenerate;
    }
  } else if (LTPointsAreCollinear({_v[0], _v[1], _v[2], _v[3]})) {
      _quadType = Quad::Type::Degenerate;
  } else {
    switch (LTNumberOfNonLeftTurns(_v)) {
      case 0:
        _quadType = Quad::Type::ConvexCounterClockwise;
        break;
      case 1:
        _quadType = Quad::Type::ConcaveCounterClockwise;
        break;
      case 2:
        _quadType = Quad::Type::Complex;
        break;
      case 3:
        _quadType = Quad::Type::ConcaveClockwise;
        break;
      case 4:
        _quadType = Quad::Type::ConvexClockwise;
        break;
      default:
        LTAssert(NO, @"Incorrect number of non-left turns returned");
    }
  }

  return *_quadType;
}

} // namespace lt

NSString *NSStringFromLTQuad(lt::Quad quad) {
  return [NSString stringWithFormat:@"{{%g, %g}, {%g, %g}, {%g, %g}, {%g, %g}}",
          quad.v0().x, quad.v0().y, quad.v1().x, quad.v1().y, quad.v2().x, quad.v2().y,
          quad.v3().x, quad.v3().y];
}

static CGPoint LTQuadVertexFromScanner(NSScanner *scanner, BOOL scanComma) {
  float x, y;
  if (![scanner scanString:@"{" intoString:nil]) return CGPointNull;
  if (![scanner lt_scanFloat:&x]) return CGPointNull;
  if (![scanner scanString:@"," intoString:nil]) return CGPointNull;
  if (![scanner lt_scanFloat:&y]) return CGPointNull;
  if (![scanner scanString:@"}" intoString:nil]) return CGPointNull;
  if (scanComma) {
    if (![scanner scanString:@"," intoString:nil]) return CGPointNull;
  }
  return CGPointMake(x, y);
}

lt::Quad LTQuadFromString(NSString *string) {
  NSScanner *scanner = [NSScanner scannerWithString:string];
  CGPoint v0, v1, v2, v3;
  if (![scanner scanString:@"{" intoString:nil]) return lt::Quad();

  v0 = LTQuadVertexFromScanner(scanner, YES);
  if (CGPointIsNull(v0)) return lt::Quad();

  v1 = LTQuadVertexFromScanner(scanner, YES);
  if (CGPointIsNull(v1)) return lt::Quad();

  v2 = LTQuadVertexFromScanner(scanner, YES);
  if (CGPointIsNull(v2)) return lt::Quad();

  v3 = LTQuadVertexFromScanner(scanner, NO);
  if (CGPointIsNull(v3)) return lt::Quad();

  if (![scanner scanString:@"}" intoString:nil]) return lt::Quad();
  if (![scanner isAtEnd]) return lt::Quad();
  return lt::Quad(v0, v1, v2, v3);
}

NS_ASSUME_NONNULL_END

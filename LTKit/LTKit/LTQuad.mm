// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuad.h"

#import "LTTriangle.h"
#import "LTRotatedRect.h"

typedef union {
  NSUInteger intValue;
  CGFloat floatValue;
} LTQuadHashHelperStruct;

@interface LTQuad ()

/// The corners of this quad.
@property (nonatomic) LTQuadCorners corners;

@end

@implementation LTQuad

static const CGFloat kEpsilon = 1e-10;

#pragma mark -
#pragma mark Factory methods
#pragma mark -

+ (instancetype)quadWithVerticesOfQuad:(LTQuad *)quad {
  LTParameterAssert(quad);
  return [((LTQuad *)[[self class] alloc]) initWithCorners:{{quad.v0, quad.v1, quad.v2, quad.v3}}];
}

+ (instancetype)quadFromRect:(CGRect)rect {
  return [[self class] quadFromRectWithOrigin:rect.origin andSize:rect.size];
}

+ (instancetype)quadFromRectWithOrigin:(CGPoint)origin andSize:(CGSize)size {
  CGPoint v0 = origin;
  CGPoint v1 = origin + CGPointMake(size.width, 0);
  CGPoint v2 = v1 + CGPointMake(0, size.height);
  CGPoint v3 = origin + CGPointMake(0, size.height);

  LTQuadCorners corners{{v0, v1, v2, v3}};
  return [[self class] safeQuadWithCorners:corners];
}

+ (instancetype)quadFromRotatedRect:(LTRotatedRect *)rotatedRect {
  LTParameterAssert(rotatedRect);
  LTQuadCorners corners{{rotatedRect.v0, rotatedRect.v1, rotatedRect.v2, rotatedRect.v3}};
  return [[self class] safeQuadWithCorners:corners];
}

+ (instancetype)quadFromRect:(CGRect)rect transformedByTransformOfQuad:(LTQuad *)quad {
  LTParameterAssert(!CGRectIsNull(rect));
  LTParameterAssert(quad);
  GLKMatrix3 transform = GLKMatrix3Transpose(quad.transform);
  GLKVector3 topLeft = GLKVector3Make(rect.origin.x, rect.origin.y, 1);
  GLKVector3 projectedTopLeft = GLKMatrix3MultiplyVector3(transform, topLeft);
  GLKVector3 projectedTopRight =
      GLKMatrix3MultiplyVector3(transform, GLKVector3Add(topLeft,
                                                         GLKVector3Make(rect.size.width, 0, 0)));
  GLKVector3 projectedBottomRight =
      GLKMatrix3MultiplyVector3(transform, GLKVector3Add(topLeft,
                                                         GLKVector3Make(rect.size.width,
                                                                        rect.size.height, 0)));
  GLKVector3 projectedBottomLeft =
      GLKMatrix3MultiplyVector3(transform, GLKVector3Add(topLeft,
                                                         GLKVector3Make(0, rect.size.height, 0)));
  LTQuadCorners corners{{
    CGPointMake(projectedTopLeft.x, projectedTopLeft.y) / projectedTopLeft.z,
    CGPointMake(projectedTopRight.x, projectedTopRight.y) / projectedTopRight.z,
    CGPointMake(projectedBottomRight.x, projectedBottomRight.y) / projectedBottomRight.z,
    CGPointMake(projectedBottomLeft.x, projectedBottomLeft.y) / projectedBottomLeft.z,
  }};

  return [[self class] safeQuadWithCorners:corners];
}

+ (instancetype)safeQuadWithCorners:(LTQuadCorners)corners {
  return [LTQuad validityOfCorners:corners] == LTQuadCornersValidityValid ?
      [(LTQuad *)[[self class] alloc] initWithCorners:corners] : nil;
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithCorners:(const LTQuadCorners &)corners {
  if (self = [super init]) {
    [self updateWithCorners:corners];
  }
  return self;
}

+ (LTQuadCornersValidity)validityOfCorners:(const LTQuadCorners &)corners {
  // Ensure that the given corners are not too close to each other.
  if ([[self class] minimalDistanceOfPoints:corners] < kEpsilon) {
    return LTQuadCornersValidityInvalidDueToProximity;
  }

  // Ensure that the given corners are provided in clockwise order. The number of non-left turns
  // of the cyclic polyline constituting a convex quad is 4 if its corners are in clockwise order
  // and 0 if they are in counterclockwise order. Analogously, the number of non-left turns of the
  // cyclic polyline constituting a concave quad is 3 if its corners are in clockwise order and 1
  // if they are in counterclockwise order. The number of non-left turns of the cyclic polyline
  // constituting a complex quad always is 2. The notion of clockwise/counterclockwise order is
  // not well-defined for complex quadrilaterals due to the self-intersection.
  if ([[self class] numberOfNonLeftTurns:corners] < 2) {
    return LTQuadCornersValidityInvalidDueToOrder;
  }

  // Ensure that at least one corner is not collinear with the other corners.
  if ([[self class] onlyCollinearPoints:corners]) {
    return LTQuadCornersValidityInvalidDueToCollinearity;
  }

  return LTQuadCornersValidityValid;
}

#pragma mark -
#pragma mark Copying
#pragma mark -

- (instancetype)copyWithCorners:(const LTQuadCorners &)corners {
  LTQuad *copy = [self copy];
  [copy updateWithCorners:corners];
  return copy;
}

#pragma mark -
#pragma mark Updating
#pragma mark -

- (void)updateWithCorners:(const LTQuadCorners &)corners {
  LTParameterAssert([[self class] validityOfCorners:corners] == LTQuadCornersValidityValid,
                    @"Invalid corners provided.");
  self.corners = corners;
}

#pragma mark -
#pragma mark Point inclusion
#pragma mark -

- (BOOL)containsPoint:(CGPoint)point {
  if ([self isConvex]) {
    return [self convexQuadContainsPoint:point];
  } else {
    // Quad is convave.
    if (self.isSelfIntersecting) {
      return [self complexQuadContainsPoint:point];
    } else {
      // Quad is concave, but not self-intersecting.
      return [self simpleConcaveQuadContainsPoint:point];
    }
  }
}

/// Assuming that this instance is convex, checks whether the given \c point is contained by this
/// instance. Throws an exception if the instance is not convex.
- (BOOL)convexQuadContainsPoint:(const CGPoint)point {
  LTAssert([self isConvex], @"Method call is illegal for concave quadrilaterals.");
  NSUInteger size = self.corners.size();
  for (NSUInteger i = 0; i < size; i++) {
    CGPoint origin = self.corners[i];
    CGPoint direction = self.corners[(i + 1) % size] - origin;
    if (LTPointLocationRelativeToRay(point, origin, direction) == LTPointLocationLeftOfRay) {
      return NO;
    }
  }
  return YES;
}

/// Assuming that this instance is simple and concave, checks whether the given \c point is
/// contained by this instance. Throws an exception if the instance is not simple and concave.
- (BOOL)simpleConcaveQuadContainsPoint:(const CGPoint)point {
  LTAssert(![self isConvex], @"Method call is illegal for convex quadrilaterals.");
  LTAssert(![self isSelfIntersecting], @"Method call is illegal for complex quadrilaterals.");

  const NSUInteger kNumCorners = self.corners.size();

  NSUInteger indexOfConcavePoint = [self indexOfConcavePoint];
  LTTriangleCorners corners0{{self.corners[indexOfConcavePoint],
      self.corners[(indexOfConcavePoint + 1) % kNumCorners],
      self.corners[(indexOfConcavePoint + 2) % kNumCorners]}};
  LTTriangle *triangle0 = [[LTTriangle alloc] initWithCorners:corners0];
  LTTriangleCorners corners1{{self.corners[(indexOfConcavePoint + 2) % kNumCorners],
      self.corners[(indexOfConcavePoint + 3) % kNumCorners],
      self.corners[indexOfConcavePoint]}};
  LTTriangle *triangle1 = [[LTTriangle alloc] initWithCorners:corners1];
  return [triangle0 containsPoint:point] || [triangle1 containsPoint:point];
}

/// Returns the index of the uniquely determined point truly inside the convex hull of this
/// quadrilateral, provided that it is simple and concave. Throws an assertion if this instance is
/// convex or complex.
- (NSUInteger)indexOfConcavePoint {
  LTAssert(!self.isSelfIntersecting, @"Quadrilateral is complex.");
  NSUInteger size = self.corners.size();
  for (NSUInteger i = 0; i < size; i++) {
    CGPoint origin = self.corners[i];
    CGPoint direction = self.corners[(i + 1) % size] - origin;
    if (LTPointLocationRelativeToRay(self.corners[(i + 2) % size], origin, direction) ==
        LTPointLocationLeftOfRay) {
      return (i + 1) % size;
    }
  }
  LTAssert(NO, @"Quadrilateral is not concave.");
  return NSNotFound;
}

/// Assuming that this instance is complex (and hence concave), checks whether the given \c point is
/// contained by this instance. Throws an exception if the instance is not complex.
- (BOOL)complexQuadContainsPoint:(const CGPoint)point {
  LTAssert([self isSelfIntersecting], @"Method call is illegal for simple quadrilaterals.");

  // Compute intersection point.
  CGPoints pointsOfClosedPolyLine{self.corners[0], self.corners[1], self.corners[2],
                                  self.corners[3], self.corners[0]};
  CGPoints intersectionPoints = LTComputeIntersectionPointsOfPolyLine(pointsOfClosedPolyLine);
  LTAssert(intersectionPoints.size() == 1, @"Quadrilaterals can self-intersect at most once.");

  // Compute point inclusion using the two triangles of which the self-intersecting quad consists.
  LTTriangle *triangle0, *triangle1;
  if (LTPointsAreCollinear(CGPoints{self.corners[0], self.corners[1], intersectionPoints[0]})) {
    LTTriangleCorners corners0{{intersectionPoints[0], self.corners[1], self.corners[2]}};
    triangle0 = [[LTTriangle alloc] initWithCorners:corners0];
    LTTriangleCorners corners1{{intersectionPoints[0], self.corners[3], self.corners[0]}};
    triangle1 = [[LTTriangle alloc] initWithCorners:corners1];
  } else {
    LTTriangleCorners corners0{{intersectionPoints[0], self.corners[0], self.corners[1]}};
    triangle0 = [[LTTriangle alloc] initWithCorners:corners0];
    LTTriangleCorners corners1{{intersectionPoints[0], self.corners[2], self.corners[3]}};
    triangle1 = [[LTTriangle alloc] initWithCorners:corners1];
  }

  return [triangle0 containsPoint:point] || [triangle1 containsPoint:point];
}

- (BOOL)containsVertexOfQuad:(LTQuad *)quad {
  return ([self containsPoint:quad.v0] || [self containsPoint:quad.v1] ||
          [self containsPoint:quad.v2] || [self containsPoint:quad.v3]);
}

#pragma mark -
#pragma mark Affine transformations
#pragma mark -

- (void)rotateByAngle:(CGFloat)angle aroundPoint:(CGPoint)anchorPoint {
  for (CGPoint &corner : _corners) {
    corner = LTRotatePoint(corner, angle, anchorPoint);
  }
}

- (void)scale:(CGFloat)scaleFactor {
  CGPoint currentCenter = self.center;
  for (CGPoint &corner : _corners) {
    corner = currentCenter + scaleFactor * (corner - currentCenter);
  }
}

- (void)scale:(CGFloat)scaleFactor aroundPoint:(CGPoint)anchorPoint {
  for (CGPoint &corner : _corners) {
    corner = anchorPoint + scaleFactor * (corner - anchorPoint);
  }
}

- (void)translateCorners:(LTQuadCornerRegion)corners
           byTranslation:(CGPoint)translation {
  LTQuadCorners translatedCorners = self.corners;
  if (corners & LTQuadCornerRegionV0) {
    translatedCorners[0] = translatedCorners[0] + translation;
  }
  if (corners & LTQuadCornerRegionV1) {
    translatedCorners[1] = translatedCorners[1] + translation;
  }
  if (corners & LTQuadCornerRegionV2) {
    translatedCorners[2] = translatedCorners[2] + translation;
  }
  if (corners & LTQuadCornerRegionV3) {
    translatedCorners[3] = translatedCorners[3] + translation;
  }
  self.corners = translatedCorners;
}

#pragma mark -
#pragma mark Point location
#pragma mark -

- (CGPoint)pointOnEdgeClosestToPoint:(CGPoint)point {
  NSUInteger size = self.corners.size();
  CGPoint closestPoint = CGPointNull;
  CGFloat minimalDistance = CGFLOAT_MAX;
  for (NSUInteger i = 0; i < size; ++i) {
    CGPoint pointOnLine =
        LTPointOnEdgeClosestToPoint(self.corners[i], self.corners[(i + 1) % size], point);
    CGFloat distance = LTVector2(pointOnLine - point).length();
    if (distance < minimalDistance) {
      minimalDistance = distance;
      closestPoint = pointOnLine;
    }
  }
  return closestPoint;
}

- (CGPointPair)nearestPoints:(LTQuad *)quad {
  CGPoints polyline0{{self.v0, self.v1, self.v2, self.v3, self.v0}};
  CGPoints polyline1{{quad.v0, quad.v1, quad.v2, quad.v3, quad.v0}};

  return LTPointOnPolylineNearestToPointOnPolyline(polyline0, polyline1);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGRect)boundingRect {
  CGFloat minX = std::min(self.v0.x, std::min(self.v1.x, std::min(self.v2.x, self.v3.x)));
  CGFloat maxX = std::max(self.v0.x, std::max(self.v1.x, std::max(self.v2.x, self.v3.x)));
  CGFloat minY = std::min(self.v0.y, std::min(self.v1.y, std::min(self.v2.y, self.v3.y)));
  CGFloat maxY = std::max(self.v0.y, std::max(self.v1.y, std::max(self.v2.y, self.v3.y)));

  return CGRectFromEdges(minX, minY, maxX, maxY);
}

- (CGPoint)center {
  return (self.v0 + self.v1 + self.v2 + self.v3) / 4;
}

- (BOOL)isConvex {
  NSUInteger size = self.corners.size();
  for (NSUInteger i = 0; i < size; i++) {
    CGPoint origin = self.corners[i];
    CGPoint direction = self.corners[(i + 1) % size] - origin;
    if (LTPointLocationRelativeToRay(self.corners[(i + 2) % size], origin, direction) ==
        LTPointLocationLeftOfRay) {
      return NO;
    }
  }
  return YES;
}

- (GLKMatrix3)transform {
  return [[self class] rectToQuad:CGRectMake(0, 0, 1, 1)
                      quadTopLeft:self.v0
                     quadTopRight:self.v1
                  quadBottomRight:self.v2
                   quadBottomLeft:self.v3];
}

- (CGFloat)minimalEdgeLength {
  std::array<CGFloat, 4> lengths = self.edgeLengths;
  return *std::min_element(lengths.begin(), lengths.end());
}

- (CGFloat)maximalEdgeLength {
  std::array<CGFloat, 4> lengths = self.edgeLengths;
  return *std::max_element(lengths.begin(), lengths.end());
}

- (std::array<CGFloat, 4>)edgeLengths {
  return std::array<CGFloat, 4>{{LTVector2(self.v0 - self.v1).length(),
      LTVector2(self.v1 - self.v2).length(), LTVector2(self.v2 - self.v3).length(),
      LTVector2(self.v3 - self.v0).length()}};
}

#pragma mark -
#pragma mark Helper methods
#pragma mark -

/// @see http://stackoverflow.com/questions/9470493/transforming-a-rectangle-image-into-a-quadrilateral-using-a-catransform3d/12820877#12820877
+ (GLKMatrix3)rectToQuad:(CGRect)rect
             quadTopLeft:(CGPoint)topLeft
            quadTopRight:(CGPoint)topRight
         quadBottomRight:(CGPoint)bottomRight
          quadBottomLeft:(CGPoint)bottomLeft {
  cv::Mat1f sourceMatrix = [self matWithQuad:[LTQuad quadFromRect:rect]];

  LTQuadCorners corners{{topLeft, topRight, bottomRight, bottomLeft}};
  cv::Mat destinationMatrix = [self matWithQuad:[[LTQuad alloc] initWithCorners:corners]];

  cv::Mat1f homography = cv::findHomography(sourceMatrix, destinationMatrix);

  return GLKMatrix3MakeWithArray((float *)homography.data);
}

+ (cv::Mat1f)matWithQuad:(LTQuad *)quad {
  cv::Mat1f result(4, 2);

  result(0, 0) = quad.v0.x;
  result(0, 1) = quad.v0.y;
  result(1, 0) = quad.v1.x;
  result(1, 1) = quad.v1.y;
  result(2, 0) = quad.v2.x;
  result(2, 1) = quad.v2.y;
  result(3, 0) = quad.v3.x;
  result(3, 1) = quad.v3.y;

  return result;
}

+ (NSUInteger)numberOfNonLeftTurns:(const LTQuadCorners &)points {
  NSUInteger result = 0;
  NSUInteger size = points.size();
  for (NSUInteger i = 0; i < size; i++) {
    CGPoint origin = points[i];
    CGPoint direction = points[(i + 1) % size] - origin;
    if (LTPointLocationRelativeToRay(points[(i + 2) % size], origin, direction) !=
        LTPointLocationLeftOfRay) {
      result++;
    }
  }
  return result;
}

+ (NSUInteger)onlyCollinearPoints:(const LTQuadCorners &)points {
  NSUInteger result = 0;
  NSUInteger size = points.size();
  for (NSUInteger i = 0; i < size; i++) {
    CGPoint origin = points[i];
    CGPoint direction = points[(i + 1) % size] - origin;
    if (LTPointLocationRelativeToRay(points[(i + 2) % size], origin, direction) ==
        LTPointLocationOnLineThroughRay) {
      result++;
    }
  }
  return result == points.size();
}

+ (CGFloat)minimalDistanceOfPoints:(const LTQuadCorners &)points {
  NSUInteger size = points.size();
  CGFloats distances((size * (size - 1)) / 2);
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

- (id)copyWithZone:(NSZone *)zone {
  return [((LTQuad *)[[self class] allocWithZone:zone]) initWithCorners:self.corners];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"v0 = (%g, %g), v1 = (%g, %g), v2 = (%g, %g), v3 = (%g, %g)",
          self.v0.x, self.v0.y, self.v1.x, self.v1.y, self.v2.x, self.v2.y, self.v3.x, self.v3.y];
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if ([object isKindOfClass:[self class]]) {
    LTQuad *quad = object;
    return self.v0 == quad.v0 && self.v1 == quad.v1 && self.v2 == quad.v2 && self.v3 == quad.v3;
  }

  return NO;
}

- (NSUInteger)hash {
  NSUInteger result = 0;
  LTQuadHashHelperStruct converter;
  for (const CGPoint &corner : self.corners) {
    converter.floatValue = corner.x;
    result ^= converter.intValue;
    converter.floatValue = corner.y;
    result ^= converter.intValue;
  }
  return result;
}

- (BOOL)isSimilarTo:(LTQuad *)quad upToDeviation:(CGFloat)deviation {
  return CGPointDistance(self.v0, quad.v0) <= deviation &&
      CGPointDistance(self.v1, quad.v1) <= deviation &&
      CGPointDistance(self.v2, quad.v2) <= deviation &&
      CGPointDistance(self.v3, quad.v3) <= deviation;
}

- (BOOL)isTransformableToQuad:(LTQuad *)quad withDeviation:(CGFloat)deviation
                  translation:(CGPoint *)translation rotation:(CGFloat *)rotation
                      scaling:(CGFloat *)scaling {
  LTParameterAssert(quad);
  LTParameterAssert(translation);
  LTParameterAssert(rotation);
  LTParameterAssert(scaling);
  *translation = quad.center - self.center;
  LTQuad *centeredQuad = [self copy];
  [centeredQuad translateCorners:LTQuadCornerRegionAll byTranslation:*translation];

  for (const CGPoint &corner : quad.corners) {
    *rotation =
        LTVector2(centeredQuad.v0 - centeredQuad.center).angle(LTVector2(corner - quad.center));
    LTQuad *rotatedQuad = [centeredQuad copy];
    [rotatedQuad rotateByAngle:*rotation aroundPoint:rotatedQuad.center];
    *scaling = LTVector2(corner - rotatedQuad.center).length() /
        LTVector2(rotatedQuad.v0 - rotatedQuad.center).length();
    [rotatedQuad scale:*scaling];
    if ([rotatedQuad isSimilarTo:quad upToDeviation:deviation]) {
      return YES;
    }
  }
  return NO;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGPoint)v0 {
  return self.corners[0];
}

- (CGPoint)v1 {
  return self.corners[1];
}

- (CGPoint)v2 {
  return self.corners[2];
}

- (CGPoint)v3 {
  return self.corners[3];
}

- (BOOL)isSelfIntersecting {
  CGPoints pointsOfClosedPolyLine{self.corners[0], self.corners[1], self.corners[2],
                                  self.corners[3], self.corners[0]};
  return LTIsSelfIntersectingPolyline(pointsOfClosedPolyLine);
}

@end

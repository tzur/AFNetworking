// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuadrilateral.h"

#import "LTGeometry.h"
#import "LTTriangle.h"

@interface LTQuadrilateral ()

@property (nonatomic) LTQuadrilateralCorners corners;

@end

@implementation LTQuadrilateral

#pragma mark -
#pragma mark Factory methods
#pragma mark -

+ (instancetype)quadrilateralFromRect:(CGRect)rect {
  return [[self class] quadrilateralFromRectWithOrigin:rect.origin andSize:rect.size];
}

+ (instancetype)quadrilateralFromRectWithOrigin:(CGPoint)origin andSize:(CGSize)size {
  CGPoint v0 = origin;
  CGPoint v1 = origin + CGPointMake(size.width, 0);
  CGPoint v2 = v1 + CGPointMake(0, size.height);
  CGPoint v3 = origin + CGPointMake(0, size.height);

  LTQuadrilateralCorners corners{{v0, v1, v2, v3}};
  return [[LTQuadrilateral alloc] initWithCorners:corners];
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithCorners:(const LTQuadrilateralCorners &)corners {
  if (self = [super init]) {
    // Ensure that the given corners are provided in clockwise order. The number of non-left turns
    // of the cyclic polyline constituting a convex quad is 4 if its corners are in clockwise order
    // and 0 if they are in counterclockwise order. Analogously, the number of non-left turns of the
    // cyclic polyline constituting a concave quad is 3 if its corners are in clockwise order and 1
    // if they are in counterclockwise order. The number of non-left turns of the cyclic polyline
    // constituting a complex quad always is 2. The notion of clockwise/counterclockwise order is
    // not well-defined for complex quadrilaterals due to the self-intersection.
    NSUInteger numberOfNonLeftTurns = [[self class] numberOfNonLeftTurns:corners];
    LTAssert(numberOfNonLeftTurns != 0,
             @"Quadrilateral is convex, but corners are given in counterclockwise direction.");
    LTAssert(numberOfNonLeftTurns != 1,
             @"Quadrilateral is concave, but corners are given in counterclockwise direction.");
    self.corners = corners;
  }
  return self;
}

#pragma mark -
#pragma mark Point inclusion
#pragma mark -

- (BOOL)containsPoint:(CGPoint)point {
  if ([self isConvex]) {
    return [self convexQuadrilateralContainsPoint:point];
  } else {
    // Quadrilateral is convave.
    if (self.isSelfIntersecting) {
      return [self complexQuadrilateralContainsPoint:point];
    } else {
      // Quadrilateral is concave, but not self-intersecting.
      return [self simpleConcaveQuadrilateralContainsPoint:point];
    }
  }
}

/// Assuming that this instance is convex, checks whether the given \c point is contained by this
/// instance. Throws an exception if the instance is not convex.
- (BOOL)convexQuadrilateralContainsPoint:(const CGPoint)point {
  LTAssert([self isConvex], @"Method call is illegal for concave quadrilaterals.");
  NSUInteger size = self.corners.size();
  for (NSUInteger i = 0; i < size; i++) {
    CGPoint origin = self.corners[i];
    CGPoint direction = CGPointFromSize(self.corners[(i + 1) % size] - origin);
    if (LTPointLocationRelativeToRay(point, origin, direction) == LTPointLocationLeftOfRay) {
      return NO;
    }
  }
  return YES;
}

/// Assuming that this instance is simple and concave, checks whether the given \c point is
/// contained by this instance. Throws an exception if the instance is not simple and concave.
- (BOOL)simpleConcaveQuadrilateralContainsPoint:(const CGPoint)point {
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
    CGPoint direction = CGPointFromSize(self.corners[(i + 1) % size] - origin);
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
- (BOOL)complexQuadrilateralContainsPoint:(const CGPoint)point {
  LTAssert([self isSelfIntersecting], @"Method call is illegal for simple quadrilaterals.");

  // Compute intersection point.
  CGPoints pointsOfClosedPolyLine{self.corners[0], self.corners[1], self.corners[2],
                                  self.corners[3], self.corners[0]};
  CGPoints intersectionPoints = LTComputeIntersectionPointsOfPolyLine(pointsOfClosedPolyLine);
  LTAssert(intersectionPoints.size() == 1, @"Quadrilaterals can self-intersect at most once.");

  // Compute point inclusion using the two triangles of which the self-intersecting quadrilateral
  // consists.
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

- (void)translate:(CGPoint)translation {
  for (CGPoint &corner : _corners) {
    corner = corner + translation;
  }
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
    CGPoint direction = CGPointFromSize(self.corners[(i + 1) % size] - origin);
    if (LTPointLocationRelativeToRay(self.corners[(i + 2) % size], origin, direction) ==
        LTPointLocationLeftOfRay) {
      return NO;
    }
  }
  return YES;
}

- (CATransform3D)transform {
  return [[self class] rectToQuad:CGRectMake(0, 0, 1, 1)
                      quadTopLeft:self.v0
                     quadTopRight:self.v1
                  quadBottomRight:self.v2
                   quadBottomLeft:self.v3];
}

#pragma mark -
#pragma mark Helper methods
#pragma mark -

/// @see http://stackoverflow.com/questions/9470493/transforming-a-rectangle-image-into-a-quadrilateral-using-a-catransform3d/12820877#12820877
+ (CATransform3D)rectToQuad:(CGRect)rect
                quadTopLeft:(CGPoint)topLeft
               quadTopRight:(CGPoint)topRight
            quadBottomRight:(CGPoint)bottomRight
             quadBottomLeft:(CGPoint)bottomLeft {
  cv::Mat1f sourceMatrix = [self matWithQuadrilateral:[LTQuadrilateral quadrilateralFromRect:rect]];

  LTQuadrilateralCorners corners{{topLeft, topRight, bottomRight, bottomLeft}};
  cv::Mat destinationMatrix = [self matWithQuadrilateral:[[LTQuadrilateral alloc]
                                                          initWithCorners:corners]];

  cv::Mat1f homography = cv::findHomography(sourceMatrix, destinationMatrix);

  return [self transform3DFromMat:homography];
}

+ (cv::Mat1f)matWithQuadrilateral:(LTQuadrilateral *)quad {
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

+ (CATransform3D)transform3DFromMat:(cv::Mat1f)mat {
  LTParameterAssert(mat.rows == 3 && mat.cols == 3);
  CATransform3D transform = CATransform3DIdentity;

  transform.m11 = mat(0, 0);
  transform.m21 = mat(0, 1);
  transform.m41 = mat(0, 2);

  transform.m12 = mat(1, 0);
  transform.m22 = mat(1, 1);
  transform.m42 = mat(1, 2);

  transform.m14 = mat(2, 0);
  transform.m24 = mat(2, 1);
  transform.m44 = mat(2, 2);

  return transform;
}

+ (NSUInteger)numberOfNonLeftTurns:(const LTQuadrilateralCorners &)points {
  NSUInteger result = 0;
  NSUInteger size = points.size();
  for (NSUInteger i = 0; i < size; i++) {
    CGPoint origin = points[i];
    CGPoint direction = CGPointFromSize(points[(i + 1) % size] - origin);
    if (LTPointLocationRelativeToRay(points[(i + 2) % size], origin, direction) !=
        LTPointLocationLeftOfRay) {
      result++;
    }
  }
  return result;
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

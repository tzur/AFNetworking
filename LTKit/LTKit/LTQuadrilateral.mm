// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuadrilateral.h"

#import "LTGeometry.h"

@interface LTQuadrilateral ()

@property (readwrite, nonatomic) CGPoint v0;
@property (readwrite, nonatomic) CGPoint v1;
@property (readwrite, nonatomic) CGPoint v2;
@property (readwrite, nonatomic) CGPoint v3;

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

  return [[[self class] alloc] initWithCorners:corners];
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithCorners:(const LTQuadrilateralCorners &)corners {
  if (self = [super init]) {
    self.v0 = corners[0];
    self.v1 = corners[1];
    self.v2 = corners[2];
    self.v3 = corners[3];
  }
  return self;
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

- (BOOL)isConvex {
  return LTPointLiesOnRightSideOfRay(self.v2, self.v0, self.v1)
      && LTPointLiesOnRightSideOfRay(self.v3, self.v1, self.v2)
      && LTPointLiesOnRightSideOfRay(self.v0, self.v2, self.v3)
      && LTPointLiesOnRightSideOfRay(self.v1, self.v3, self.v0);
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

// For more details see stackoverflow:
// http://stackoverflow.com/questions/9470493/transforming-a-rectangle-image-into-a-quadrilateral-using-a-catransform3d/12820877#12820877

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

@end

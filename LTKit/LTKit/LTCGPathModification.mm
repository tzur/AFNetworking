// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCGPathModification.h"

/// Structure wrapping the data required for computing the modified path.
typedef struct LTPathModificationData {
  CGMutablePathRef path;
  GLKMatrix3 transform;
} LTPathModificationData;

/// Adds the provided \c element to the path wrapped in the given \c data, after multiplying the
/// points of the \c element with the transform wrapped in the given \c data.
static void recomputePoints(void *data, const CGPathElement *element);

/// Returns the result of multiplying the provided \c point with the provided \c transform.
static CGPoint CGPointApplyTransform(CGPoint point, GLKMatrix3 &transform);

CGMutablePathRef LTCGPathApplyTransform(CGPathRef path, GLKMatrix3 &transform) {
  CGMutablePathRef result = CGPathCreateMutable();

  LTPathModificationData data;
  data.path = result;
  data.transform = transform;

  CGPathApply(path, &data, &recomputePoints);
  return result;
}

void recomputePoints(void *data, const CGPathElement *element) {
  LTPathModificationData *modificationData = (LTPathModificationData *)data;

  CGMutablePathRef path = modificationData->path;
  GLKMatrix3 transform = modificationData->transform;

  CGPoint *points = element->points;

  switch (element->type) {
    case kCGPathElementMoveToPoint:
      points[0] = CGPointApplyTransform(points[0], transform);
      CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
      break;
    case kCGPathElementAddLineToPoint:
      points[0] = CGPointApplyTransform(points[0], transform);
      CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
      break;
    case kCGPathElementAddQuadCurveToPoint:
      points[0] = CGPointApplyTransform(points[0], transform);
      points[1] = CGPointApplyTransform(points[1], transform);
      CGPathAddQuadCurveToPoint(path, NULL, points[0].x, points[0].y,
                                points[1].x, points[1].y);
      break;
    case kCGPathElementAddCurveToPoint:
      points[0] = CGPointApplyTransform(points[0], transform);
      points[1] = CGPointApplyTransform(points[1], transform);
      points[2] = CGPointApplyTransform(points[2], transform);
      CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                            points[1].x, points[1].y,
                            points[2].x, points[2].y);
      break;
    case kCGPathElementCloseSubpath:
      CGPathCloseSubpath(path);
      break;
    default:
      LTAssert(NO, @"Invalid element type.");
  }
}

static CGPoint CGPointApplyTransform(CGPoint point, GLKMatrix3 &transform) {
  GLKVector3 vector = GLKVector3Make(point.x, point.y, 1);
  vector = GLKMatrix3MultiplyVector3(transform, vector);
  return CGPointMake(vector.x / vector.z, vector.y / vector.z);
}

// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCGPathModification.h"

#import "LTGLKitExtensions.h"

typedef struct PointsStruct {
  CGPoints points;
  NSUInteger currentlyCheckedPoint;
  BOOL failure;
} PointsStruct;

static const CGFloat kEpsilon = 1e-6;

static void checkCorrectnessOfTransformation(void *data, const CGPathElement *element) {
  PointsStruct *expectedPoints = (PointsStruct *)data;

  CGPoint *points = element->points;

  switch (element->type) {
    case kCGPathElementMoveToPoint:
    case kCGPathElementAddLineToPoint:
      if (CGPointDistance(points[0], expectedPoints->points[expectedPoints->currentlyCheckedPoint])
          > kEpsilon) {
        expectedPoints->failure = YES;
        return;
      }
      break;
    default:
      return;
  }

  expectedPoints->currentlyCheckedPoint++;
}

SpecBegin(LTCGPathModification)

__block CGMutablePathRef path;
__block CGPoints initialPoints;

beforeEach(^{
  path = CGPathCreateMutable();
  initialPoints = CGPoints{CGPointZero, CGPointMake(1, 1), CGPointMake(2, 0)};
  CGPathMoveToPoint(path, nil, initialPoints[0].x, initialPoints[0].y);
  CGPathAddLineToPoint(path, nil, initialPoints[1].x, initialPoints[1].y);
  CGPathAddLineToPoint(path, nil, initialPoints[2].x, initialPoints[2].y);
});

afterEach(^{
  CGPathRelease(path);
});

context(@"transformation", ^{
  __block CGMutablePathRef transformedPath;
  __block PointsStruct expectedPoints;

  it(@"should correctly compute a translated path", ^{
    CGPoint translation = CGPointMake(1, 2);
    GLKMatrix3 matrix = GLKMatrix3MakeTranslation(translation.x, translation.y);
    transformedPath = LTCGPathApplyTransform(path, matrix);

    expectedPoints.points = CGPoints{initialPoints[0] + translation, initialPoints[1] + translation,
      initialPoints[2] + translation};
    expectedPoints.currentlyCheckedPoint = 0;
    expectedPoints.failure = NO;
    CGPathApply(transformedPath, &expectedPoints, &checkCorrectnessOfTransformation);
    expect(expectedPoints.failure).to.beFalsy();
  });

  it(@"should correctly compute a rotated path", ^{
    // In iOS, negative values mean clockwise rotation, while positive values in OSX.
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    const CGFloat kClockwiseAngle = -M_PI / 2;
#else
    const CGFloat kClockwiseAngle = M_PI / 2;
#endif

    GLKMatrix3 matrix = GLKMatrix3MakeRotation(kClockwiseAngle, 0, 0, 1);

    transformedPath = LTCGPathApplyTransform(path, matrix);

    expectedPoints.points = CGPoints{CGPointZero, CGPointMake(1, -1), CGPointMake(0, -2)};
    expectedPoints.currentlyCheckedPoint = 0;
    expectedPoints.failure = NO;
    CGPathApply(transformedPath, &expectedPoints, &checkCorrectnessOfTransformation);
    expect(expectedPoints.failure).to.beFalsy();
  });
});

SpecEnd

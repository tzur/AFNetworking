// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCGPathExtensions.h"

#import "LTGLKitExtensions.h"

typedef struct EvaluationStruct {
  CGPoints points;
  NSUInteger numberOfPoints;
  NSUInteger numberOfPointsToExpect;
  NSUInteger numberOfClosedSubPaths;
  NSUInteger numberOfClosedSubPathsToExpect;
  BOOL failure;
} EvaluationStruct;

static const CGFloat kEpsilon = 1e-6;

static BOOL LTAreDifferent(CGPoint p, CGPoint q) {
  return CGPointDistance(p, q) > kEpsilon;
}

static void LTCheckCorrectnessOfPath(void *data, const CGPathElement *element) {
  EvaluationStruct *evaluation = (EvaluationStruct *)data;

  if (evaluation->numberOfPoints > evaluation->numberOfPointsToExpect ||
      evaluation->numberOfClosedSubPaths > evaluation->numberOfClosedSubPathsToExpect) {
    evaluation->failure = YES;
    return;
  }

  CGPoint *points = element->points;

  switch (element->type) {
    case kCGPathElementMoveToPoint:
    case kCGPathElementAddLineToPoint:
      evaluation->failure |=
          LTAreDifferent(points[0], evaluation->points[(evaluation->numberOfPoints)++]);
      break;
    case kCGPathElementAddQuadCurveToPoint:
      evaluation->failure |=
          LTAreDifferent(points[0], evaluation->points[(evaluation->numberOfPoints)++]);
      evaluation->failure |=
          LTAreDifferent(points[1], evaluation->points[(evaluation->numberOfPoints)++]);
      break;
    case kCGPathElementAddCurveToPoint:
      evaluation->failure |=
          LTAreDifferent(points[0], evaluation->points[(evaluation->numberOfPoints)++]);
      evaluation->failure |=
          LTAreDifferent(points[1], evaluation->points[(evaluation->numberOfPoints)++]);
      evaluation->failure |=
          LTAreDifferent(points[2], evaluation->points[(evaluation->numberOfPoints)++]);
      break;
    case kCGPathElementCloseSubpath:
      (evaluation->numberOfClosedSubPaths)++;
      break;
    default:
      return;
  }
}

SpecBegin(LTCGPathExtensions)

__block CGMutablePathRef path;
__block CGPoints initialPoints;
__block EvaluationStruct evaluation;

beforeEach(^{
  path = CGPathCreateMutable();
  initialPoints = CGPoints{CGPointZero, CGPointMake(1, 1), CGPointMake(2, 0)};
  CGPathMoveToPoint(path, nil, initialPoints[0].x, initialPoints[0].y);
  CGPathAddLineToPoint(path, nil, initialPoints[1].x, initialPoints[1].y);
  CGPathAddLineToPoint(path, nil, initialPoints[2].x, initialPoints[2].y);
  evaluation.points.clear();
  evaluation.numberOfPoints = 0;
  evaluation.numberOfClosedSubPaths = 0;
  evaluation.numberOfPointsToExpect = 0;
  evaluation.numberOfClosedSubPathsToExpect = 0;
  evaluation.failure = NO;
});

afterEach(^{
  CGPathRelease(path);
});

context(@"transformation", ^{
  __block CGPathRef transformedPath;

  it(@"should correctly compute a translated path", ^{
    CGPoint translation = CGPointMake(1, 2);
    GLKMatrix3 matrix = GLKMatrix3MakeTranslation(translation.x, translation.y);
    transformedPath = LTCGPathCreateCopyByTransformingPath(path, matrix);

    evaluation.points = CGPoints{initialPoints[0] + translation, initialPoints[1] + translation,
        initialPoints[2] + translation};
    evaluation.numberOfPointsToExpect = evaluation.points.size();
    CGPathApply(transformedPath, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
    CGPathRelease(transformedPath);
  });

  it(@"should correctly compute a rotated path", ^{
    // In iOS, negative values mean clockwise rotation, while positive values in OSX.
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    const CGFloat kClockwiseAngle = -M_PI / 2;
#else
    const CGFloat kClockwiseAngle = M_PI / 2;
#endif

    GLKMatrix3 matrix = GLKMatrix3MakeRotation(kClockwiseAngle, 0, 0, 1);

    transformedPath = LTCGPathCreateCopyByTransformingPath(path, matrix);

    evaluation.points = CGPoints{CGPointZero, CGPointMake(1, -1), CGPointMake(0, -2)};
    evaluation.numberOfPointsToExpect = evaluation.points.size();
    CGPathApply(transformedPath, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
    CGPathRelease(transformedPath);
  });
});

static const BOOL kClosed = YES;

context(@"creation", ^{
  __block CGFloat smootheningRadius;

  it(@"should compute the correct path of an acyclic unsmoothened polyline", ^{
    CGPoints points{CGPointMake(0, 0), CGPointMake(1, 0), CGPointMake(1, 1)};
    std::vector<LTVector2> inputData{LTVector2(points[0]), LTVector2(points[1]),
        LTVector2(points[2])};
    smootheningRadius = 0;
    path = LTCGPathCreateWithControlPoints(inputData, smootheningRadius, !kClosed);

    evaluation.points = points;
    evaluation.numberOfPointsToExpect = points.size();
    CGPathApply(path, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
  });

  it(@"should compute the correct path of a cyclic unsmoothened polyline", ^{
    CGPoints points{CGPointMake(0, 0), CGPointMake(1, 0), CGPointMake(1, 1), CGPointMake(2, 3)};
    std::vector<LTVector2> inputData{LTVector2(points[0]), LTVector2(points[1]),
        LTVector2(points[2]), LTVector2(points[3])};
    smootheningRadius = 0;
    path = LTCGPathCreateWithControlPoints(inputData, smootheningRadius, kClosed);

    evaluation.points = points;
    evaluation.numberOfPointsToExpect = points.size();
    evaluation.numberOfClosedSubPathsToExpect = 1;
    CGPathApply(path, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
  });

  it(@"should compute the correct path of an acyclic smoothened polyline", ^{
    CGPoints points{CGPointMake(0, 0), CGPointMake(0.75, 0), CGPointMake(1, 0),
        CGPointMake(1 + M_SQRT1_2 * 0.25, M_SQRT1_2 * 0.25), CGPointMake(2, 1)};
    std::vector<LTVector2> inputData{LTVector2(points[0]), LTVector2(points[2]),
        LTVector2(points[4])};
    smootheningRadius = 0.25;
    path = LTCGPathCreateWithControlPoints(inputData, smootheningRadius, !kClosed);

    evaluation.points = points;
    evaluation.numberOfPointsToExpect = points.size();
    evaluation.numberOfClosedSubPathsToExpect = 0;
    CGPathApply(path, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
  });

  it(@"should compute the correct path of an cyclic smoothened polyline", ^{
    CGPoints points{CGPointMake(0.25, 0), CGPointMake(1.75, 0), CGPointMake(2, 0),
        CGPointMake(2, 0.25), CGPointMake(2, 1.85), CGPointMake(2, 1.9), CGPointMake(2, 1.95),
        CGPointMake(2, 1.95), CGPointMake(2, 2),
        CGPointMake(2 - M_SQRT1_2 * 0.05, 2 - M_SQRT1_2 * 0.05),
        CGPointMake(M_SQRT1_2 * 0.25, M_SQRT1_2 * 0.25), CGPointMake(0, 0),
        CGPointMake(0.25, 0)};
    std::vector<LTVector2> inputData{LTVector2(points[11]), LTVector2(points[2]),
        LTVector2(points[5]), LTVector2(points[8])};
    smootheningRadius = 0.25;
    path = LTCGPathCreateWithControlPoints(inputData, smootheningRadius, kClosed);

    evaluation.points = points;
    evaluation.numberOfPointsToExpect = points.size();
    evaluation.numberOfClosedSubPathsToExpect = 1;
    CGPathApply(path, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
  });
});

SpecEnd

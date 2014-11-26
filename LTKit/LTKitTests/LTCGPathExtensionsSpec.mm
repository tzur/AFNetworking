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
  initialPoints = {CGPointZero, CGPointMake(1, 1), CGPointMake(2, 0)};
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

  it(@"should correctly create a translated copy of a path", ^{
    CGPoint translation = CGPointMake(1, 2);
    GLKMatrix3 matrix = GLKMatrix3MakeTranslation(translation.x, translation.y);
    transformedPath = LTCGPathCreateCopyByTransformingPath(path, matrix);

    evaluation.points = {initialPoints[0] + translation, initialPoints[1] + translation,
        initialPoints[2] + translation};
    evaluation.numberOfPointsToExpect = evaluation.points.size();
    CGPathApply(transformedPath, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
    CGPathRelease(transformedPath);
  });

  it(@"should correctly create a rotated copy of a path", ^{
    // In iOS, negative values mean clockwise rotation, while positive values in OSX.
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    const CGFloat kClockwiseAngle = -M_PI / 2;
#else
    const CGFloat kClockwiseAngle = M_PI / 2;
#endif

    GLKMatrix3 matrix = GLKMatrix3MakeRotation(kClockwiseAngle, 0, 0, 1);

    transformedPath = LTCGPathCreateCopyByTransformingPath(path, matrix);

    evaluation.points = {CGPointZero, CGPointMake(1, -1), CGPointMake(0, -2)};
    evaluation.numberOfPointsToExpect = evaluation.points.size();
    CGPathApply(transformedPath, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
    CGPathRelease(transformedPath);
  });

  it(@"should correctly create a copy of a path in a given rect", ^{
    CGPathRef originalPath = CGPathCreateWithEllipseInRect(CGRectMake(1, 2, 3, 4), NULL);
    CGPathRef expectedTransformedPath = CGPathCreateWithEllipseInRect(CGRectMake(2, 3, 4, 5), NULL);
    CGPathRef actualTransformedPath =
        LTCGPathCreateCopyInRect(originalPath, CGRectMake(2, 3, 4, 5));
    expect(CGPathEqualToPath(expectedTransformedPath, actualTransformedPath)).to.beTruthy();
    CGPathRelease(originalPath);
    CGPathRelease(expectedTransformedPath);
    CGPathRelease(actualTransformedPath);
  });
});

static const BOOL kClosed = YES;

context(@"creation", ^{
  __block CGFloat smootheningRadius;
  __block CGFloat gapSize;

  it(@"should correctly create a path for a given acyclic unsmoothened polyline", ^{
    CGPoints points{CGPointMake(0, 0), CGPointMake(1, 0), CGPointMake(1, 1)};
    LTVector2s inputData{LTVector2(points[0]), LTVector2(points[1]), LTVector2(points[2])};
    smootheningRadius = 0;
    CGPathRelease(path);
    path = LTCGPathCreateWithControlPoints(inputData, smootheningRadius, !kClosed);

    evaluation.points = points;
    evaluation.numberOfPointsToExpect = points.size();
    CGPathApply(path, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
  });

  it(@"should correctly create a path for a given cyclic unsmoothened polyline", ^{
    CGPoints points{CGPointMake(0, 0), CGPointMake(1, 0), CGPointMake(1, 1), CGPointMake(2, 3)};
    LTVector2s inputData{LTVector2(points[0]), LTVector2(points[1]), LTVector2(points[2]),
        LTVector2(points[3])};
    smootheningRadius = 0;
    CGPathRelease(path);
    path = LTCGPathCreateWithControlPoints(inputData, smootheningRadius, kClosed);

    evaluation.points = points;
    evaluation.numberOfPointsToExpect = points.size();
    evaluation.numberOfClosedSubPathsToExpect = 1;
    CGPathApply(path, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
  });

  it(@"should correctly create a path for a given acyclic smoothened polyline", ^{
    CGPoints points{CGPointMake(0, 0), CGPointMake(0.75, 0), CGPointMake(1, 0),
        CGPointMake(1 + M_SQRT1_2 * 0.25, M_SQRT1_2 * 0.25), CGPointMake(2, 1)};
    LTVector2s inputData{LTVector2(points[0]), LTVector2(points[2]), LTVector2(points[4])};
    smootheningRadius = 0.25;
    CGPathRelease(path);
    path = LTCGPathCreateWithControlPoints(inputData, smootheningRadius, !kClosed);

    evaluation.points = points;
    evaluation.numberOfPointsToExpect = points.size();
    evaluation.numberOfClosedSubPathsToExpect = 0;
    CGPathApply(path, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
  });

  it(@"should correctly create a path for a given cyclic smoothened polyline", ^{
    CGPoints points{CGPointMake(0.25, 0), CGPointMake(1.75, 0), CGPointMake(2, 0),
        CGPointMake(2, 0.25), CGPointMake(2, 1.85), CGPointMake(2, 1.9), CGPointMake(2, 1.95),
        CGPointMake(2, 1.95), CGPointMake(2, 2),
        CGPointMake(2 - M_SQRT1_2 * 0.05, 2 - M_SQRT1_2 * 0.05),
        CGPointMake(M_SQRT1_2 * 0.25, M_SQRT1_2 * 0.25), CGPointMake(0, 0),
        CGPointMake(0.25, 0)};
    LTVector2s inputData{LTVector2(points[11]), LTVector2(points[2]), LTVector2(points[5]),
        LTVector2(points[8])};
    smootheningRadius = 0.25;
    CGPathRelease(path);
    path = LTCGPathCreateWithControlPoints(inputData, smootheningRadius, kClosed);

    evaluation.points = points;
    evaluation.numberOfPointsToExpect = points.size();
    evaluation.numberOfClosedSubPathsToExpect = 1;
    CGPathApply(path, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
  });

  it(@"should correctly create a closed path with gaps", ^{
    CGPoints points{CGPointMake(0.25, 0), CGPointMake(1.75, 0), CGPointMake(2, 0.25),
        CGPointMake(2, 1.65), CGPointMake(2 - M_SQRT1_2 * 0.25, 2 - M_SQRT1_2 * 0.25),
        CGPointMake(M_SQRT1_2 * 0.25, M_SQRT1_2 * 0.25)};
    LTVector2s inputData{LTVector2Zero, LTVector2(2, 0), LTVector2(2, 1.9), LTVector2(2, 2)};
    gapSize = 0.25;
    CGPathRef immutablePath =
        LTCGPathCreateWithControlPointsAndGapsAroundVertices(inputData, gapSize, kClosed);

    evaluation.points = points;
    evaluation.numberOfPointsToExpect = points.size();
    evaluation.numberOfClosedSubPathsToExpect = 3;
    CGPathApply(immutablePath, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
    CGPathRelease(immutablePath);
  });

  it(@"should correctly create an open path with gaps", ^{
    CGPoints points{CGPointMake(1.25, 0), CGPointMake(1.75, 0), CGPointMake(2, 0.25),
        CGPointMake(2, 1.75), CGPointMake(2 - M_SQRT1_2 * 0.25, 2 - M_SQRT1_2 * 0.25),
        CGPointMake(M_SQRT1_2 * 0.25, M_SQRT1_2 * 0.25)};
    LTVector2s inputData{LTVector2(1, 0), LTVector2(2, 0), LTVector2(2, 2),
        LTVector2Zero};
    gapSize = 0.25;
    CGPathRef immutablePath =
        LTCGPathCreateWithControlPointsAndGapsAroundVertices(inputData, gapSize, !kClosed);

    evaluation.points = points;
    evaluation.numberOfPointsToExpect = points.size();
    evaluation.numberOfClosedSubPathsToExpect = 3;
    CGPathApply(immutablePath, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
    CGPathRelease(immutablePath);
  });

  it(@"should correctly create a path for a circular sector", ^{
    const CGFloat controlPointCoordinate = 0.5522847;

    CGPoints points{CGPointZero, CGPointMake(1, 0), CGPointMake(1, -controlPointCoordinate),
        CGPointMake(controlPointCoordinate, -1), CGPointMake(0, -1),
        CGPointMake(-controlPointCoordinate, -1), CGPointMake(-1, -controlPointCoordinate),
        CGPointMake(-1, 0)};

    CGPathRef circularSectorPath = LTCGPathCreateWithCircularSector(LTVector2Zero, 1, 0, M_PI, YES);
    evaluation.points = points;
    evaluation.numberOfPointsToExpect = points.size();
    evaluation.numberOfClosedSubPathsToExpect = 1;
    CGPathApply(circularSectorPath, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
    CGPathRelease(circularSectorPath);

    evaluation.points.clear();
    evaluation.numberOfPoints = 0;
    evaluation.numberOfClosedSubPaths = 0;

    points = CGPoints{CGPointZero, CGPointMake(0, 1), CGPointMake(0.26521644, 1),
        CGPointMake(0.51957041, 0.894643127), CGPointMake(M_SQRT1_2, M_SQRT1_2)};

    circularSectorPath = LTCGPathCreateWithCircularSector(LTVector2Zero, 1, M_PI_2, M_PI_4, YES);
    evaluation.points = points;
    evaluation.numberOfPointsToExpect = points.size();
    evaluation.numberOfClosedSubPathsToExpect = 1;
    CGPathApply(circularSectorPath, &evaluation, &LTCheckCorrectnessOfPath);
    expect(evaluation.failure).to.beFalsy();
    expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
    expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
    CGPathRelease(circularSectorPath);
  });

  context(@"string to path conversion", ^{
    __block CGFloat advancementFactor;
    __block CGFloat lineHeightFactor;
    __block CGPoints pointsForSingleL;
    __block CGPoints pointsForDoubleL;
    __block CGPoints pointsForTripleL;
    __block CGPoints pointsForTripleLWithLineHeightFactor;

    beforeAll(^{
      pointsForSingleL = {CGPointZero, CGPointMake(0.9716796875, 0),
        CGPointMake(0.9716796875, 6.318359375), CGPointMake(4.6044921875, 6.318359375),
        CGPointMake(4.6044921875, 7.1728515625), CGPointMake(0, 7.1728515625)
      };

      advancementFactor = 2;

      CGPoint horizontalTranslation = CGPointMake(5.5615234375 * advancementFactor, 0);

      pointsForDoubleL = {pointsForSingleL[0], pointsForSingleL[1], pointsForSingleL[2],
        pointsForSingleL[3], pointsForSingleL[4], pointsForSingleL[5],
        pointsForSingleL[0] + horizontalTranslation, pointsForSingleL[1] + horizontalTranslation,
        pointsForSingleL[2] + horizontalTranslation, pointsForSingleL[3] + horizontalTranslation,
        pointsForSingleL[4] + horizontalTranslation, pointsForSingleL[5] + horizontalTranslation
      };

      CGPoint verticalTranslation0 = CGPointMake(0, 10);
      CGPoint verticalTranslation1 = CGPointMake(0, 20);

      pointsForTripleL = {pointsForSingleL[0], pointsForSingleL[1], pointsForSingleL[2],
        pointsForSingleL[3], pointsForSingleL[4], pointsForSingleL[5],
        pointsForSingleL[0] + verticalTranslation0, pointsForSingleL[1] + verticalTranslation0,
        pointsForSingleL[2] + verticalTranslation0, pointsForSingleL[3] + verticalTranslation0,
        pointsForSingleL[4] + verticalTranslation0, pointsForSingleL[5] + verticalTranslation0,
        pointsForSingleL[0] + verticalTranslation1, pointsForSingleL[1] + verticalTranslation1,
        pointsForSingleL[2] + verticalTranslation1, pointsForSingleL[3] + verticalTranslation1,
        pointsForSingleL[4] + verticalTranslation1, pointsForSingleL[5] + verticalTranslation1
      };

      lineHeightFactor = 1.5;

      pointsForTripleLWithLineHeightFactor = {pointsForSingleL[0], pointsForSingleL[1],
        pointsForSingleL[2], pointsForSingleL[3], pointsForSingleL[4], pointsForSingleL[5],
        pointsForSingleL[0] + lineHeightFactor * verticalTranslation0,
        pointsForSingleL[1] + lineHeightFactor * verticalTranslation0,
        pointsForSingleL[2] + lineHeightFactor * verticalTranslation0,
        pointsForSingleL[3] + lineHeightFactor * verticalTranslation0,
        pointsForSingleL[4] + lineHeightFactor * verticalTranslation0,
        pointsForSingleL[5] + lineHeightFactor * verticalTranslation0,
        pointsForSingleL[0] + lineHeightFactor * verticalTranslation1,
        pointsForSingleL[1] + lineHeightFactor * verticalTranslation1,
        pointsForSingleL[2] + lineHeightFactor * verticalTranslation1,
        pointsForSingleL[3] + lineHeightFactor * verticalTranslation1,
        pointsForSingleL[4] + lineHeightFactor * verticalTranslation1,
        pointsForSingleL[5] + lineHeightFactor * verticalTranslation1
      };
    });

    it(@"should correctly create a path for a given string", ^{
      CGPathRelease(path);
      path = LTCGPathCreateWithString(@"L\n", [UIFont fontWithName:@"Helvetica" size:10]);

      evaluation.points = pointsForSingleL;
      evaluation.numberOfPointsToExpect = pointsForSingleL.size();
      evaluation.numberOfClosedSubPathsToExpect = 1;
      CGPathApply(path, &evaluation, &LTCheckCorrectnessOfPath);
      expect(evaluation.failure).to.beFalsy();
      expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
      expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);
    });

    it(@"should correctly create a path for a given single line attributed string", ^{
      CGPathRelease(path);
      UIFont *font = [UIFont fontWithName:@"Helvetica" size:10];
      NSAttributedString *attributedString =
          [[NSAttributedString alloc] initWithString:@"L\n"
                                          attributes:@{NSFontAttributeName: font}];
      CGPathRef immutablePath = LTCGPathCreateWithAttributedString(attributedString);

      evaluation.points = pointsForSingleL;
      evaluation.numberOfPointsToExpect = pointsForSingleL.size();
      evaluation.numberOfClosedSubPathsToExpect = 1;
      CGPathApply(immutablePath, &evaluation, &LTCheckCorrectnessOfPath);
      expect(evaluation.failure).to.beFalsy();
      expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
      expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);

      CGPathRelease(immutablePath);
    });

    it(@"should correctly create a path for a given multiple line attributed string", ^{
      UIFont *font = [UIFont fontWithName:@"Helvetica" size:10];
      NSAttributedString *attributedString =
      [[NSAttributedString alloc] initWithString:@"L\nL\nL\n"
                                      attributes:@{NSFontAttributeName: font}];
      CGPathRef immutablePath = LTCGPathCreateWithAttributedString(attributedString);

      evaluation.points = pointsForTripleL;
      evaluation.numberOfPointsToExpect = pointsForTripleL.size();
      evaluation.numberOfClosedSubPathsToExpect = 3;
      CGPathApply(immutablePath, &evaluation, &LTCheckCorrectnessOfPath);
      expect(evaluation.failure).to.beFalsy();
      expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
      expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);

      CGPathRelease(immutablePath);
    });

    it(@"should correctly create a path for a given attributed string with extra advancement", ^{
      UIFont *font = [UIFont fontWithName:@"Helvetica" size:10];
      NSAttributedString *attributedString =
      [[NSAttributedString alloc] initWithString:@"LL"
                                      attributes:@{NSFontAttributeName: font}];
      CGPathRef immutablePath =
          LTCGPathCreateWithAttributedString(attributedString, 1, advancementFactor);

      evaluation.points = pointsForDoubleL;
      evaluation.numberOfPointsToExpect = pointsForDoubleL.size();
      evaluation.numberOfClosedSubPathsToExpect = 2;
      CGPathApply(immutablePath, &evaluation, &LTCheckCorrectnessOfPath);
      expect(evaluation.failure).to.beFalsy();
      expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
      expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);

      CGPathRelease(immutablePath);
    });

    it(@"should correctly create a path for a given attributed string with line height factor", ^{
      UIFont *font = [UIFont fontWithName:@"Helvetica" size:10];
      NSAttributedString *attributedString =
      [[NSAttributedString alloc] initWithString:@"L\nL\nL\n"
                                      attributes:@{NSFontAttributeName: font}];
      CGPathRef immutablePath =
          LTCGPathCreateWithAttributedString(attributedString, lineHeightFactor);

      evaluation.points = pointsForTripleLWithLineHeightFactor;
      evaluation.numberOfPointsToExpect = pointsForTripleLWithLineHeightFactor.size();
      evaluation.numberOfClosedSubPathsToExpect = 3;
      CGPathApply(immutablePath, &evaluation, &LTCheckCorrectnessOfPath);
      expect(evaluation.failure).to.beFalsy();
      expect(evaluation.numberOfPoints).to.equal(evaluation.numberOfPointsToExpect);
      expect(evaluation.numberOfClosedSubPaths).to.equal(evaluation.numberOfClosedSubPathsToExpect);

      CGPathRelease(immutablePath);
    });
  });
});

SpecEnd

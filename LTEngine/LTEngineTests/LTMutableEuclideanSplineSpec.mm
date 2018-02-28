// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTMutableEuclideanSpline.h"

#import "LTBasicParameterizedObjectFactories.h"
#import "LTCompoundParameterizedObjectFactory.h"
#import "LTMutableEuclideanSplineTestUtils.h"
#import "LTParameterizationKeyToValues.h"

static const CGFloat kEpsilon = 3e-6;

static BOOL LTCompareParameterizationKeyToValues(LTParameterizationKeyToValues *mapping,
                                                 LTParameterizationKeyToValues *expectedMapping,
                                                 const CGFloat epsilon) {
  if (![[mapping.keys set] isEqualToSet:[expectedMapping.keys set]] ||
      mapping.numberOfValuesPerKey != expectedMapping.numberOfValuesPerKey) {
    return NO;
  }

  for (NSString *key in mapping.keys) {
    CGFloats values = [mapping valuesForKey:key];
    CGFloats expectedValues = [expectedMapping valuesForKey:key];

    for (NSUInteger i = 0; i < values.size(); ++i) {
      if (std::abs(values[i] - expectedValues[i]) > epsilon) {
        return NO;
      }
    }
  }

  return YES;
}

SpecBegin(LTMutableEuclideanSpline)

static NSString * const kLTMutableEuclideanSplineExamples = @"LTMutableEuclideanSplineExamples";

static NSString * const kLTMutableEuclideanSplineBaseFactory =
    @"LTMutableEuclideanSplineBaseFactory";

static NSString * const kLTMutableEuclideanSplineInitialPoints =
    @"LTMutableEuclideanSplineInitialPoints";

static NSString * const kLTMutableEuclideanSplineInsufficientAdditionalPoints =
    @"LTMutableEuclideanSplineInsufficientAdditionalPoints";

static NSString * const kLTMutableEuclideanSplineAdditionalPoints =
    @"LTMutableEuclideanSplineAdditionalPoints";

static NSString * const kLTMutableEuclideanSplineMaxParametericValue =
    @"LTMutableEuclideanSplineMaxParametericValue";

static NSString * const kLTMutableEuclideanSplineMaxParametericValueAfterPushing =
    @"LTMutableEuclideanSplineMaxParametericValueAfterPushing";

sharedExamplesFor(kLTMutableEuclideanSplineExamples, ^(NSDictionary *data) {
  __block id<LTBasicParameterizedObjectFactory> baseFactory;
  __block LTCompoundParameterizedObjectFactory *factory;
  __block NSArray<LTSplineControlPoint *> *initialPoints;
  __block NSArray<LTSplineControlPoint *> *additionalPoints;
  __block LTMutableEuclideanSpline *spline;

  beforeEach(^{
    baseFactory = data[kLTMutableEuclideanSplineBaseFactory];
    factory = [[LTCompoundParameterizedObjectFactory alloc] initWithBasicFactory:baseFactory];
    initialPoints = data[kLTMutableEuclideanSplineInitialPoints];
    additionalPoints = data[kLTMutableEuclideanSplineAdditionalPoints];
    spline = [[LTMutableEuclideanSpline alloc] initWithFactory:factory
                                          initialControlPoints:initialPoints];
  });

  context(@"initialization", ^{
    it(@"should initialize correctly", ^{
      expect(spline).toNot.beNil();
      expect(spline.controlPoints).to.equal(initialPoints);
      expect(spline.numberOfSegments).to.equal(1);
    });

    it(@"should raise when attempting to initialize with insufficient number of control points", ^{
      NSMutableArray<LTSplineControlPoint *> *insufficientInitialPoints =
          [initialPoints mutableCopy];
      [insufficientInitialPoints removeLastObject];
      initialPoints = [insufficientInitialPoints copy];

      expect(^{
        LTMutableEuclideanSpline __unused *spline =
            [[LTMutableEuclideanSpline alloc] initWithFactory:factory
                                         initialControlPoints:initialPoints];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise upon attempt to initialize with control points with decreasing timestamp", ^{
      NSArray<LTSplineControlPoint *> *reversedInitialPoints =
          [[initialPoints reverseObjectEnumerator] allObjects];

      expect(^{
        LTMutableEuclideanSpline __unused *spline =
            [[LTMutableEuclideanSpline alloc] initWithFactory:factory
                                              initialControlPoints:reversedInitialPoints];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"pushing control points", ^{
    it(@"should push control points", ^{
      [spline pushControlPoints:additionalPoints];
      expect(spline.controlPoints)
          .to.equal([initialPoints arrayByAddingObjectsFromArray:additionalPoints]);
    });

    it(@"should not add segment if number of new control points is insufficient for creation", ^{
      NSArray<LTSplineControlPoint *> *insufficientAdditionalPoints =
          data[kLTMutableEuclideanSplineInsufficientAdditionalPoints];

      [spline pushControlPoints:insufficientAdditionalPoints];

      expect(spline.numberOfSegments).to.equal(1);
    });

    it(@"should add segments if number of new control points is sufficient for creation", ^{
      [spline pushControlPoints:additionalPoints];
      expect(spline.numberOfSegments).to.equal(3);
    });

    it(@"should raise when attempting to push control points with decreasing timestamps", ^{
      NSArray<LTSplineControlPoint *> *reversedAdditionalPoints =
          [[additionalPoints reverseObjectEnumerator] allObjects];

      expect(^{
        [spline pushControlPoints:reversedAdditionalPoints];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"LTParameterizedObject protocol", ^{
    context(@"after initialization", ^{
      context(@"intrinsic parametric range", ^{
        it(@"should have the correct minimum parametric value", ^{
          expect(spline.minParametricValue).to.equal(0);
        });

        it(@"should have the correct maximum parametric value", ^{
          CGFloat maxParametricValue =
              [data[kLTMutableEuclideanSplineMaxParametericValue] CGFloatValue];
          expect(spline.maxParametricValue).to.beCloseToWithin(maxParametricValue, kEpsilon);
        });
      });

      context(@"mapping", ^{
        __block LTSplineControlPoint *startPoint;
        __block LTSplineControlPoint *endPoint;

        beforeEach(^{
          NSRange range = [[baseFactory class] intrinsicParametricRange];
          startPoint = spline.controlPoints[range.location];
          endPoint = spline.controlPoints[range.location + range.length - 1];
        });

        it(@"should return the correct mapping for a given parametric value", ^{
          LTParameterizationKeyToValue *expectedMapping = @{
            @keypath(startPoint, xCoordinateOfLocation): @(startPoint.xCoordinateOfLocation),
            @keypath(startPoint, yCoordinateOfLocation): @(startPoint.yCoordinateOfLocation),
            @"attribute": @7
          };

          LTParameterizationKeyToValue *mapping = [spline mappingForParametricValue:0];

          expect(mapping).to.equal(expectedMapping);
        });

        it(@"should return the correct mappings for given parametric values", ^{
          NSOrderedSet<NSString *> *keys =
              [NSOrderedSet orderedSetWithArray:@[@keypath(startPoint, xCoordinateOfLocation),
                                                  @keypath(startPoint, yCoordinateOfLocation),
                                                  @"attribute"]];
          cv::Mat1g values = (cv::Mat1g(3, 2) <<
              startPoint.xCoordinateOfLocation, endPoint.xCoordinateOfLocation,
              startPoint.yCoordinateOfLocation, endPoint.yCoordinateOfLocation,
              7, 8);

          LTParameterizationKeyToValues *expectedMapping =
              [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:values];

          LTParameterizationKeyToValues *mapping =
              [spline mappingForParametricValues:{0, spline.maxParametricValue}];

          expect(LTCompareParameterizationKeyToValues(mapping, expectedMapping, kEpsilon))
              .to.beTruthy();
        });

        it(@"should return the correct float value for a given parametric value and key", ^{
          CGFloat value = [spline floatForParametricValue:0
                                                      key:@keypath(initialPoints.firstObject,
                                                                   xCoordinateOfLocation)];
          expect(value).to.equal(startPoint.xCoordinateOfLocation);
        });

        it(@"should return the correct float values for given parametric values and key", ^{
          CGFloats expectedValues = {startPoint.xCoordinateOfLocation,
                                     endPoint.xCoordinateOfLocation};

          CGFloats values = [spline floatsForParametricValues:{0, spline.maxParametricValue}
                                                          key:@keypath(initialPoints.firstObject,
                                                                       xCoordinateOfLocation)];

          expect(values.size()).to.equal(expectedValues.size());
          for (CGFloats::size_type i = 0; i < values.size(); ++i) {
            expect(values[i]).to.beCloseToWithin(expectedValues[i], kEpsilon);
          }
        });
      });
    });

    context(@"after pushing additional control points", ^{
      beforeEach(^{
        [spline pushControlPoints:additionalPoints];
      });

      context(@"intrinsic parametric range", ^{
        it(@"should not update the minimum parametric value when adding additional control points",
           ^{
          expect(spline.minParametricValue).to.equal(0);
        });

        it(@"should update the maximum parametric value when adding additional control points", ^{
          CGFloat maxParametricValue =
              [data[kLTMutableEuclideanSplineMaxParametericValueAfterPushing] CGFloatValue];
          expect(spline.maxParametricValue).to.beCloseToWithin(maxParametricValue, kEpsilon);
        });
      });

      context(@"mapping", ^{
        __block LTSplineControlPoint *startPoint;
        __block LTSplineControlPoint *endPoint;

        beforeEach(^{
          NSRange range = [[baseFactory class] intrinsicParametricRange];
          startPoint = spline.controlPoints[range.location];
          endPoint = spline.controlPoints[spline.numberOfControlPoints -
                                          (range.location + range.length - 1)];
        });

        it(@"should return the correct mapping for a given parametric value", ^{
          LTParameterizationKeyToValue *expectedMapping = @{
            @keypath(startPoint, xCoordinateOfLocation): @(startPoint.xCoordinateOfLocation),
            @keypath(startPoint, yCoordinateOfLocation): @(startPoint.yCoordinateOfLocation),
            @"attribute": @7
          };

          LTParameterizationKeyToValue *mapping = [spline mappingForParametricValue:0];

          expect(mapping).to.equal(expectedMapping);
        });

        it(@"should return the correct mappings for given parametric values", ^{
          NSOrderedSet<NSString *> *keys =
              [NSOrderedSet orderedSetWithArray:@[@keypath(startPoint, xCoordinateOfLocation),
                                                  @keypath(startPoint, yCoordinateOfLocation),
                                                  @"attribute"]];
          cv::Mat1g values = (cv::Mat1g(3, 2) <<
              startPoint.xCoordinateOfLocation, endPoint.xCoordinateOfLocation,
              startPoint.yCoordinateOfLocation, endPoint.yCoordinateOfLocation,
              7, 11);

          LTParameterizationKeyToValues *expectedMapping =
              [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:values];

          LTParameterizationKeyToValues *mapping =
              [spline mappingForParametricValues:{0, spline.maxParametricValue}];

          expect(LTCompareParameterizationKeyToValues(mapping, expectedMapping, kEpsilon))
              .to.beTruthy();
        });

        it(@"should return the correct float value for a given parametric value and key", ^{
          CGFloat value = [spline floatForParametricValue:0
                                                      key:@keypath(initialPoints.firstObject,
                                                                   xCoordinateOfLocation)];
          expect(value).to.equal(startPoint.xCoordinateOfLocation);
        });

        it(@"should return the correct float values for given parametric values and key", ^{
          CGFloats expectedValues = {startPoint.xCoordinateOfLocation,
                                     endPoint.xCoordinateOfLocation};

          CGFloats values = [spline floatsForParametricValues:{0, spline.maxParametricValue}
                                                          key:@keypath(initialPoints.firstObject,
                                                                       xCoordinateOfLocation)];

          expect(values.size()).to.equal(expectedValues.size());
          for (CGFloats::size_type i = 0; i < values.size(); ++i) {
            expect(values[i]).to.beCloseToWithin(expectedValues[i], kEpsilon);
          }
        });
      });
    });
  });

  it(@"should have the correct parametrization keys", ^{
    expect(spline.parameterizationKeys)
        .to.equal([initialPoints.firstObject propertiesToInterpolate]);
  });

  context(@"properties", ^{
    it(@"should return copies of its control points", ^{
      NSArray<LTSplineControlPoint *> *controlPoints = spline.controlPoints;
      [spline pushControlPoints:additionalPoints];
      expect(controlPoints).toNot.beIdenticalTo(spline.controlPoints);
    });

    it(@"should return copies of its segments", ^{
      NSArray<id<LTParameterizedObject>> *segments = spline.segments;
      [spline pushControlPoints:additionalPoints];
      expect(segments).toNot.beIdenticalTo(spline.segments);
    });

    it(@"should return the correct number of control points", ^{
      expect(spline.numberOfControlPoints).to.equal(initialPoints.count);
      expect(spline.numberOfControlPoints).to.equal(spline.controlPoints.count);

      [spline pushControlPoints:additionalPoints];
      expect(spline.numberOfControlPoints).to.equal(initialPoints.count + additionalPoints.count);
      expect(spline.numberOfControlPoints).to.equal(spline.controlPoints.count);
    });

    it(@"should return the correct number of segments", ^{
      expect(spline.numberOfSegments).to.equal(1);
      expect(spline.numberOfSegments).to.equal(spline.segments.count);

      [spline pushControlPoints:additionalPoints];
      expect(spline.numberOfSegments).to.equal(3);
      expect(spline.numberOfSegments).to.equal(spline.segments.count);
    });
  });
});

itShouldBehaveLike(kLTMutableEuclideanSplineExamples, @{
  kLTMutableEuclideanSplineBaseFactory: [[LTBasicLinearInterpolantFactory alloc] init],
  kLTMutableEuclideanSplineInitialPoints:
      LTCreateSplinePoints({0, 1}, {CGPointZero, CGPointMake(1, 1)}, @"attribute", @[@7, @8]),
  kLTMutableEuclideanSplineInsufficientAdditionalPoints: LTCreateSplinePoints({}, {}, nil, nil),
  kLTMutableEuclideanSplineAdditionalPoints:
      LTCreateSplinePoints({2, 3}, {CGPointMake(2, 0), CGPointMake(3, 1)}, @"attribute",
                           @[@10, @11]),
  kLTMutableEuclideanSplineMaxParametericValue: @(M_SQRT2),
  kLTMutableEuclideanSplineMaxParametericValueAfterPushing: @(3 * M_SQRT2)
});

itShouldBehaveLike(kLTMutableEuclideanSplineExamples, @{
  kLTMutableEuclideanSplineBaseFactory: [[LTBasicCubicBezierInterpolantFactory alloc] init],
  kLTMutableEuclideanSplineInitialPoints:
      LTCreateSplinePoints({0, 1, 2, 3},
                           {CGPointZero, CGPointZero, CGPointMake(1, 1), CGPointMake(1, 1)},
                           @"attribute", @[@7, @7.1, @7.2, @8]),
  kLTMutableEuclideanSplineInsufficientAdditionalPoints: LTCreateSplinePoints({}, {}, nil, nil),
  kLTMutableEuclideanSplineAdditionalPoints:
      LTCreateSplinePoints({4, 5, 6, 7, 8, 9}, {CGPointMake(1, 1), CGPointMake(2, 2),
                           CGPointMake(2, 2), CGPointMake(2, 2), CGPointMake(3, 3),
                           CGPointMake(3, 3)}, @"attribute", @[@8.5, @9, @9.5, @10, @10.5, @11]),
  kLTMutableEuclideanSplineMaxParametericValue: @(M_SQRT2),
  kLTMutableEuclideanSplineMaxParametericValueAfterPushing: @(M_SQRT2 * 3)
});

itShouldBehaveLike(kLTMutableEuclideanSplineExamples, @{
  kLTMutableEuclideanSplineBaseFactory: [[LTBasicCatmullRomInterpolantFactory alloc] init],
  kLTMutableEuclideanSplineInitialPoints:
      LTCreateSplinePoints({0, 1, 2, 3},
                           {CGPointZero, CGPointZero, CGPointMake(1, 1), CGPointMake(1, 1)},
                           @"attribute", @[@6, @7, @8, @9]),
  kLTMutableEuclideanSplineInsufficientAdditionalPoints: LTCreateSplinePoints({}, {}, nil, nil),
  kLTMutableEuclideanSplineAdditionalPoints:
      LTCreateSplinePoints({4, 5}, {CGPointMake(2, 0), CGPointMake(2, 0)}, @"attribute",
                           @[@11, @12]),
  kLTMutableEuclideanSplineMaxParametericValue: @(M_SQRT2),
  kLTMutableEuclideanSplineMaxParametericValueAfterPushing: @3.1677561067696
});

SpecEnd

// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTMutableEuclideanSpline.h"

#import "LTCompoundParameterizedObjectFactory.h"
#import "LTMutableEuclideanSplineTestUtils.h"
#import "LTPrimitiveParameterizedObjectFactories.h"

static const CGFloat kEpsilon = 3e-6;

static BOOL LTCompareParameterizationKeyToValues(LTParameterizationKeyToValues *mapping,
                                                 LTParameterizationKeyToValues *expectedMapping,
                                                 const CGFloat epsilon) {
  if (![[NSSet setWithArray:[mapping allKeys]]
        isEqualToSet:[NSSet setWithArray:[expectedMapping allKeys]]]) {
    return NO;
  }

  for (NSString *key in mapping) {
    NSUInteger size = mapping[key].count;
    if (size != expectedMapping[key].count) {
      return NO;
    }

    for (NSUInteger i = 0; i < size; ++i) {
      if (std::abs([mapping[key][i] CGFloatValue] - [expectedMapping[key][i] CGFloatValue]) >
          epsilon) {
        return NO;
      }
    }
  }

  return YES;
}

SpecBegin(LTMutableEuclideanSpline)

static NSString * const kLTMutableEuclideanSplineExamples = @"LTMutableEuclideanSplineExamples";

static NSString * const kLTMutableEuclideanSplinePrimitiveFactory =
    @"LTMutableEuclideanSplinePrimitiveFactory";

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
  __block id<LTPrimitiveParameterizedObjectFactory> primitiveFactory;
  __block LTCompoundParameterizedObjectFactory *factory;
  __block NSArray<LTEuclideanSplineControlPoint *> *initialPoints;
  __block NSArray<LTEuclideanSplineControlPoint *> *additionalPoints;
  __block LTMutableEuclideanSpline *spline;

  beforeEach(^{
    primitiveFactory = data[kLTMutableEuclideanSplinePrimitiveFactory];
    factory =
        [[LTCompoundParameterizedObjectFactory alloc] initWithPrimitiveFactory:primitiveFactory];
    initialPoints = data[kLTMutableEuclideanSplineInitialPoints];
    additionalPoints = data[kLTMutableEuclideanSplineAdditionalPoints];
    spline = [[LTMutableEuclideanSpline alloc] initWithFactory:factory
                                          initialControlPoints:initialPoints];
  });

  context(@"initialization", ^{
    it(@"should initialize correctly", ^{
      expect(spline).toNot.beNil();
      expect(spline.controlPoints).to.equal(initialPoints);
      expect(spline.segments.count).to.equal(1);
    });

    it(@"should raise when attempting to initialize with insufficient number of control points", ^{
      NSMutableArray<LTEuclideanSplineControlPoint *> *insufficientInitialPoints =
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
      NSArray<LTEuclideanSplineControlPoint *> *reversedInitialPoints =
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
      NSArray<LTEuclideanSplineControlPoint *> *insufficientAdditionalPoints =
          data[kLTMutableEuclideanSplineInsufficientAdditionalPoints];

      [spline pushControlPoints:insufficientAdditionalPoints];

      expect(spline.segments.count).to.equal(1);
    });

    it(@"should add segments if number of new control points is sufficient for creation", ^{
      [spline pushControlPoints:additionalPoints];
      expect(spline.segments.count).to.equal(3);
    });

    it(@"should raise when attempting to push control points with decreasing timestamps", ^{
      NSArray<LTEuclideanSplineControlPoint *> *reversedAdditionalPoints =
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
        __block LTEuclideanSplineControlPoint *startPoint;
        __block LTEuclideanSplineControlPoint *endPoint;

        beforeEach(^{
          NSRange range = [[primitiveFactory class] intrinsicParametricRange];
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
          LTParameterizationKeyToValues *expectedMapping = @{
            @keypath(startPoint, xCoordinateOfLocation):
                @[@(startPoint.xCoordinateOfLocation), @(endPoint.xCoordinateOfLocation)],
            @keypath(startPoint, yCoordinateOfLocation):
                @[@(startPoint.yCoordinateOfLocation), @(endPoint.yCoordinateOfLocation)],
            @"attribute": @[@7, @8]
          };

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
        __block LTEuclideanSplineControlPoint *startPoint;
        __block LTEuclideanSplineControlPoint *endPoint;

        beforeEach(^{
          NSRange range = [[primitiveFactory class] intrinsicParametricRange];
          startPoint = spline.controlPoints[range.location];
          endPoint = spline.controlPoints[spline.controlPoints.count -
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
          LTParameterizationKeyToValues *expectedMapping = @{
            @keypath(startPoint, xCoordinateOfLocation):
                @[@(startPoint.xCoordinateOfLocation), @(endPoint.xCoordinateOfLocation)],
            @keypath(startPoint, yCoordinateOfLocation):
                @[@(startPoint.yCoordinateOfLocation), @(endPoint.yCoordinateOfLocation)],
            @"attribute": @[@7, @11]
          };

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
});

itShouldBehaveLike(kLTMutableEuclideanSplineExamples, @{
  kLTMutableEuclideanSplinePrimitiveFactory: [[LTPrimitiveLinearInterpolantFactory alloc] init],
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
  kLTMutableEuclideanSplinePrimitiveFactory: [[LTPrimitiveCatmullRomInterpolantFactory alloc] init],
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

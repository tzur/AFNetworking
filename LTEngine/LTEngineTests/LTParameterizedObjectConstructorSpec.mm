// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObjectConstructor.h"

#import "LTControlPointModel.h"
#import "LTParameterizedObjectType.h"
#import "LTSplineControlPoint.h"

static NSString * const kLTParameterizedObjectConstructorExamples =
    @"LTParameterizedObjectConstructorExamples";

static NSString * const kLTParameterizedObjectTypeClass = @"LTParameterizedObjectTypeClass";

static NSString * const kLTBasicParameterizedObjectFactoryInsufficientControlPoints =
    @"LTBasicParameterizedObjectFactoryInsufficientControlPoints";

static NSString * const kLTBasicParameterizedObjectFactorySufficientControlPoints =
    @"LTBasicParameterizedObjectFactorySufficientControlPoints";

static NSString * const kLTBasicParameterizedObjectFactoryControlPointsForPopping =
    @"LTBasicParameterizedObjectFactoryControlPointsForPopping";

SharedExamplesBegin(LTParameterizedObjectConstructorExamples)

sharedExamplesFor(kLTParameterizedObjectConstructorExamples, ^(NSDictionary *data) {
  __block LTParameterizedObjectType *type;
  __block NSArray<LTSplineControlPoint *> *insufficientControlPoints;
  __block NSArray<LTSplineControlPoint *> *sufficientControlPoints;
  __block NSArray<LTSplineControlPoint *> *controlPointsForPopping;
  __block LTParameterizedObjectConstructor *constructor;

  beforeEach(^{
    type = data[kLTParameterizedObjectTypeClass];
    insufficientControlPoints = data[kLTBasicParameterizedObjectFactoryInsufficientControlPoints];
    sufficientControlPoints = data[kLTBasicParameterizedObjectFactorySufficientControlPoints];
    controlPointsForPopping = data[kLTBasicParameterizedObjectFactoryControlPointsForPopping];
    constructor = [[LTParameterizedObjectConstructor alloc] initWithType:type];
  });

  context(@"initialization", ^{
    it(@"should initialize correctly", ^{
      expect(constructor.parameterizedObject).to.beNil();
    });
  });

  context(@"type", ^{
    it(@"should return the type of the parameterized object", ^{
      expect(constructor.type).to.equal(type);
    });
  });

  context(@"parameterized object", ^{
    it(@"should not provide parameterized object after adding insufficient number of points", ^{
      [constructor pushControlPoints:insufficientControlPoints];
      expect([constructor parameterizedObject]).to.beNil();
    });

    it(@"should provide parameterized object after adding sufficient number of points", ^{
      [constructor pushControlPoints:sufficientControlPoints];
      expect([constructor parameterizedObject]).toNot.beNil();
    });

    it(@"should provide correct parameterized object", ^{
      [constructor pushControlPoints:sufficientControlPoints];
      id<LTParameterizedObject> parameterizedObject = [constructor parameterizedObject];
      NSString *key = @instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation);
      expect(parameterizedObject.minParametricValue).to.equal(0);
      expect(parameterizedObject.maxParametricValue).to.equal(1);
      expect([parameterizedObject floatForParametricValue:0 key:key]).to.equal(1);
      expect([parameterizedObject floatForParametricValue:1 key:key]).to.equal(2);
    });

    context(@"popping control points", ^{
      beforeEach(^{
        [constructor pushControlPoints:sufficientControlPoints];
      });

      it(@"should provide parameterized object after popping zero points", ^{
        [constructor popControlPoints:0];
        expect([constructor parameterizedObject]).toNot.beNil();
      });

      it(@"should provide parameterized object after popping insufficient number of points", ^{
        [constructor pushControlPoints:controlPointsForPopping];
        [constructor popControlPoints:controlPointsForPopping.count];
        expect([constructor parameterizedObject]).toNot.beNil();
      });

      it(@"should not provide parameterized object after popping sufficient number of points", ^{
        [constructor pushControlPoints:controlPointsForPopping];
        [constructor popControlPoints:controlPointsForPopping.count + 1];
        expect([constructor parameterizedObject]).to.beNil();
      });

      it(@"should not provide parameterized object after popping all existing points", ^{
        [constructor popControlPoints:sufficientControlPoints.count];
        expect([constructor parameterizedObject]).to.beNil();
      });

      it(@"should not provide parameterized object after popping all possible points", ^{
        [constructor popControlPoints:NSUIntegerMax];
        expect([constructor parameterizedObject]).to.beNil();
      });

      it(@"should be able to create parameterized object after popping points", ^{
        [constructor popControlPoints:sufficientControlPoints.count];
        expect([constructor parameterizedObject]).to.beNil();
        [constructor pushControlPoints:sufficientControlPoints];
        expect([constructor parameterizedObject]).toNot.beNil();
      });
    });

    context(@"parameterized object from control point model", ^{
      it(@"should not provide parameterized object from insufficient control point model", ^{
        LTControlPointModel *model =
            [[LTControlPointModel alloc] initWithType:type controlPoints:insufficientControlPoints];
        id<LTParameterizedObject> parameterizedObject =
            [LTParameterizedObjectConstructor parameterizedObjectFromModel:model];
        expect(parameterizedObject).to.beNil();
      });

      it(@"should provide correct parameterized object from control point model", ^{
        LTControlPointModel *model =
            [[LTControlPointModel alloc] initWithType:type controlPoints:sufficientControlPoints];
        id<LTParameterizedObject> parameterizedObject =
            [LTParameterizedObjectConstructor parameterizedObjectFromModel:model];
        NSString *key = @instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation);
        expect(parameterizedObject.minParametricValue).to.equal(0);
        expect(parameterizedObject.maxParametricValue).to.equal(1);
        expect([parameterizedObject floatForParametricValue:0 key:key]).to.equal(1);
        expect([parameterizedObject floatForParametricValue:1 key:key]).to.equal(2);
      });

      it(@"should not provide object from insufficient control point model created by itself", ^{
        [constructor pushControlPoints:insufficientControlPoints];
            LTControlPointModel *model = [constructor reset];
        id<LTParameterizedObject> parameterizedObject =
            [LTParameterizedObjectConstructor parameterizedObjectFromModel:model];
        expect(parameterizedObject).to.beNil();
      });

      it(@"should provide parameterized object from control point model created by itself", ^{
        [constructor pushControlPoints:sufficientControlPoints];
        LTControlPointModel *model = [constructor reset];
        id<LTParameterizedObject> parameterizedObject =
            [LTParameterizedObjectConstructor parameterizedObjectFromModel:model];
        NSString *key = @instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation);
        expect(parameterizedObject.minParametricValue).to.equal(0);
        expect(parameterizedObject.maxParametricValue).to.equal(1);
        expect([parameterizedObject floatForParametricValue:0 key:key]).to.equal(1);
        expect([parameterizedObject floatForParametricValue:1 key:key]).to.equal(2);
      });

      it(@"should return same parameterized object if possible", ^{
        [constructor pushControlPoints:sufficientControlPoints];
        id<LTParameterizedObject> parameterizedObject = constructor.parameterizedObject;
        LTControlPointModel *model = [constructor reset];
        id<LTParameterizedObject> anotherParameterizedObject =
            [LTParameterizedObjectConstructor parameterizedObjectFromModel:model];
        expect(parameterizedObject).to.beIdenticalTo(anotherParameterizedObject);
      });
    });
  });

  context(@"resetting", ^{
    context(@"after initialization", ^{
      it(@"should ignore resetting right after initialization", ^{
        [constructor reset];
        expect(constructor.parameterizedObject).to.beNil();
      });

      it(@"should return an empty control point model when resetting right after initialization", ^{
        LTControlPointModel *model = [constructor reset];
        expect(model).to.equal([[LTControlPointModel alloc] initWithType:type]);
      });
    });

    context(@"after pushing insufficient number of points", ^{
      beforeEach(^{
        [constructor pushControlPoints:insufficientControlPoints];
      });

      it(@"should reset correctly", ^{
        LTControlPointModel *model = [constructor reset];
        expect(constructor.parameterizedObject).to.beNil();
        expect(model).to.equal([[LTControlPointModel alloc]
                                initWithType:type controlPoints:insufficientControlPoints]);
      });

      it(@"should reset correctly after popping", ^{
        [constructor popControlPoints:1];
        LTControlPointModel *model = [constructor reset];
        expect(constructor.parameterizedObject).to.beNil();
        NSArray<LTSplineControlPoint *> *controlPoints =
            [insufficientControlPoints
             subarrayWithRange:NSMakeRange(0, insufficientControlPoints.count - 1)];
        expect(model).to.equal([[LTControlPointModel alloc] initWithType:type
                                                           controlPoints:controlPoints]);
      });
    });

    context(@"after pushing sufficient number of points", ^{
      beforeEach(^{
        [constructor pushControlPoints:sufficientControlPoints];
      });

      it(@"should reset correctly", ^{
        LTControlPointModel *model = [constructor reset];
        expect(constructor.parameterizedObject).to.beNil();
        expect(model).to.equal([[LTControlPointModel alloc]
                                 initWithType:type controlPoints:sufficientControlPoints]);

      });

      it(@"should reset correctly after popping", ^{
        [constructor popControlPoints:1];
        LTControlPointModel *model = [constructor reset];
        expect(constructor.parameterizedObject).to.beNil();
        NSArray<LTSplineControlPoint *> *controlPoints =
            [sufficientControlPoints
             subarrayWithRange:NSMakeRange(0, sufficientControlPoints.count - 1)];
        expect(model).to.equal([[LTControlPointModel alloc] initWithType:type
                                                           controlPoints:controlPoints]);

      });
    });
  });
});

SharedExamplesEnd

SpecBegin(LTParameterizedObjectConstructor)

static const NSArray<LTSplineControlPoint *> *kPoints = @[
  [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointZero],
  [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(0, 1)],
  [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(0, 2)],
  [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(0, 3)]
];

static const NSArray<LTSplineControlPoint *> *kPointsForPopping = @[
  [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(0, 4)],
  [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(0, 5)]
];

itShouldBehaveLike(kLTParameterizedObjectConstructorExamples, ^{
  return @{
    kLTParameterizedObjectTypeClass: $(LTParameterizedObjectTypeLinear),
    kLTBasicParameterizedObjectFactoryInsufficientControlPoints: @[kPoints[0]],
    kLTBasicParameterizedObjectFactorySufficientControlPoints: @[kPoints[1], kPoints[2]],
    kLTBasicParameterizedObjectFactoryControlPointsForPopping: @[kPointsForPopping[0]]
  };
});

itShouldBehaveLike(kLTParameterizedObjectConstructorExamples, ^{
  return @{
    kLTParameterizedObjectTypeClass: $(LTParameterizedObjectTypeCubicBezier),
    kLTBasicParameterizedObjectFactoryInsufficientControlPoints: @[kPoints[0], kPoints[1],
                                                                   kPoints[2]],
    kLTBasicParameterizedObjectFactorySufficientControlPoints: @[kPoints[1], kPoints[1], kPoints[2],
                                                                 kPoints[2]],
    kLTBasicParameterizedObjectFactoryControlPointsForPopping: kPointsForPopping
  };
});

itShouldBehaveLike(kLTParameterizedObjectConstructorExamples, ^{
  return @{
    kLTParameterizedObjectTypeClass: $(LTParameterizedObjectTypeCatmullRom),
    kLTBasicParameterizedObjectFactoryInsufficientControlPoints: @[kPoints[0], kPoints[1],
                                                                   kPoints[2]],
    kLTBasicParameterizedObjectFactorySufficientControlPoints: @[kPoints[0], kPoints[1], kPoints[2],
                                                                 kPoints[3]],
    kLTBasicParameterizedObjectFactoryControlPointsForPopping: kPointsForPopping
  };
});

itShouldBehaveLike(kLTParameterizedObjectConstructorExamples, ^{
  return @{
    kLTParameterizedObjectTypeClass: $(LTParameterizedObjectTypeBSpline),
    kLTBasicParameterizedObjectFactoryInsufficientControlPoints: @[kPoints[0], kPoints[1],
                                                                   kPoints[2]],
    kLTBasicParameterizedObjectFactorySufficientControlPoints: @[kPoints[0], kPoints[1], kPoints[2],
                                                                 kPoints[3]],
    kLTBasicParameterizedObjectFactoryControlPointsForPopping: kPointsForPopping
  };
});

SpecEnd

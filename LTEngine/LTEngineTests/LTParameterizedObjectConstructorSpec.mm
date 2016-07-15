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

SharedExamplesBegin(LTParameterizedObjectConstructorExamples)

sharedExamplesFor(kLTParameterizedObjectConstructorExamples, ^(NSDictionary *data) {
  __block LTParameterizedObjectType *type;
  __block NSArray<LTSplineControlPoint *> *insufficientControlPoints;
  __block NSArray<LTSplineControlPoint *> *sufficientControlPoints;
  __block LTParameterizedObjectConstructor *constructor;

  beforeEach(^{
    type = data[kLTParameterizedObjectTypeClass];
    insufficientControlPoints = data[kLTBasicParameterizedObjectFactoryInsufficientControlPoints];
    sufficientControlPoints = data[kLTBasicParameterizedObjectFactorySufficientControlPoints];
    constructor = [[LTParameterizedObjectConstructor alloc] initWithType:type];
  });

  context(@"initialization", ^{
    it(@"should initialize correctly", ^{
      expect(constructor.parameterizedObject).to.beNil();
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

      it(@"should provide correct parameterized object from control point model created by itself", ^{
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
      it(@"should reset correctly", ^{
        [constructor pushControlPoints:insufficientControlPoints];
        LTControlPointModel *model = [constructor reset];
        expect(constructor.parameterizedObject).to.beNil();
        expect(model).to.equal([[LTControlPointModel alloc]
                                initWithType:type controlPoints:insufficientControlPoints]);
      });
    });

    context(@"after pushing sufficient number of points", ^{
      it(@"should reset correctly", ^{
        [constructor pushControlPoints:sufficientControlPoints];
        LTControlPointModel *model = [constructor reset];
        expect(constructor.parameterizedObject).to.beNil();
        expect(model) .to.equal([[LTControlPointModel alloc]
                                 initWithType:type controlPoints:sufficientControlPoints]);

      });
    });
  });
});

SharedExamplesEnd

SpecBegin(LTParameterizedObjectConstructor)

static const NSArray<LTSplineControlPoint *> *points =
    @[[[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointZero],
      [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(0, 1)],
      [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(0, 2)],
      [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(0, 3)]];

itShouldBehaveLike(kLTParameterizedObjectConstructorExamples, ^{
  return @{kLTParameterizedObjectTypeClass: $(LTParameterizedObjectTypeLinear),
           kLTBasicParameterizedObjectFactoryInsufficientControlPoints: @[points[0]],
           kLTBasicParameterizedObjectFactorySufficientControlPoints: @[points[1], points[2]]};
});

itShouldBehaveLike(kLTParameterizedObjectConstructorExamples, ^{
  return @{kLTParameterizedObjectTypeClass: $(LTParameterizedObjectTypeCatmullRom),
           kLTBasicParameterizedObjectFactoryInsufficientControlPoints: @[points[0], points[1],
                                                                          points[2]],
           kLTBasicParameterizedObjectFactorySufficientControlPoints: @[points[0], points[1],
                                                                        points[2], points[3]]};
});

SpecEnd

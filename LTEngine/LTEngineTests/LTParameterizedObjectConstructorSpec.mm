// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObjectConstructor.h"

#import "LTControlPointModel.h"
#import "LTEuclideanSplineControlPoint.h"
#import "LTParameterizedObjectType.h"

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
  __block LTControlPointModel *insufficientModel;
  __block LTControlPointModel *sufficientModel;

  beforeEach(^{
    type = data[kLTParameterizedObjectTypeClass];
    insufficientModel =
        [[LTControlPointModel alloc]
         initWithType:type
         controlPoints:data[kLTBasicParameterizedObjectFactoryInsufficientControlPoints]];
    sufficientModel =
        [[LTControlPointModel alloc]
         initWithType:type
         controlPoints:data[kLTBasicParameterizedObjectFactorySufficientControlPoints]];
  });

  context(@"initialization", ^{
    it(@"should initialize correctly with empty control point model", ^{
      LTControlPointModel *model =
          [[LTControlPointModel alloc] initWithType:type controlPoints:@[]];
      LTParameterizedObjectConstructor *constructor =
          [[LTParameterizedObjectConstructor alloc] initWithControlPointModel:model];
      expect(constructor.controlPointModel).to.equal(model);
    });

    it(@"should initialize correctly with model with insufficient number of control points", ^{
      LTParameterizedObjectConstructor *constructor =
          [[LTParameterizedObjectConstructor alloc] initWithControlPointModel:insufficientModel];
      expect(constructor.controlPointModel).to.equal(insufficientModel);
    });

    it(@"should initialize correctly with model with sufficient number of control points", ^{
      LTParameterizedObjectConstructor *constructor =
          [[LTParameterizedObjectConstructor alloc] initWithControlPointModel:sufficientModel];
      expect(constructor.controlPointModel).to.equal(sufficientModel);
    });

    context(@"parameterized object retrieval after initialization", ^{
      context(@"initialization", ^{
        it(@"should not provide object after initialization without points", ^{
          LTControlPointModel *model =
              [[LTControlPointModel alloc] initWithType:type controlPoints:@[]];
          LTParameterizedObjectConstructor *constructor =
              [[LTParameterizedObjectConstructor alloc] initWithControlPointModel:model];
          expect([constructor parameterizedObject]).to.beNil();
        });

        it(@"should not provide object after initialization with insufficient number of points", ^{
          LTParameterizedObjectConstructor *constructor =
              [[LTParameterizedObjectConstructor alloc]
               initWithControlPointModel:insufficientModel];
          expect([constructor parameterizedObject]).to.beNil();
        });

        it(@"should provide object after initialization with sufficient number of points", ^{
          LTParameterizedObjectConstructor *constructor =
              [[LTParameterizedObjectConstructor alloc] initWithControlPointModel:sufficientModel];
          expect([constructor parameterizedObject]).toNot.beNil();
        });
      });
    });

    context(@"adding control points", ^{
      it(@"should not provide object after adding insufficient number of points", ^{
        LTControlPointModel *model =
            [[LTControlPointModel alloc] initWithType:type controlPoints:@[]];
        LTParameterizedObjectConstructor *constructor =
            [[LTParameterizedObjectConstructor alloc] initWithControlPointModel:model];
        [constructor pushControlPoints:insufficientModel.controlPoints];
        expect([constructor parameterizedObject]).to.beNil();
      });

      it(@"should provide object after adding sufficient number of points", ^{
        LTControlPointModel *model =
            [[LTControlPointModel alloc] initWithType:type controlPoints:@[]];
        LTParameterizedObjectConstructor *constructor =
            [[LTParameterizedObjectConstructor alloc] initWithControlPointModel:model];
        [constructor pushControlPoints:sufficientModel.controlPoints];
        expect([constructor parameterizedObject]).toNot.beNil();
      });
    });

    context(@"parameterized object", ^{
      it(@"should provide correct parameterized object", ^{
        LTParameterizedObjectConstructor *constructor =
            [[LTParameterizedObjectConstructor alloc] initWithControlPointModel:sufficientModel];
        id<LTParameterizedObject> parameterizedObject = [constructor parameterizedObject];
        NSString *key = @instanceKeypath(LTEuclideanSplineControlPoint, yCoordinateOfLocation);
        expect(parameterizedObject.minParametricValue).to.equal(0);
        expect(parameterizedObject.maxParametricValue).to.equal(1);
        expect([parameterizedObject floatForParametricValue:0 key:key]).to.equal(1);
        expect([parameterizedObject floatForParametricValue:1 key:key]).to.equal(2);
      });
    });
  });
});

SharedExamplesEnd

SpecBegin(LTParameterizedObjectConstructor)

static const NSArray<LTEuclideanSplineControlPoint *> *points =
    @[[[LTEuclideanSplineControlPoint alloc] initWithTimestamp:0 location:CGPointZero],
      [[LTEuclideanSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(0, 1)],
      [[LTEuclideanSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(0, 2)],
      [[LTEuclideanSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(0, 3)]];

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

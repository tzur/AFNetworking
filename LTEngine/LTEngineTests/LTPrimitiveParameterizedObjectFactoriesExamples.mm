// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTPrimitiveParameterizedObjectFactoriesExamples.h"

#import "LTPrimitiveParameterizedObject.h"
#import "LTPrimitiveParameterizedObjectFactories.h"

NSString * const kLTPrimitiveParameterizedObjectFactoryExamples =
    @"LTPrimitiveParameterizedObjectFactoryExamples";
NSString * const kLTPrimitiveParameterizedObjectFactoryClass =
    @"LTPrimitiveParameterizedObjectFactoryClass";
NSString * const kLTPrimitiveParameterizedObjectFactoryNumberOfRequiredValues =
    @"LTPrimitiveParameterizedObjectFactoryNumberOfRequiredValues";
NSString * const kLTPrimitiveParameterizedObjectFactoryMinParametricValue =
    @"LTPrimitiveParameterizedObjectFactoryMinParametricValue";
NSString * const kLTPrimitiveParameterizedObjectFactoryMaxParametricValue =
    @"LTPrimitiveParameterizedObjectFactoryMaxParametricValue";
NSString * const kLTPrimitiveParameterizedObjectFactoryRange =
    @"LTPrimitiveParameterizedObjectFactoryRange";
NSString * const kLTPrimitiveParameterizedObjectFactoryValues =
    @"LTPrimitiveParameterizedObjectFactoryValues";
NSString * const kLTPrimitiveParameterizedObjectFactoryComputedValues =
    @"LTPrimitiveParameterizedObjectFactoryComputedValues";

SharedExamplesBegin(LTPrimitiveParameterizedObjectFactoriesExamples)

static const CGFloat kEpsilon = 1e-4;

sharedExamplesFor(kLTPrimitiveParameterizedObjectFactoryExamples, ^(NSDictionary *data) {
  __block id<LTPrimitiveParameterizedObjectFactory> factory;
  __block NSUInteger numberOfRequiredValues;
  __block NSRange range;

  beforeEach(^{
    factory = [[data[kLTPrimitiveParameterizedObjectFactoryClass] alloc] init];
    numberOfRequiredValues =
        [data[kLTPrimitiveParameterizedObjectFactoryNumberOfRequiredValues] unsignedIntegerValue];
    range = [data[kLTPrimitiveParameterizedObjectFactoryRange] rangeValue];
  });

  context(@"initialization", ^{
    it(@"should initialize correctly", ^{
      expect(factory).toNot.beNil();
      expect([[factory class] numberOfRequiredValues]).to.equal(numberOfRequiredValues);
      expect([[factory class] intrinsicParametricRange].location).to.equal(range.location);
      expect([[factory class] intrinsicParametricRange].length).to.equal(range.length);
    });
  });

  context(@"validity of properties", ^{
    it(@"should have correct properties", ^{
      expect([[factory class] numberOfRequiredValues]).to.beGreaterThan(0);
      expect([[factory class] intrinsicParametricRange].length).to.beGreaterThanOrEqualTo(1);
      expect([[factory class] intrinsicParametricRange].location +
             [[factory class] intrinsicParametricRange].length)
          .toNot.beGreaterThan([[factory class] numberOfRequiredValues]);
    });
  });

  context(@"computation of primitive parameterized objects", ^{
    context(@"invalid API calls", ^{
      it(@"should raise when attempting to compute object from values with invalid count", ^{
        CGFloats valuesWithInvalidCount;
        for (NSUInteger i = 0; i < numberOfRequiredValues + 1; ++i) {
          valuesWithInvalidCount.push_back(0);
        }
        expect(^{
          [factory primitiveParameterizedObjectsFromValues:valuesWithInvalidCount];
        }).to.raise(NSInvalidArgumentException);
      });
    });

    context(@"valid API calls", ^{
      __block id<LTPrimitiveParameterizedObject> parameterizedObject;
      __block NSArray<NSNumber *> *initializationValues;
      __block NSArray<NSNumber *> *expectedValues;

      beforeEach(^{
        initializationValues = data[kLTPrimitiveParameterizedObjectFactoryValues];
        expectedValues = data[kLTPrimitiveParameterizedObjectFactoryComputedValues];

        CGFloats unboxedInitializationValues;
        for (NSNumber *initializationValue in initializationValues) {
          unboxedInitializationValues.push_back([initializationValue CGFloatValue]);
        }
        parameterizedObject =
            [factory primitiveParameterizedObjectsFromValues:unboxedInitializationValues];
      });

      it(@"should have correct intrinsic parametric range", ^{
        expect(parameterizedObject.minParametricValue)
            .to.equal(data[kLTPrimitiveParameterizedObjectFactoryMinParametricValue]);
        expect(parameterizedObject.maxParametricValue)
            .to.equal(data[kLTPrimitiveParameterizedObjectFactoryMaxParametricValue]);
      });

      it(@"should return correct value for minimum value of intrinsic parametric range", ^{
        CGFloat value =
            [parameterizedObject floatForParametricValue:parameterizedObject.minParametricValue];
        expect(value).to.beCloseToWithin(initializationValues[range.location], kEpsilon);
      });

      it(@"should return correct value for maximum value of intrinsic parametric range", ^{
        CGFloat value =
            [parameterizedObject floatForParametricValue:parameterizedObject.maxParametricValue];
        expect(value).to.beCloseToWithin(initializationValues[range.location + range.length - 1],
                                         kEpsilon);
      });

      it(@"should return the correct interpolation for values in (0, 1)", ^{
        CGFloat value = [parameterizedObject floatForParametricValue:0.25];
        expect(value).to.beCloseToWithin([expectedValues[0] CGFloatValue], kEpsilon);
        value = [parameterizedObject floatForParametricValue:0.5];
        expect(value).to.beCloseToWithin([expectedValues[1] CGFloatValue], kEpsilon);
        value = [parameterizedObject floatForParametricValue:0.75];
        expect(value).to.beCloseToWithin([expectedValues[2] CGFloatValue], kEpsilon);
      });
    });
  });
});

SharedExamplesEnd

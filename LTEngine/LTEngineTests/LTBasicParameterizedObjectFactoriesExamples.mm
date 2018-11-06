// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBasicParameterizedObjectFactoriesExamples.h"

#import "LTBasicParameterizedObject.h"
#import "LTBasicParameterizedObjectFactories.h"

NSString * const kLTBasicParameterizedObjectFactoryExamples =
    @"LTBasicParameterizedObjectFactoryExamples";
NSString * const kLTBasicParameterizedObjectFactoryClass =
    @"LTBasicParameterizedObjectFactoryClass";
NSString * const kLTBasicParameterizedObjectFactoryNumberOfRequiredValues =
    @"LTBasicParameterizedObjectFactoryNumberOfRequiredValues";
NSString * const kLTBasicParameterizedObjectFactoryMinParametricValue =
    @"LTBasicParameterizedObjectFactoryMinParametricValue";
NSString * const kLTBasicParameterizedObjectFactoryMaxParametricValue =
    @"LTBasicParameterizedObjectFactoryMaxParametricValue";
NSString * const kLTBasicParameterizedObjectFactoryRange =
    @"LTBasicParameterizedObjectFactoryRange";
NSString * const kLTBasicParameterizedObjectFactoryValues =
    @"LTBasicParameterizedObjectFactoryValues";
NSString * const kLTBasicParameterizedObjectFactoryComputedValues =
    @"LTBasicParameterizedObjectFactoryComputedValues";

SharedExamplesBegin(LTBasicParameterizedObjectFactoriesExamples)

static const CGFloat kEpsilon = 1e-4;

sharedExamplesFor(kLTBasicParameterizedObjectFactoryExamples, ^(NSDictionary *data) {
  __block id<LTBasicParameterizedObjectFactory> factory;
  __block NSUInteger numberOfRequiredValues;
  __block NSRange range;

  beforeEach(^{
    factory = [[data[kLTBasicParameterizedObjectFactoryClass] alloc] init];
    numberOfRequiredValues =
        [data[kLTBasicParameterizedObjectFactoryNumberOfRequiredValues] unsignedIntegerValue];
    range = [data[kLTBasicParameterizedObjectFactoryRange] rangeValue];
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

  context(@"computation of basic parameterized objects", ^{
    context(@"invalid API calls", ^{
      it(@"should raise when attempting to compute object from values with invalid count", ^{
        std::vector<CGFloat> valuesWithInvalidCount;
        for (NSUInteger i = 0; i < numberOfRequiredValues + 1; ++i) {
          valuesWithInvalidCount.push_back(0);
        }
        expect(^{
          [factory baseParameterizedObjectsFromValues:valuesWithInvalidCount];
        }).to.raise(NSInvalidArgumentException);
      });
    });

    context(@"valid API calls", ^{
      __block id<LTBasicParameterizedObject> parameterizedObject;
      __block NSArray<NSNumber *> *initializationValues;
      __block NSArray<NSNumber *> *expectedValues;

      beforeEach(^{
        initializationValues = data[kLTBasicParameterizedObjectFactoryValues];
        expectedValues = data[kLTBasicParameterizedObjectFactoryComputedValues];

        std::vector<CGFloat> unboxedInitializationValues;
        for (NSNumber *initializationValue in initializationValues) {
          unboxedInitializationValues.push_back([initializationValue CGFloatValue]);
        }
        parameterizedObject =
            [factory baseParameterizedObjectsFromValues:unboxedInitializationValues];
      });

      it(@"should have correct intrinsic parametric range", ^{
        expect(parameterizedObject.minParametricValue)
            .to.equal(data[kLTBasicParameterizedObjectFactoryMinParametricValue]);
        expect(parameterizedObject.maxParametricValue)
            .to.equal(data[kLTBasicParameterizedObjectFactoryMaxParametricValue]);
      });

      it(@"should return correct value for minimum value of intrinsic parametric range", ^{
        CGFloat value =
            [parameterizedObject floatForParametricValue:parameterizedObject.minParametricValue];
        expect(value).to.beCloseToWithin([expectedValues[0] CGFloatValue], kEpsilon);
      });

      it(@"should return correct value for maximum value of intrinsic parametric range", ^{
        CGFloat value =
            [parameterizedObject floatForParametricValue:parameterizedObject.maxParametricValue];
        expect(value).to.beCloseToWithin([expectedValues[4] CGFloatValue], kEpsilon);
      });

      it(@"should return the correct interpolation for values in (0, 1)", ^{
        CGFloat value = [parameterizedObject floatForParametricValue:0.25];
        expect(value).to.beCloseToWithin([expectedValues[1] CGFloatValue], kEpsilon);
        value = [parameterizedObject floatForParametricValue:0.5];
        expect(value).to.beCloseToWithin([expectedValues[2] CGFloatValue], kEpsilon);
        value = [parameterizedObject floatForParametricValue:0.75];
        expect(value).to.beCloseToWithin([expectedValues[3] CGFloatValue], kEpsilon);
      });
    });
  });
});

SharedExamplesEnd

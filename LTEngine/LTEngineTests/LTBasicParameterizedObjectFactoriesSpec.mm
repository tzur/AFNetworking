// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBasicParameterizedObjectFactories.h"

#import "LTBasicParameterizedObjectFactoriesExamples.h"

SpecBegin(LTBasicParameterizedObjectFactories)

#pragma mark -
#pragma mark LTBasicDegenerateInterpolantFactory
#pragma mark -

itShouldBehaveLike(kLTBasicParameterizedObjectFactoryExamples, @{
  kLTBasicParameterizedObjectFactoryClass: [LTBasicDegenerateInterpolantFactory class],
  kLTBasicParameterizedObjectFactoryNumberOfRequiredValues: @1,
  kLTBasicParameterizedObjectFactoryMinParametricValue: @0,
  kLTBasicParameterizedObjectFactoryMaxParametricValue: @1,
  kLTBasicParameterizedObjectFactoryRange: [NSValue valueWithRange:NSMakeRange(0, 1)],
  kLTBasicParameterizedObjectFactoryValues: @[@1],
  kLTBasicParameterizedObjectFactoryComputedValues: @[@1, @1, @1, @1, @1]
});

#pragma mark -
#pragma mark LTBasicLinearInterpolantFactory
#pragma mark -

itShouldBehaveLike(kLTBasicParameterizedObjectFactoryExamples, @{
  kLTBasicParameterizedObjectFactoryClass: [LTBasicLinearInterpolantFactory class],
  kLTBasicParameterizedObjectFactoryNumberOfRequiredValues: @2,
  kLTBasicParameterizedObjectFactoryMinParametricValue: @0,
  kLTBasicParameterizedObjectFactoryMaxParametricValue: @1,
  kLTBasicParameterizedObjectFactoryRange: [NSValue valueWithRange:NSMakeRange(0, 2)],
  kLTBasicParameterizedObjectFactoryValues: @[@1, @2],
  kLTBasicParameterizedObjectFactoryComputedValues: @[@1, @1.25, @1.5, @1.75, @2]
});

#pragma mark -
#pragma mark LTBasicCatmullRomInterpolantFactory
#pragma mark -

itShouldBehaveLike(kLTBasicParameterizedObjectFactoryExamples, @{
  kLTBasicParameterizedObjectFactoryClass: [LTBasicCubicBezierInterpolantFactory class],
  kLTBasicParameterizedObjectFactoryNumberOfRequiredValues: @4,
  kLTBasicParameterizedObjectFactoryMinParametricValue: @0,
  kLTBasicParameterizedObjectFactoryMaxParametricValue: @1,
  kLTBasicParameterizedObjectFactoryRange: [NSValue valueWithRange:NSMakeRange(0, 4)],
  kLTBasicParameterizedObjectFactoryValues: @[@0.25, @0.5, @(1.0 / 3.0), @(2.0 / 3.0)],
  kLTBasicParameterizedObjectFactoryComputedValues: @[@0.25, @0.3737, @0.4271, @0.4961,
                                                      @(2.0 / 3.0)]
});

#pragma mark -
#pragma mark LTBasicCatmullRomInterpolantFactory
#pragma mark -

itShouldBehaveLike(kLTBasicParameterizedObjectFactoryExamples, @{
  kLTBasicParameterizedObjectFactoryClass: [LTBasicCatmullRomInterpolantFactory class],
  kLTBasicParameterizedObjectFactoryNumberOfRequiredValues: @4,
  kLTBasicParameterizedObjectFactoryMinParametricValue: @0,
  kLTBasicParameterizedObjectFactoryMaxParametricValue: @1,
  kLTBasicParameterizedObjectFactoryRange: [NSValue valueWithRange:NSMakeRange(1, 2)],
  kLTBasicParameterizedObjectFactoryValues: @[@0.25, @0.5, @(1.0 / 3.0), @(2.0 / 3.0)],
  kLTBasicParameterizedObjectFactoryComputedValues: @[@0.5, @0.4759, @0.4115, @0.3496, @(1.0 / 3.0)]
});

#pragma mark -
#pragma mark LTBasicBSplineInterpolantFactory
#pragma mark -

itShouldBehaveLike(kLTBasicParameterizedObjectFactoryExamples, @{
  kLTBasicParameterizedObjectFactoryClass: [LTBasicBSplineInterpolantFactory class],
  kLTBasicParameterizedObjectFactoryNumberOfRequiredValues: @4,
  kLTBasicParameterizedObjectFactoryMinParametricValue: @0,
  kLTBasicParameterizedObjectFactoryMaxParametricValue: @1,
  kLTBasicParameterizedObjectFactoryRange: [NSValue valueWithRange:NSMakeRange(1, 2)],
  kLTBasicParameterizedObjectFactoryValues: @[@0.25, @0.5, @(1.0 / 3.0), @(2.0 / 3.0)],
  kLTBasicParameterizedObjectFactoryComputedValues: @[@0.430556, @0.430339, @0.418403, @0.409071,
                                                      @0.416667]
});

SpecEnd

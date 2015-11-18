// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTPrimitiveParameterizedObjectFactories.h"

#import "LTPrimitiveParameterizedObjectFactoriesExamples.h"

SpecBegin(LTPrimitiveParameterizedObjectFactories)

#pragma mark -
#pragma mark LTPrimitiveDegenerateInterpolantFactory
#pragma mark -

itShouldBehaveLike(kLTPrimitiveParameterizedObjectFactoryExamples, @{
  kLTPrimitiveParameterizedObjectFactoryClass: [LTPrimitiveDegenerateInterpolantFactory class],
  kLTPrimitiveParameterizedObjectFactoryNumberOfRequiredValues: @1,
  kLTPrimitiveParameterizedObjectFactoryMinParametricValue: @0,
  kLTPrimitiveParameterizedObjectFactoryMaxParametricValue: @1,
  kLTPrimitiveParameterizedObjectFactoryRange: [NSValue valueWithRange:NSMakeRange(0, 1)],
  kLTPrimitiveParameterizedObjectFactoryValues: @[@1],
  kLTPrimitiveParameterizedObjectFactoryComputedValues: @[@1, @1, @1]
});

#pragma mark -
#pragma mark LTPrimitiveLinearInterpolantFactory
#pragma mark -

itShouldBehaveLike(kLTPrimitiveParameterizedObjectFactoryExamples, @{
  kLTPrimitiveParameterizedObjectFactoryClass: [LTPrimitiveLinearInterpolantFactory class],
  kLTPrimitiveParameterizedObjectFactoryNumberOfRequiredValues: @2,
  kLTPrimitiveParameterizedObjectFactoryMinParametricValue: @0,
  kLTPrimitiveParameterizedObjectFactoryMaxParametricValue: @1,
  kLTPrimitiveParameterizedObjectFactoryRange: [NSValue valueWithRange:NSMakeRange(0, 2)],
  kLTPrimitiveParameterizedObjectFactoryValues: @[@1, @2],
  kLTPrimitiveParameterizedObjectFactoryComputedValues: @[@1.25, @1.5, @1.75]
});

#pragma mark -
#pragma mark LTPrimitiveCatmullRomInterpolantFactory
#pragma mark -

itShouldBehaveLike(kLTPrimitiveParameterizedObjectFactoryExamples, @{
  kLTPrimitiveParameterizedObjectFactoryClass: [LTPrimitiveCatmullRomInterpolantFactory class],
  kLTPrimitiveParameterizedObjectFactoryNumberOfRequiredValues: @4,
  kLTPrimitiveParameterizedObjectFactoryMinParametricValue: @0,
  kLTPrimitiveParameterizedObjectFactoryMaxParametricValue: @1,
  kLTPrimitiveParameterizedObjectFactoryRange: [NSValue valueWithRange:NSMakeRange(1, 2)],
  kLTPrimitiveParameterizedObjectFactoryValues: @[@0.25, @0.5, @(1.0 / 3.0), @(2.0 / 3.0)],
  kLTPrimitiveParameterizedObjectFactoryComputedValues: @[@0.4759, @0.4115, @0.3496]
});

SpecEnd

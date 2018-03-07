// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObjectType.h"

#import "LTBasicParameterizedObjectFactories.h"

SpecBegin(LTParameterizedObjectType)

it(@"should return a factory of the correct class for each type", ^{
  NSDictionary<LTParameterizedObjectType *, Class> *typeToClass = @{
    $(LTParameterizedObjectTypeDegenerate): [LTBasicDegenerateInterpolantFactory class],
    $(LTParameterizedObjectTypeLinear): [LTBasicLinearInterpolantFactory class],
    $(LTParameterizedObjectTypeCubicBezier): [LTBasicCubicBezierInterpolantFactory class],
    $(LTParameterizedObjectTypeCatmullRom): [LTBasicCatmullRomInterpolantFactory class],
    $(LTParameterizedObjectTypeBSpline): [LTBasicBSplineInterpolantFactory class]
  };

  [LTParameterizedObjectType enumerateEnumUsingBlock:^(LTParameterizedObjectType *value) {
    expect([[value factory] class]).to.equal(typeToClass[value]);
  }];
});

SpecEnd

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObjectType.h"

#import "LTBasicParameterizedObjectFactories.h"

NS_ASSUME_NONNULL_BEGIN

/// Mapping of \c LTParameterizedObjectType to the corresponding factory of basic parameterized
/// objects.
typedef NSDictionary<LTParameterizedObjectType *,
                     id<LTBasicParameterizedObjectFactory>> LTParameterizedObjectTypeMapping;

LTEnumImplement(NSUInteger, LTParameterizedObjectType,
  LTParameterizedObjectTypeDegenerate,
  LTParameterizedObjectTypeLinear,
  LTParameterizedObjectTypeCubicBezier,
  LTParameterizedObjectTypeCatmullRom,
  LTParameterizedObjectTypeBSpline
);

@implementation LTParameterizedObjectType (Type)

- (id<LTBasicParameterizedObjectFactory>)factory {
  return [[self class] factoryMapping][self];
}

+ (LTParameterizedObjectTypeMapping *)factoryMapping {
  static LTParameterizedObjectTypeMapping *factoryMapping;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    factoryMapping = @{
      $(LTParameterizedObjectTypeDegenerate): [[LTBasicDegenerateInterpolantFactory alloc] init],
      $(LTParameterizedObjectTypeLinear): [[LTBasicLinearInterpolantFactory alloc] init],
      $(LTParameterizedObjectTypeCubicBezier): [[LTBasicCubicBezierInterpolantFactory alloc] init],
      $(LTParameterizedObjectTypeCatmullRom): [[LTBasicCatmullRomInterpolantFactory alloc] init],
      $(LTParameterizedObjectTypeBSpline): [[LTBasicBSplineInterpolantFactory alloc] init]
    };
  });

  return factoryMapping;
}

@end

NS_ASSUME_NONNULL_END

// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@protocol LTBasicParameterizedObjectFactory;

/// Value class representing the type of certain parameterized objects.
LTEnumDeclare(NSUInteger, LTParameterizedObjectType,
  LTParameterizedObjectTypeDegenerate,
  LTParameterizedObjectTypeLinear,
  LTParameterizedObjectTypeCatmullRom,
  LTParameterizedObjectTypeBSpline
);

/// Category augmenting the \c LTParameterizedObjectType class with functionality to return a
/// factory for creating basic parameterized objects of the represented type.
@interface LTParameterizedObjectType (Type)

/// Returns the factory of basic parameterized objects corresponding to this type.
- (id<LTBasicParameterizedObjectFactory>)factory;

@end

NS_ASSUME_NONNULL_END

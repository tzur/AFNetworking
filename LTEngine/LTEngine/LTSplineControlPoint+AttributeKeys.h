// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSplineControlPoint.h"

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting the \c LTSplineControlPoint class with the ability to provide strings
/// commonly used as keys of the \c attributes dictionary.
@interface LTSplineControlPoint (AttributeKeys)

/// Returns the key used to describe a radius attribute associated with an
// \c LTSplineControlPoint.
+ (NSString *)keyForRadius;

/// Returns the key used to describe a force attribute associated with an
// \c LTSplineControlPoint.
+ (NSString *)keyForForce;

@end

NS_ASSUME_NONNULL_END

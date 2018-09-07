// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSplineControlPoint.h"

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting the \c LTSplineControlPoint class with the ability to provide strings
/// commonly used as keys of the \c attributes dictionary.
@interface LTSplineControlPoint (AttributeKeys)

/// Returns the key used to describe an attribute representing the radius, in floating-point pixel
/// units of the content coordinate system, associated with the receiver.
+ (NSString *)keyForRadius;

/// Returns the key used to describe an attribute representing the force associated with the
/// receiver.
+ (NSString *)keyForForce;

/// Returns the key used to describe an attribute representing the speed, in point units of the
/// screen coordinate system, of the receiver.
+ (NSString *)keyForSpeedInScreenCoordinates;

@end

NS_ASSUME_NONNULL_END

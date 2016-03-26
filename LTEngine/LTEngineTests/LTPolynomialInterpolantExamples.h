// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTInterpolatableObject.h"

/// Interpolants examples shared group name.
extern NSString * const LTPolynomialInterpolantExamples;

/// Interpolants factory examples shared group name.
extern NSString * const LTPolynomialInterpolantFactoryExamples;

/// Class object of LTPolynomialInterpolant subclass to test.
extern NSString * const LTPolynomialInterpolantClass;

/// Instance of the LTPolynomialInterpolant factory to test.
extern NSString * const LTPolynomialInterpolantFactory;

/// Used to test the various interpolants.
@interface InterpolatedObject : NSObject <LTInterpolatableObject>

@property (nonatomic) double propertyNotToInterpolate;
@property (nonatomic) float floatToInterpolate;
@property (nonatomic) double doubleToInterpolate;
@property (nonatomic) CGPoint pointToInterpolate;

@end

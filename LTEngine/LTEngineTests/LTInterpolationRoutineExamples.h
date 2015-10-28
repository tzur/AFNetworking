// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTInterpolatedObject.h"

/// Interpolants examples shared group name.
extern NSString * const kLTInterpolationRoutineExamples;

/// Interpolants factory examples shared group name.
extern NSString * const kLTInterpolationRoutineFactoryExamples;

/// Class object of LTPolynomialInterpolant subclass to test.
extern NSString * const kLTInterpolationRoutineClass;

/// Instance of the LTPolynomialInterpolant factory to test.
extern NSString * const kLTInterpolationRoutineFactory;

/// Used to test the various interpolants.
@interface InterpolatedObject : NSObject <LTInterpolatedObject>

@property (nonatomic) double propertyNotToInterpolate;
@property (nonatomic) float floatToInterpolate;
@property (nonatomic) double doubleToInterpolate;
@property (nonatomic) CGPoint pointToInterpolate;

@end

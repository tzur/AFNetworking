// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTInterpolatedObject.h"

/// Interpolation routines examples shared group name.
extern NSString * const kLTInterpolationRoutineExamples;

/// Class object of LTInterpolationRoutine subclass to test.
extern NSString * const kLTInterpolationRoutineClass;

/// Used to test the various interpolation routines.
@interface InterpolatedObject : NSObject <LTInterpolatedObject>

@property (nonatomic) double propertyNotToInterpolate;
@property (nonatomic) float floatToInterpolate;
@property (nonatomic) double doubleToInterpolate;
@property (nonatomic) CGPoint pointToInterpolate;

@end

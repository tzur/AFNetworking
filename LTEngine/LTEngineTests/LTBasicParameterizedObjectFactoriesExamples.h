// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Group name of shared tests for factories conforming to the
/// \c LTBasicParameterizedObjectFactory protocol.
extern NSString * const kLTBasicParameterizedObjectFactoryExamples;

/// Dictionary key to the \c class of the factory to test.
extern NSString * const kLTBasicParameterizedObjectFactoryClass;

/// Dictionary key to \c NSArray<NSNumber *> required by the factory to test in order to construct
/// basic parameterized objects.
extern NSString * const kLTBasicParameterizedObjectFactoryNumberOfRequiredValues;

/// Dictionary key to \c CGFloat representing the minimum value of the intrinsic parametric range of
/// the object constructed by the factory to test.
extern NSString * const kLTBasicParameterizedObjectFactoryMinParametricValue;

/// Dictionary key to \c CGFloat representing the maximum value of the intrinsic parametric range of
/// the object constructed by the factory to test.
extern NSString * const kLTBasicParameterizedObjectFactoryMaxParametricValue;

/// Dictionary key to \c NSRange, representing the intrinsic parametric range of the object
/// constructed by the factory to test.
extern NSString * const kLTBasicParameterizedObjectFactoryRange;

/// Dictionary key to \c NSArray<NSNumber *>  containing values required by the factory to test in
/// order to construct basic parameterized objects.
extern NSString * const kLTBasicParameterizedObjectFactoryValues;

/// Dictionary key to \c NSArray<NSNumber *> containing values computed by the basic parameterized
/// object (created by the factory to test) for parametric values {0.25, 0.5, 0.75}.
extern NSString * const kLTBasicParameterizedObjectFactoryComputedValues;

// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObject.h"

@class LTParameterizationKeyToValues;

NS_ASSUME_NONNULL_BEGIN

/// Object used in sampler tests. Calls to the \c mappingForParametricValues: method with some
/// parameters \c values return the \c returnedMapping of this instance if the given \c values equal
/// the \c expectedParametricValues of this instance and \c nil, otherwise. Calls to the
/// \c mappingForParametricValue: method alway returns \c nil. Calls to the
/// \c floatForParametricValue: method always return \c 0. Calls to the
/// \c floatsForParametricValues: method always return \c {}.
@interface LTSamplerTestParameterizedObject : NSObject <LTParameterizedObject>

/// Minimum parametric value. See \c LTParameterizedObject protocol for more details.
@property (nonatomic) CGFloat minParametricValue;

/// Maximum parametric value. See \c LTParameterizedObject protocol for more details.
@property (nonatomic) CGFloat maxParametricValue;

/// Values expected as parameters of the \c mappingForParametricValues: method. Upon calls to the
/// method with different values, \c nil is returned.
@property (nonatomic) std::vector<CGFloat> expectedParametricValues;

/// Mapping returned by the \c mappingForParametricValues: method when calling with values equaling
/// \c expectedParametricValues.
@property (nonatomic) LTParameterizationKeyToValues *returnedMapping;

@end

NS_ASSUME_NONNULL_END

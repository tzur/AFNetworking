// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInterval.h"
#import "LTParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTFloatSet;

/// Protocol which should be implemented by immutable value classes constituting the output of an
/// \c LTSampler object.
@protocol LTSamplerOutput <NSObject>

/// Parametric values at which the parameterized object has been sampled. Is empty if no values were
/// sampled.
@property (readonly, nonatomic) CGFloats sampledParametricValues;

/// Mapping from \c parameterizationKeys of the sampled parameterized object to sampled values.
/// \c nil if no values were sampled.
@property (readonly, nonatomic) LTParameterizationKeyToValues *mappingOfSampledValues;

@end

/// Immutable object sampling a parameterized object according to values from a given \c LTFloatSet,
/// in a given interval. The parameterized object is provided upon initialization. The output of a
/// sampling pass consists of the parametric values at which the given parameterized object has been
/// sampled as well as the actual sampling result.
@interface LTSampler : NSObject

/// Samples the given \c parameterizedObject according to the values of the given \c discreteSet,
/// belonging to the given \c interval. Returns a tuple consisting of a) the values at which the
/// \c parameterizedObject has been sampled, and b) the mapping from keys of the sampled
/// \c parameterizedObject to the corresponding values.
- (id<LTSamplerOutput>)samplesFromParameterizedObject:(id<LTParameterizedObject>)parameterizedObject
                                     usingDiscreteSet:(id<LTFloatSet>)discreteSet
                                             interval:(const lt::Interval<CGFloat> &)interval;

@end

NS_ASSUME_NONNULL_END

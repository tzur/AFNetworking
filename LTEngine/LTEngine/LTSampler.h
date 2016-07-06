// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInterval.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTFloatSet, LTParameterizedObject, LTSampleValues;

/// Immutable object sampling a parameterized object according to values from a given \c LTFloatSet,
/// in a given interval. The parameterized object is provided upon initialization. The output of a
/// sampling pass consists of the parametric values at which the given parameterized object has been
/// sampled as well as the actual sampling result.
@interface LTSampler : NSObject

/// Samples the given \c parameterizedObject according to the values of the given \c discreteSet,
/// belonging to the given \c interval. Returns a tuple consisting of the values at which the
/// \c parameterizedObject has been sampled, and the mapping from keys of the sampled
/// \c parameterizedObject to the corresponding values.
- (id<LTSampleValues>)samplesFromParameterizedObject:(id<LTParameterizedObject>)parameterizedObject
                                    usingDiscreteSet:(id<LTFloatSet>)discreteSet
                                            interval:(const lt::Interval<CGFloat> &)interval;

@end

NS_ASSUME_NONNULL_END

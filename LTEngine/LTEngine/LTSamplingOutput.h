// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTSamplingScheme;

/// Protocol which should be implemented by immutable value objects constituting the output of
/// \c LTSamplingScheme objects.
@protocol LTSamplingOutput <NSObject>

/// Parametric values at which the parameterized object has been sampled. Is empty if no values were
/// sampled.
@property (readonly, nonatomic) CGFloats sampledParametricValues;

/// Mapping from \c parameterizationKeys of the sampled parameterized object to sampled values.
/// \c nil if no values were sampled.
@property (readonly, nonatomic) LTParameterizationKeyToValues *mappingOfSampledValues;

/// Sampling scheme describing the desired continuation of the sampling applied to create this
/// output.
@property (readonly, nonatomic) id<LTSamplingScheme> samplingScheme;

@end

/// Object representing the output of a sampling of a parameterized object.
@interface LTSamplingOutput : NSObject <LTSamplingOutput>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c sampledParametricValues, \c mapping and the given
/// \c samplingScheme. The given \c sampledParametricValues are the parametric values at which the
/// parameterized object has been sampled. The given \c mapping constitutes the mapping from keys of
/// the sampled parameterized object to sampled values. Should be \c nil if no values were sampled.
/// The given \c samplingScheme describes the desired continuation of future sampling.
- (instancetype)initWithSampledParametricValues:(const CGFloats &)sampledParametricValues
                                        mapping:(nullable LTParameterizationKeyToValues *)mapping
                                 samplingScheme:(id<LTSamplingScheme>)samplingScheme
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

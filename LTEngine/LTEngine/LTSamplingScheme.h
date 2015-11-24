// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@protocol LTSamplingOutput;

/// Protocol which should be implemented by immutable value objects representing and executing a
/// certain sampling scheme. A sampling scheme is a description of how a given parameterized object
/// should be sampled. The output of a sampling scheme, \c S, includes the parametric values at
/// which a given parameterized object has been sampled, the actual sampling result, and a possibly
/// different sampling scheme that can be used to continue the sampling from the point where \c S
/// stopped. Since objects that implement this protocol must be immutable, it is guaranteed that
/// state is only transferred via the sampling scheme provided in the output.
///
/// Example 1: An object conforming to this protocol may define a scheme requiring sampling of a
/// given parameterized object at \c x equidistant parametric values, starting at the
/// \c minParametricValue of the parameterized object. Upon sample retrieval, it may return as part
/// of the result an updated sampling scheme which allows the continuation of the sampling starting
/// at the corresponding next (\c x+1 th) parametric value.
///
/// Example 2: An object conforming to this protocol may define a scheme requiring sampling of a
/// given parameterized object at parametric values with increasing distance, starting at a certain
/// parametric value.
@protocol LTSamplingScheme <NSObject>

/// Samples a given parameterized \c object according to the sampling scheme represented by this
/// object and returns a triple consisting of a) the parametric values at which the parameterized
/// \c object has been sampled, b) the mapping from keys of the sampled parameterized \c object to
/// the corresponding values, and c) the sampling scheme to apply in consecutive samplings. The
/// returned sampling scheme might differ from this instance; this is usually the case, if the
/// sampling scheme has some internal state that reflects the progress of sampling.
- (id<LTSamplingOutput>)samplesFromParameterizedObject:(id<LTParameterizedObject>)object;

@end

NS_ASSUME_NONNULL_END

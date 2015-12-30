// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTReparameterization.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTParameterizedObject;

/// Category augmenting \c LTReparameterization with functionality to compute an approximate
/// arc-length reparameterization for a given parameterized object, in 2D Euclidean space. The
/// approximate arc-length is computed by sampling the parameterized object using equidistant
/// parametric values, covering the entire intrinsic parametric range of the object. The sampling
/// results in piecewise linear segments whose lengths are used as arc-length approximation.
@interface LTReparameterization (ArcLength)

/// Returns a new instance constituting an approximate arc-length reparameterization, in 2D
/// Euclidean space, for the given parameterized \c object. The reparameterization is computed by
/// approximating the parameterized object with piecewise linear segments. The mapping with which
/// the returned reparameterization is initialized is the ordered collection of the sums of line
/// segment lengths.
///
/// @param \c object is the object for which the arc-length reparameterization is computed.
///
/// @param \c numberOfSamples represents the number of equidistant parametric values at which the
/// intrinsic parametric range of the given parametrized \c object is sampled. It also constitutes
/// the size of the mapping constructed for initialization of the returned \c LTReparameterization.
/// Must be greater than \c 1.
///
/// @param \c minParametricValue constitutes the minimum parametric value used by the returned
/// instance.
///
/// @param \c xKey represents the parameterization key which maps to the x-coordinates according to
/// which the arc-length should be computed. Must be among the \c parameterizationKeys of the given
/// \c object.
///
/// @param \c yKey represents the parameterization key which maps to the y-coordinates according to
/// which the arc-length should be computed. Must be among the \c parameterizationKeys of the given
/// \c object.
///
/// @note the \c numberOfSamples affects the performance of value retrieval of the returned
/// reparameterization. Refer to \c LTReparameterization for exact time complexities.
+ (instancetype)arcLengthReparameterizationForObject:(id<LTParameterizedObject>)object
                                     numberOfSamples:(NSUInteger)numberOfSamples
                                  minParametricValue:(CGFloat)minParametricValue
                   parameterizationKeyForXCoordinate:(NSString *)xKey
                   parameterizationKeyForYCoordinate:(NSString *)yKey;

@end

NS_ASSUME_NONNULL_END

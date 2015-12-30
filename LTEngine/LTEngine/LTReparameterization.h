// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTPrimitiveParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

/// Primitive parameterized object constituting a discretized, bijective, monotonous mapping of the
/// intrinsic parametric range [\c minParametricValue, \c maxParametricValue] to the canonical range
/// [\c 0, \c 1].
///
/// @note A possible use case of this object is the reparameterization of a parameterized object of
/// geometric nature to its arc-length parameterization. Value retrieval via the
/// \c floatForParametricValue: method is in \c O(log n), where \c n is the size of the \c mapping
/// provided upon initialization.
@interface LTReparameterization : NSObject <LTPrimitiveParameterizedObject>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c mapping. The given \c mapping must contain at least two values.
/// The first value of the \c mapping is used as \c minParametricValue, while the last value of the
/// \c mapping is used as \c maxParametricValue. The \c mapping must be strictly monotonically
/// increasing. The \c i th interval (\c i in \c{1,...,n}, where \c n=mapping.size()-1) of the
/// \c mapping is mapped to the interval [\c(i-1)/n, \c i/n]. Parametric values smaller than
/// \c minParametricValue are linearly mapped according to the first interval of the given
/// \c mapping. Analogously, parametric values greater than \c maxParametricValue are linearly
/// mapped according to the last interval.
- (instancetype)initWithMapping:(CGFloats)mapping NS_DESIGNATED_INITIALIZER;

/// Returns a new instance with a shifted version of the \c mapping of the receiver. All values of
/// the \c mapping of the returned instance are shifted by the given \c offset, in comparison to the
/// \c mapping of the receiver. The receiver is not modified.
- (LTReparameterization *)reparameterizationShiftedByOffset:(CGFloat)offset;

@end

NS_ASSUME_NONNULL_END

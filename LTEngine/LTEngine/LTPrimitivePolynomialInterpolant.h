// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Object interpolating a given value according to a polynomial whose coefficients are provided
/// upon initialization.
@interface LTPrimitivePolynomialInterpolant : NSObject

/// Initializes with the given \c coefficients which must consist of at least one coefficient.
- (instancetype)initWithCoefficients:(CGFloats)coefficients;

/// Returns for a given \c value the \c sum_{i=0}^{n-1}(c_i*value^(n-1-i)), where \c n is the number
/// of coefficients and \c x_i is the \c i th coefficient.
- (CGFloat)interpolatedValueForValue:(CGFloat)value;

/// Coefficients determining the polynomial used for interpolation.
@property (readonly, nonatomic) CGFloats coefficients;

@end

NS_ASSUME_NONNULL_END

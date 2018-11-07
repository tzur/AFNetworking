// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBasicParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

/// Basic parameterized object interpolating a given value according to a polynomial whose
/// coefficients are provided upon initialization. Calls to \c floatForParametricValue: with a
/// given \c value return \c sum_{i=0}^{n-1}(c_i*value^(n-1-i)), where \c n is the number of
/// coefficients and \c x_i is the \c i th coefficient. The intrinsic parametric range of this
/// object is \c [0,1].
@interface LTBasicPolynomialInterpolant : NSObject <LTBasicParameterizedObject>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c coefficients which must consist of at least one coefficient.
- (instancetype)initWithCoefficients:(std::vector<CGFloat>)coefficients NS_DESIGNATED_INITIALIZER;

/// Coefficients determining the polynomial used for interpolation.
@property (readonly, nonatomic) std::vector<CGFloat> coefficients;

@end

NS_ASSUME_NONNULL_END

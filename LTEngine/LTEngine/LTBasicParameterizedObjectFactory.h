// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@protocol LTBasicParameterizedObject;

/// Protocol which should be implemented by immutable objects creating objects conforming to the
/// \c \c LTBasicParameterizedObject protocol.
@protocol LTBasicParameterizedObjectFactory <NSObject>

/// Returns a basic parameterized object with the given \c values.
- (id<LTBasicParameterizedObject>)baseParameterizedObjectsFromValues:(std::vector<CGFloat>)values;

/// Returns the number of values required to create a basic parameterized object using this
/// factory. Returned number is positive.
+ (NSUInteger)numberOfRequiredValues;

/// Returns the range, in terms of the input \c values array, representing the intrinsic parametric
/// range of the basic parameterized object returned by this factory. In particular, the range
/// determines the values \c A and \c B in the given \c values s.t. \c A corresponds to parametric
/// value \c minParametricValue and \c B corresponds to parametric value \c maxParametricValue of
/// the returned basic parameterized objects. \c A equals
/// \c values[intrinsicParametricRange.location] and \c B equals
/// \c values[intrinsicParametricRange.location + intrinsicParametricRange.length - 1].
///
/// The \c length of the returned range is greater than \c 0. The sum of the \c location and the
/// \c length of the returned range are smaller than or equal to \c numberOfRequiredValues.
+ (NSRange)intrinsicParametricRange;

@end

NS_ASSUME_NONNULL_END

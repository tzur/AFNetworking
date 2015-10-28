// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Abstract polynomial interpolant class, used to polynomially interpolate objects conforming to
/// the \c LTInterpolatableObject protocol according to key-frame objects given upon initialization.
/// The "heavier" computation (calculating the polynomial coefficients) is performed on
/// initialization, so querying for values at a given key point in range [0,1] is fast (estimating a
/// polynom at a given point).
@interface LTPolynomialInterpolant : NSObject

/// Returns the expected number of key frames for the interpolant.
///
/// @note Subclasses must implement this method and return the number of keyframes necessary for the
/// type of interpolation they implement.
+ (NSUInteger)expectedKeyFrames;

/// Returns the range (in the input keyframes array) of the interval interpolated by the keys [0,1].
///
/// @note Subclasses must implement this method and return the appropriate range.
+ (NSRange)rangeOfIntervalInWindow;

/// Initializes the interpolant with the given keyframes, validating the count and type of keyframes
/// provided (all of the same class, and conform to the \c LTInterpolatableObject protocol).
- (instancetype)initWithKeyFrames:(NSArray *)keyFrames;

/// Returns the interpolated result (object of the same class of the key frames) at the given \c key
/// (must be in range [0,1]). Properties that are not interpolated will be have their default value.
- (id)valueAtKey:(CGFloat)key;

/// Returns the interpolated property at the given \c key (must be in range [0,1]).
- (NSNumber *)valueOfPropertyNamed:(NSString *)name atKey:(CGFloat)key;

/// Returns a vector of the interpolated properties at the given keys (must be in range [0,1]).
///
/// @note This is an optimization greately improving the performance of scenarios where a single
/// property needs to be estimated on lots of keys.
- (CGFloats)valuesOfCGFloatPropertyNamed:(NSString *)name atKeys:(const CGFloats &)keys;

/// Returns a dictionary mapping each property to an \c NSArray with its polynomial coefficients (as
/// \c NSNumbers).
/// Subclasses must implement this abstract method and calculate the coefficients according to the
/// interpolation method they implement and the given key frames. The coefficients should be
/// ordered from the highest power to the lowest.
///
/// @note it is safe to assume that \c keyFrames contains the expected number of objects, and that
/// all of them are of the same type and conform to the \c LTInterpolatableObject protocol.
- (NSDictionary *)calculateCoefficientsForKeyFrames:(NSArray *)keyFrames;

@end

/// Abstract factory for \c LTPolynomialInterpolant subclasses.
@protocol LTPolynomialInterpolantFactory <NSObject>

/// Initializes and returns a polynomial interpolant with the given keyframes.
- (LTPolynomialInterpolant *)interpolantWithKeyFrames:(NSArray *)keyFrames;

/// Returns the expected number of key frames for the polynomial interpolant created by the factory.
- (NSUInteger)expectedKeyFrames;

/// Returns the range (in the input keyframes array) of the interval interpolated by the keys [0,1].
- (NSRange)rangeOfIntervalInWindow;

@end

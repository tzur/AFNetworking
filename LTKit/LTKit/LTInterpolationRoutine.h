// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Abstract interpolation routine class, used to interpolate objects conforming to the
/// \c LTInterpolatedObject protocol according to key-frame objects given upon initialization.
/// The "heavier" computation (calculating the polynomial coefficients) is performed on
/// initialization, so querying for values at a given key point in range [0,1] is fast (estimating a
/// polynom at a given point).
@interface LTInterpolationRoutine : NSObject

/// Returns the expected number of key frames for the interpolation routine.
///
/// @note Subclasses must implement this method and return the number of keyframes necessary for the
/// type of interpolation they implement.
+ (NSUInteger)expectedKeyFrames;

/// Initializes the interpolation routine with the given keyframes, validating the count and type of
/// keyframes provided (all of the same class, and conform to the \c LTInterpolatedObject protocol).
- (instancetype)initWithKeyFrames:(NSArray *)keyFrames;

/// Returns the interpolated result (object of the same class of the key frames) at the given \c key
/// (must be in range [0,1]). Properties that are not interpolated will be have their default value.
- (id)valueAtKey:(CGFloat)key;

/// Returns a dictionary mapping each property to an \c NSArray with its polynomial coefficients (as
/// \c NSNumbers).
/// Subclasses must implement this abstract method and calculate the coefficients according to the
/// interpolation method they implement and the given key frames. The coefficients should be
/// ordered from the highest power to the lowest.
///
/// @note it is safe to assume that \c keyFrames contains the expected number of objects, and that
/// all of them are of the same type and conform to the \c LTInterpolatedObject protocol.
- (NSDictionary *)calculateCoefficientsForKeyFrames:(NSArray *)keyFrames;

@end

// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// The \c LTInterpolatedObject protocol declares the methods that a class must implement so that
/// instances of that class can be interpolated.
@protocol LTInterpolatedObject <NSObject>

@optional

/// Initializes the object while setting the interpolated properties given as a dictionary mapping
/// property names (\cNSString) to values (\c NSNumber).
///
/// @note In case this method is not implemented, the standard initializer will be used and all the
/// interpolated properties will be set after the initialization.
- (instancetype)initWithInterpolatedProperties:(NSDictionary *)properties;

@required

/// Returns an array of names of the properties that should be interpolated. All properties must be
/// of a primitive floating point type.
///
/// @note It is possible to interpolate complex properties (such as \c CGPoint for example) by
/// creating helper properties for setting and getting their components. See \c LTTouchPoint.
- (NSArray *)propertiesToInterpolate;

@end

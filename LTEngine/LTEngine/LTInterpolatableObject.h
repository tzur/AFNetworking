// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Protocol which should be implemented by objects allowing the creation of instances with
/// interpolated properties.
@protocol LTInterpolatableObject <NSObject>

/// Initializes the object with the given \c properties. The keys of the given \c properties must be
/// a subset of the \c propertiesToInterpolate.
- (instancetype)initWithInterpolatedProperties:(NSDictionary<NSString *, NSNumber *> *)properties;

/// Returns a set of names of the properties to interpolate. All properties must be of a primitive
/// floating-point type.
///
/// @important Any class implementing this protocol must guarantee that the returned set must be the
/// same for all its instances.
/// @note It is possible to interpolate complex properties (such as \c CGPoint for example) by
/// creating helper properties for setting and getting their components. See \c LTPainterPoint.
- (NSSet<NSString *> *)propertiesToInterpolate;

@end

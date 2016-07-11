// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInterpolatableObject.h"

NS_ASSUME_NONNULL_BEGIN

/// Immutable value object used as a control point of a 2D Euclidean spline.
///
/// @important This class overrides the \c valueForKey: method declared in \c NSKeyValueCoding. If
/// the \c attributes provided upon initialization contain a given \c key, the corresponding value
/// is returned. Otherwise, the regular implementation of \c super is called.
@interface LTSplineControlPoint : NSObject <LTInterpolatableObject, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c timestamp and the given \c location. The given \c location must
/// not be \c CGPointNull.
- (instancetype)initWithTimestamp:(NSTimeInterval)timestamp location:(CGPoint)location;

/// Initializes with the given \c timestamp, \c location, and the given \c attributes. The given
/// \c location must not be \c CGPointNull. The keys in the given \c attributes must be different
/// from the keys of the properties of this class. The values in the given \c attributes must be
/// boxed \c CGFloat values. The \c propertiesToInterpolate of the returned instance are the union
/// of <tt>{xCoordinateOfLocation, yCoordinateOfLocation}</tt> and <tt>[attributes allKeys]</tt>.
- (instancetype)initWithTimestamp:(NSTimeInterval)timestamp location:(CGPoint)location
                       attributes:(NSDictionary<NSString *, NSNumber *> *)attributes
    NS_DESIGNATED_INITIALIZER;

/// Returns \c YES if the receiver \c isEqual: to the given \c controlPoint, ignoring the
/// \c timestamp.
- (BOOL)isEqualIgnoringTimestamp:(LTSplineControlPoint *)controlPoint;

/// Timestamp of this control point.
@property (readonly, nonatomic) NSTimeInterval timestamp;

/// Location of this object in the corresponding 2D Euclidean coordinate system. Equals
/// \c CGPointMake(xCoordinateOfLocation, yCoordinateOfLocation).
@property (readonly, nonatomic) CGPoint location;

/// x-coordinate of the location of this object in the corresponding 2D Euclidean coordinate system.
/// Provided as primitive to enable straightforward interpolation. Keypath is among
/// \c propertiesToInterpolate.
@property (readonly, nonatomic) CGFloat xCoordinateOfLocation;

/// y-coordinate of the location of this object in the corresponding 2D Euclidean coordinate system.
/// Provided as primitive to enable straightforward interpolation. Keypath is among
/// \c propertiesToInterpolate.
@property (readonly, nonatomic) CGFloat yCoordinateOfLocation;

/// Additional attributes associated with this object.
@property (readonly, nonatomic, nullable) NSDictionary<NSString *, NSNumber *> *attributes;

@end

NS_ASSUME_NONNULL_END

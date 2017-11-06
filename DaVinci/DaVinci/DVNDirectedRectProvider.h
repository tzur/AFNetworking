// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTKit/LTValueObject.h>

#import "DVNGeometryProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Model of a \c DVNGeometryProvider object providing directed, rectangular, not necessarily
/// axis-aligned quads. Calling the \c valuesFromSamples:end: method of the geometry provider
/// retrievable from this model with given \c samples, yields
/// <tt>dvn::GeometryValues(quads, indices, samples)</tt>, where \c quads is a vector of the size of
/// \c samples.sampledParametricValues, and \c indices is the vector <tt>{0, 1, 2, 3, ...}</tt> of
/// the same length. All returned quads are rectangular and have the same dimensions but are rotated
/// according to the direction computed from the samples (and the corresponding preceding sample),
/// except for the first one which is constructed as follows:
///
/// If more than one sample are provided, the first quad is rotated in the same way the second one
/// is rotated. If one sample is provided and the \c end indication is \c NO, the first quad is
/// axis-aligned and has size <tt>(0, 0)</tt>. Otherwise, the first quad is axis-aligned and its
/// size equals the \c size of this instance.
///
/// The center of each quad has the coordinates retrieved from the given \c samples at keys
/// \c xCoordinateKey and \c yCoordinateKey.
///
/// @important: Any \c id<LTSampleValues> object used as parameter of the \c valuesFromSamples:end
/// method must have the keys \c xCoordinateKey and \c yCoordinateKey.
@interface DVNDirectedRectProviderModel : LTValueObject <DVNGeometryProviderModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c size and default values for \c xCoordinateKey and
/// \c yCoordinateKey. Any quad provided by this object have the given \c size. Both dimensions of
/// the given \c size must be greater than \c 0.
- (instancetype)initWithSize:(CGSize)size;

/// Initializes with the given \c size, \c xCoordinateKey and \c yCoordinateKey. Any quad provided
/// by this object have the given \c size. Both dimensions of the given \c size must be greater than
/// \c 0. The \c length of the given \c xCoordinateKey and \c yCoordinateKey must be positive and
/// the strings must be distinct from each other.
- (instancetype)initWithSize:(CGSize)size xCoordinateKey:(NSString *)xCoordinateKey
              yCoordinateKey:(NSString *)yCoordinateKey NS_DESIGNATED_INITIALIZER;

/// Key any \c LTParameterizationKeyToValues object given to this object must contain in order to
/// retrieve the x-coordinates of the centers of the quads returned by this instance. Default value
/// is <tt>@instanceKeypath(LTSplineControlPoint, xCoordinateOfLocation)</tt>.
@property (readonly, nonatomic) NSString *xCoordinateKey;

/// Key any \c LTParameterizationKeyToValues object given to this object must contain in order to
/// retrieve the y-coordinates of the centers of the quads returned by this instance. Default value
/// is <tt>@instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation)</tt>.
@property (readonly, nonatomic) NSString *yCoordinateKey;

/// Size of any quad provided by this object.
@property (readonly, nonatomic) CGSize size;

@end

NS_ASSUME_NONNULL_END

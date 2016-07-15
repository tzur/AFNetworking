// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNGeometryProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Model of a \c DVNGeometryProvider object providing square quads. Calling
/// \c valuesFromSamples:samples on the geometry provider, yields
/// <tt>dvn::GeometryValues(quads, indices, samples)</tt>, where \c quads is a vector of the size of
/// \c samples.sampledParametricValues, and \c indices is the vector <tt>{0, 1, 2, 3, ...}</tt> of
/// the same length. All returned quads are square and have the same edge length. The center of each
/// quad has the coordinates retrieved from the given \c samples at keys \c xCoordinateKey and
/// \c yCoordinateKey.
///
/// @important: Any \c id<LTSampleValues> object used as parameter of the \c valuesFromSamples:
/// method must have the keys \c xCoordinateKey and \c yCoordinateKey.
@interface DVNSquareProviderModel : NSObject <DVNGeometryProviderModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c edgeLength and default values for \c xCoordinateKey and
/// \c yCoordinateKey. The length of any edge of the square quads provided by this object equals the
/// given \c edgeLength. The given \c edgeLength must be greater than \c 0.
- (instancetype)initWithEdgeLength:(CGFloat)edgeLength;

/// Initializes with the given \c edgeLength, \c xCoordinateKey and \c yCoordinateKey. The length of
/// any edge of the square quads provided by this object equals the given \c edgeLength. The given
/// \c edgeLength must be greater than \c 0. The \c length of the given \c xCoordinateKey and
/// \c yCoordinateKey must be positive and the strings must be distinct from each other.
- (instancetype)initWithEdgeLength:(CGFloat)edgeLength xCoordinateKey:(NSString *)xCoordinateKey
                    yCoordinateKey:(NSString *)yCoordinateKey NS_DESIGNATED_INITIALIZER;

/// Key any \c LTParameterizationKeyToValues object given to this object must contain in order to
/// retrieve the x-coordinates of the centers of the quads returned by this instance. Default value
/// is <tt>@instanceKeypath(LTSplineControlPoint, xCoordinateOfLocation)</tt>.
@property (readonly, nonatomic) NSString *xCoordinateKey;

/// Key any \c LTParameterizationKeyToValues object given to this object must contain in order to
/// retrieve the y-coordinates of the centers of the quads returned by this instance. Default value
/// is <tt>@instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation)</tt>.
@property (readonly, nonatomic) NSString *yCoordinateKey;

/// Edge length of any square quad provided by this object.
@property (readonly, nonatomic) CGFloat edgeLength;

@end

NS_ASSUME_NONNULL_END

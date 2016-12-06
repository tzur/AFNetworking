// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNGeometryProvider.h"

#import <LTEngine/LTInterval.h>

NS_ASSUME_NONNULL_BEGIN

@class DVNSquareProviderModel, LTRandomState;

/// Model of an \c id<DVNGeometryProvider> that provides \c dvn::GeometryValues with randomly
/// transformed quads.
///
/// The returned \c dvn::GeometryValues are constructed by manipulating the \c dvn::GeometryValues
/// returned by an internal \c id<DVNGeometryProvider> which is constructed from a
/// \c id<DVNGeometryProviderModel> model given upon initialization.
///
/// The manipulation is performed as follows: First, each quad returned by the
/// \c valuesFromSamples:end: method of the internal \c id<DVNGeometryProvider> is duplicated \c x
/// times, where \x is randomly chosen from <tt>{1, 2, ..., maximumCount}<\tt> for every quad.
/// Afterwards, a random affine transformation is applied to each of the quads, that is constructed
/// from translation, roatation and scaling. Every quad is assigned with the index of the quad it
/// was duplicated from. The \c samples of the \c dvn::GeometryValues returned by the aforementioned
/// internal \c id<DVNGeometryProvider> are left unchanged.
@interface DVNScatteredGeometryProviderModel : NSObject <DVNGeometryProviderModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c geometryProviderModel, \c randomState, \c maximumCount,
/// \c distance, \c angle and \c scale.
///
/// @param geometryProviderModel Underlying model of this instance.
/// @param randomState State to use as initial state of \c LTRandom objects internally used by the
/// \c id<DVNGeometryProvider> that can be constructed from this model.
/// @param maximumCount Maximum number of quads duplicated from a given quad.
/// @param distance Interval from which the length of random translations of quads are retrieved.
/// Must be in range <tt>[0, CGFLOAT_MAX]</tt>.
/// @param angle Interval from which the angle of random rotations of quads are retrieved. Must be
/// in range <tt>[0, 2 * M_PI)</tt>.
/// @param scale Interval from which the scale factor of random scalings of quads are retrieved.
/// Must be in range <tt>(0, CGFLOAT_MAX]</tt>.
- (instancetype)initWithGeometryProviderModel:(id<DVNGeometryProviderModel>)geometryProviderModel
                                  randomState:(LTRandomState *)randomState
                                 maximumCount:(NSUInteger)maximumCount
                                     distance:(lt::Interval<CGFloat>)distance
                                        angle:(lt::Interval<CGFloat>)angle
                                        scale:(lt::Interval<CGFloat>)scale
    NS_DESIGNATED_INITIALIZER;

/// Underlying geometry model of this instance.
@property (readonly, nonatomic) id<DVNGeometryProviderModel> geometryProviderModel;

/// Maximum number of quads duplicated from a given quad.
@property (readonly, nonatomic) NSUInteger maximumCount;

/// Interval from which the length of random translations of quads are retrieved. Is in range
/// <tt>[0, CGFLOAT_MAX]</tt>.
@property (readonly, nonatomic) lt::Interval<CGFloat> distance;

/// Interval from which the angle of random rotations of quads are retrieved. Is in range
/// <tt>[0, 2 * M_PI)</tt>.
@property (readonly, nonatomic) lt::Interval<CGFloat> angle;

/// Interval from which the scale factor of random scalings of quads are retrieved. Is in range
/// <tt>[0, CGFLOAT_MAX]</tt>.
@property (readonly, nonatomic) lt::Interval<CGFloat> scale;

/// State to use as initial state of \c LTRandom objects internally used by the
/// \c id<DVNGeometryProvider> that can be constructed from this model.
@property (readonly, nonatomic) LTRandomState *randomState;

@end

NS_ASSUME_NONNULL_END

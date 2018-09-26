// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import <LTEngine/LTInterval.h>

#import "DVNGeometryProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class DVNSquareProviderModel, LTRandomState;

/// Model of an \c id<DVNGeometryProvider> that provides \c dvn::GeometryValues with randomly
/// transformed and potentially tapered quads.
///
/// The returned \c dvn::GeometryValues are constructed by manipulating the \c dvn::GeometryValues
/// returned by an internal \c id<DVNGeometryProvider> which is constructed from a
/// \c id<DVNGeometryProviderModel> model given upon initialization.
///
/// The manipulation is performed as follows: First, each quad returned by the
/// \c valuesFromSamples:end: method of the internal \c id<DVNGeometryProvider> is duplicated \c x
/// times, where \x is randomly chosen from <tt>{minimumCount, ..., maximumCount}<\tt> for every
/// quad. Afterwards, a random affine transformation is applied to each of the quads, that is
/// constructed from translation, rotation and scaling. If the tapering parameters are set to
/// non-default values, the aforementioned translation and scaling of the quads also involves a
/// scaling yielding the desired tapering effect. Every quad is assigned with the index of the quad
/// it was duplicated from. The \c samples of the \c dvn::GeometryValues returned by the
/// aforementioned internal \c id<DVNGeometryProvider> are left unchanged.
///
/// @important The \c mappingOfSampledValues of the \c id<LTSampleValues> objects used as argument
/// of the \c valuesFromSamples:end: method must have values for the key
/// <tt>[LTSplineControlPoint keyForSpeedInScreenCoordinates]</tt>.
@interface DVNScatteredGeometryProviderModel : NSObject <DVNGeometryProviderModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c geometryProviderModel, \c randomState, \c maximumCount,
/// \c distance, \c angle and \c scale.
///
/// @param geometryProviderModel Underlying model of this instance.
/// @param randomState State to use as initial state of \c LTRandom objects internally used by the
/// \c id<DVNGeometryProvider> that can be constructed from this model.
/// @param count Interval from which the count of quads duplicated from a given quad are retrieved.
/// @param distance Interval from which the length of random translations of quads are retrieved.
/// Must be non-negative.
/// @param angle Interval from which the angle of random rotations of quads are retrieved. Must be
/// in range <tt>[0, 4 * M_PI)</tt>.
/// @param scale Interval from which the scale factor of random scalings of quads are retrieved.
/// Must be positive.
- (instancetype)initWithGeometryProviderModel:(id<DVNGeometryProviderModel>)geometryProviderModel
                                  randomState:(LTRandomState *)randomState
                                        count:(lt::Interval<NSUInteger>)count
                                     distance:(lt::Interval<CGFloat>)distance
                                        angle:(lt::Interval<CGFloat>)angle
                                        scale:(lt::Interval<CGFloat>)scale;

/// Initializes with the given parameters explained as follows:
///
/// @param geometryProviderModel Underlying model of this instance.
/// @param randomState State to use as initial state of \c LTRandom objects internally used by the
/// \c id<DVNGeometryProvider> that can be constructed from this model.
/// @param count Interval from which the count of quads duplicated from a given quad are retrieved.
/// @param distance Interval from which the length of random translations of quads are retrieved.
/// Must be non-negative.
/// @param angle Interval from which the angle of random rotations of quads are retrieved. Must be
/// in range <tt>[0, 4 * M_PI)</tt>.
/// @param scale Interval from which the scale factor of random scalings of quads are retrieved.
/// Must be positive.
/// @param lengthOfStartTapering Maximum length, in units of the sampled parametric object, at the
/// beginning of the sample sequence for which tapering of the returned quads is performed. Must be
/// non-negative.
/// @param lengthOfEndTapering Maximum length, in units of the sampled parametric object, at the end
/// of the sample sequence for which tapering of the returned quads is performed. Must be
/// non-negative.
/// @param startTaperingFactor Factor used in a Bernstein polynomial for computing the size of the
/// returned quads undergoing tapering at the beginning of the sample sequence. Must be in range
/// <tt>[0, 1]</tt>.
/// @param endTaperingFactor Factor used in a Bernstein polynomial for computing the size of the
/// returned quads undergoing tapering at the end of the sample sequence. Must be in range
/// <tt>[0, 1]</tt>.
/// @param minimumTaperingScaleFactor Minimum scale factor used for tapering. Must be in range
/// <tt>(0, 1]</tt>.
/// @param speedBasedTaperingFactor Factor determining the intensity and the behavior of the
/// speed-based tapering. Must be in range <tt>[-1, 1]</tt>. A value of \c 0 results in no tapering
/// due to speed. A value of \c 1 yields smaller quads with higher speed, while a value of \c -1
/// results in smaller quads with lower speed.
/// @param conversionFactor Factor for scaling units of the sampled parametric object. Can be used
/// to ensure similar speed-based behaviors across different render target resolutions.
- (instancetype)initWithGeometryProviderModel:(id<DVNGeometryProviderModel>)geometryProviderModel
                                  randomState:(LTRandomState *)randomState
                                        count:(lt::Interval<NSUInteger>)count
                                     distance:(lt::Interval<CGFloat>)distance
                                        angle:(lt::Interval<CGFloat>)angle
                                        scale:(lt::Interval<CGFloat>)scale
                        lengthOfStartTapering:(CGFloat)lengthOfStartTapering
                          lengthOfEndTapering:(CGFloat)lengthOfEndTapering
                          startTaperingFactor:(CGFloat)startTaperingFactor
                            endTaperingFactor:(CGFloat)endTaperingFactor
                   minimumTaperingScaleFactor:(CGFloat)minimumTaperingScaleFactor
                     speedBasedTaperingFactor:(CGFloat)speedBasedTaperingFactor
                             conversionFactor:(CGFloat)conversionFactor
    NS_DESIGNATED_INITIALIZER;

/// Underlying geometry model of this instance.
@property (readonly, nonatomic) id<DVNGeometryProviderModel> geometryProviderModel;

/// State to use as initial state of \c LTRandom objects internally used by the
/// \c id<DVNGeometryProvider> that can be constructed from this model.
@property (readonly, nonatomic) LTRandomState *randomState;

#pragma mark -
#pragma mark Jittering
#pragma mark -

/// Interval from which the count of quads duplicated from a given quad are retrieved.
@property (readonly, nonatomic) lt::Interval<NSUInteger> count;

/// Interval from which the length of random translations of quads are retrieved. Is non-negative.
@property (readonly, nonatomic) lt::Interval<CGFloat> distance;

/// Interval from which the angle of random rotations of quads are retrieved. Is in range
/// <tt>[0, 4 * M_PI]</tt>.
@property (readonly, nonatomic) lt::Interval<CGFloat> angle;

/// Interval from which the scale factor of random scalings of quads are retrieved. Is in range
/// <tt>(0, CGFLOAT_MAX]</tt>.
@property (readonly, nonatomic) lt::Interval<CGFloat> scale;

#pragma mark -
#pragma mark Tapering
#pragma mark -

/// Maximum length, in units of the sampled parametric object, at the beginning of the sample
/// sequence for which tapering of the returned quads is performed. Is non-negative.
@property (readonly, nonatomic) CGFloat lengthOfStartTapering;

/// Maximum length, in units of the sampled parametric object, at the end of the sample sequence for
/// which tapering of the returned quads is performed. Is non-negative.
@property (readonly, nonatomic) CGFloat lengthOfEndTapering;

/// Factor used in a Bernstein polynomial for computing the size of the returned quads undergoing
/// tapering at the beginning of the sample sequence. Is in range <tt>[0, 1]</tt>.
@property (readonly, nonatomic) CGFloat startTaperingFactor;

/// Factor used in a Bernstein polynomial for computing the size of the returned quads undergoing
/// tapering at the end of the sample sequence. Is in range <tt>[0, 1]</tt>.
@property (readonly, nonatomic) CGFloat endTaperingFactor;

/// Minimum scale factor used for tapering. Is in range <tt>(0, 1]</tt>.
@property (readonly, nonatomic) CGFloat minimumTaperingScaleFactor;

/// Factor determining the intensity and the behavior of the speed-based tapering.
@property (readonly, nonatomic) CGFloat speedBasedTaperingFactor;

/// Factor for scaling units of the sampled parametric object.
@property (readonly, nonatomic) CGFloat conversionFactor;

@end

NS_ASSUME_NONNULL_END
